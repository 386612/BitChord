import Foundation

struct SearchTrack: Identifiable, Hashable {
    let id: String
    let title: String
    let artist: String
    let thumbnailURL: URL?
}

struct YouTubeMusicSearch {
    private let endpoint = URL(string: "https://music.youtube.com/youtubei/v1/search?prettyPrint=false")!

    func search(_ query: String) async throws -> [SearchTrack] {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("music.youtube.com", forHTTPHeaderField: "Origin")
        let body: [String: Any] = [
            "context": ["client": [
                "clientName": "WEB_REMIX",
                "clientVersion": "1.20261001.01.00",
                "hl": "ja",
                "gl": "JP"
            ]],
            "query": query
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
            throw URLError(.badServerResponse)
        }
        guard let root = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw URLError(.cannotParseResponse)
        }
        return collectTracks(in: root)
    }

    private func collectTracks(in value: Any) -> [SearchTrack] {
        var output: [SearchTrack] = []
        walk(value) { object in
            guard let renderer = object["videoRenderer"] as? [String: Any],
                  let id = renderer["videoId"] as? String,
                  let title = text(renderer["title"]) else { return }
            let artist = text(renderer["ownerText"]) ?? text(renderer["longBylineText"]) ?? "YouTube Music"
            let thumb = ((renderer["thumbnail"] as? [String: Any])?["thumbnails"] as? [[String: Any]])?.last?["url"] as? String
            output.append(SearchTrack(id: id, title: title, artist: artist, thumbnailURL: URL(string: thumb ?? "")))
        }
        var seen = Set<String>()
        return output.filter { seen.insert($0.id).inserted }
    }

    private func walk(_ value: Any, visit: ([String: Any]) -> Void) {
        if let object = value as? [String: Any] {
            visit(object)
            object.values.forEach { walk($0, visit: visit) }
        } else if let array = value as? [Any] {
            array.forEach { walk($0, visit: visit) }
        }
    }

    private func text(_ value: Any?) -> String? {
        guard let object = value as? [String: Any] else { return nil }
        if let simple = object["simpleText"] as? String { return simple }
        if let runs = object["runs"] as? [[String: Any]] {
            return runs.compactMap { $0["text"] as? String }.joined()
        }
        return nil
    }
}
