import SwiftUI

struct ContentView: View {
    @StateObject private var player = AudioPlayer.shared
    @State private var query = ""
    @State private var mediaURL = ""
    @State private var mediaTitle = ""
    @State private var showingURLPlayer = false
    @State private var results: [SearchTrack] = []
    @State private var searching = false
    @State private var searchError: String?

    var body: some View {
        TabView {
            NavigationStack {
                List {
                    Section("検索") {
                        TextField("曲名・アーティスト", text: $query)
                            .textInputAutocapitalization(.never)
                        Button {
                            searching = true
                            searchError = nil
                            Task {
                                do {
                                    results = try await YouTubeMusicSearch().search(query)
                                } catch {
                                    searchError = error.localizedDescription
                                }
                                searching = false
                            }
                        } label: {
                            if searching { ProgressView() } else { Text("検索") }
                        }
                            .disabled(query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    if let searchError {
                        Section { Text(searchError).foregroundStyle(.red) }
                    }
                    Section("検索結果") {
                        ForEach(results) { track in
                            Button {
                                mediaTitle = track.title
                                showingURLPlayer = true
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(track.title).font(.headline).foregroundStyle(.primary)
                                    Text(track.artist).font(.subheadline).foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    Section("再生") {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(player.title).font(.headline)
                                Text(player.artist).font(.subheadline).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button { player.toggle() } label: {
                                Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        Button("音声URLを再生") { showingURLPlayer = true }
                    }
                }
                .navigationTitle("BitChord")
            }
            .tabItem { Label("検索", systemImage: "magnifyingglass") }

            NavigationStack {
                VStack(spacing: 16) {
                    Image(systemName: "music.note.list").font(.system(size: 58)).foregroundStyle(.tint)
                    Text("ライブラリ").font(.title2.bold())
                    Text("iOSのオフライン保存とライブラリ連携を実装中です")
                        .foregroundStyle(.secondary).multilineTextAlignment(.center)
                }
                .padding().navigationTitle("ライブラリ")
            }
            .tabItem { Label("ライブラリ", systemImage: "books.vertical") }
        }
        .sheet(isPresented: $showingURLPlayer) {
            NavigationStack {
                Form {
                    TextField("https://…", text: $mediaURL).textInputAutocapitalization(.never).keyboardType(.URL)
                    TextField("タイトル", text: $mediaTitle)
                    Button("再生") {
                        guard let url = URL(string: mediaURL), url.scheme == "https" || url.scheme == "http" else { return }
                        player.play(url: url, title: mediaTitle.isEmpty ? "音声" : mediaTitle)
                        showingURLPlayer = false
                    }
                }
                .navigationTitle("音声URL")
                .toolbar { Button("閉じる") { showingURLPlayer = false } }
            }
            .presentationDetents([.medium])
        }
        .alert("再生エラー", isPresented: Binding(
            get: { player.errorMessage != nil },
            set: { if !$0 { player.errorMessage = nil } }
        )) {
            Button("閉じる", role: .cancel) { player.errorMessage = nil }
        } message: {
            Text(player.errorMessage ?? "不明なエラー")
        }
    }
}

#Preview {
    ContentView()
}
