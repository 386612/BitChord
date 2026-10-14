import SwiftUI

struct ContentView: View {
    @StateObject private var player = AudioPlayer.shared
    @State private var query = ""
    @State private var mediaURL = ""
    @State private var mediaTitle = ""
    @State private var showingURLPlayer = false
    @State private var showingNowPlaying = false
    @State private var results: [SearchTrack] = []
    @State private var searching = false
    @State private var searchError: String?
    @State private var selectedTab = 0

    private let background = LinearGradient(
        colors: [Color(red: 0.10, green: 0.08, blue: 0.16), Color.black],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    var body: some View {
        ZStack {
            background.ignoresSafeArea()
            TabView(selection: $selectedTab) {
                homeScreen.tag(0).tabItem { Label("ホーム", systemImage: "house.fill") }
                searchScreen.tag(1).tabItem { Label("検索", systemImage: "magnifyingglass") }
                libraryScreen.tag(2).tabItem { Label("ライブラリ", systemImage: "books.vertical.fill") }
                settingsScreen.tag(3).tabItem { Label("設定", systemImage: "gearshape.fill") }
            }
            .tint(.white)
            .toolbarBackground(.ultraThinMaterial, for: .tabBar)
            .toolbarBackground(.visible, for: .tabBar)
        }
        .sheet(isPresented: $showingNowPlaying) { nowPlayingScreen }
        .sheet(isPresented: $showingURLPlayer) { urlPlayerSheet }
        .alert("再生エラー", isPresented: Binding(
            get: { player.errorMessage != nil },
            set: { if !$0 { player.errorMessage = nil } }
        )) {
            Button("閉じる", role: .cancel) { player.errorMessage = nil }
        } message: { Text(player.errorMessage ?? "不明なエラー") }
    }

    private var homeScreen: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    header("おかえりなさい")
                    featuredCard
                    shelf(title: "クイックピック", icon: "sparkles")
                    shelf(title: "最近再生した曲", icon: "clock.arrow.circlepath")
                    shelf(title: "あなたへのおすすめ", icon: "wand.and.stars")
                    if player.title != "未再生" { miniPlayer }
                }
                .padding(.horizontal, 18).padding(.top, 12).padding(.bottom, 90)
            }
            .navigationBarHidden(true)
        }
    }

    private var searchScreen: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    header("検索")
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                        TextField("曲名、アーティスト、アルバム", text: $query)
                            .textInputAutocapitalization(.never)
                            .foregroundStyle(.white)
                        if !query.isEmpty { Button { query = "" } label: { Image(systemName: "xmark.circle.fill") } }
                    }
                    .padding(14).background(.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 16))
                    Button {
                        runSearch()
                    } label: {
                        HStack { Spacer(); if searching { ProgressView() } else { Text("YouTube Musicを検索") }; Spacer() }
                    }
                    .buttonStyle(.borderedProminent).tint(.purple)
                    if let searchError { Text(searchError).font(.footnote).foregroundStyle(.red) }
                    if results.isEmpty && !searching {
                        emptyState(icon: "music.note", title: "曲を探す", subtitle: "検索した曲はここに表示されます")
                    }
                    ForEach(results) { track in
                        Button {
                            mediaTitle = track.title
                            showingURLPlayer = true
                        } label: { resultRow(track) }
                    }
                    if !results.isEmpty { Button("音声URLを直接入力") { showingURLPlayer = true }.foregroundStyle(.secondary) }
                }
                .padding(.horizontal, 18).padding(.top, 12).padding(.bottom, 90)
            }
            .navigationBarHidden(true)
        }
    }

    private var libraryScreen: some View {
        NavigationStack {
            VStack(spacing: 18) {
                header("ライブラリ")
                HStack(spacing: 12) {
                    libraryTile("お気に入り", "heart.fill", .pink)
                    libraryTile("ダウンロード", "arrow.down.circle.fill", .blue)
                }
                HStack(spacing: 12) {
                    libraryTile("プレイリスト", "music.note.list", .purple)
                    libraryTile("ローカル音源", "folder.fill", .orange)
                }
                Spacer()
            }
            .padding(.horizontal, 18).padding(.top, 12)
            .navigationBarHidden(true)
        }
    }

    private var settingsScreen: some View {
        NavigationStack {
            List {
                Section("再生") {
                    Label("音質", systemImage: "waveform.path.ecg")
                    Label("クロスフェード", systemImage: "arrow.left.and.right")
                    Label("バックグラウンド再生", systemImage: "headphones")
                }
                Section("連携") {
                    Label("Googleアカウント", systemImage: "person.crop.circle")
                    Label("Spotify", systemImage: "link")
                    Label("Last.fm / ListenBrainz", systemImage: "chart.bar.xaxis")
                }
                Section("BitChord") { Text("iOS移植版\nVersion 1.8 iOS") }
            }
            .scrollContentBackground(.hidden)
            .background(background)
            .navigationTitle("設定")
        }
    }

    private var featuredCard: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(colors: [.purple.opacity(0.9), .blue.opacity(0.55), .black.opacity(0.85)], startPoint: .topTrailing, endPoint: .bottomLeading)
            VStack(alignment: .leading, spacing: 6) {
                Text("BITCHORD").font(.caption.weight(.bold)).tracking(2).foregroundStyle(.white.opacity(0.7))
                Text("音楽を、もっと美しく。").font(.title.bold())
                Text("YouTube Musicクライアント").font(.subheadline).foregroundStyle(.white.opacity(0.75))
            }.padding(20)
        }
        .frame(height: 170).clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(.white.opacity(0.12)))
    }

    private func shelf(title: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: icon).font(.headline)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(0..<5, id: \.self) { index in
                        VStack(alignment: .leading, spacing: 7) {
                            RoundedRectangle(cornerRadius: 14).fill(LinearGradient(colors: [.purple.opacity(0.7), .blue.opacity(0.35)], startPoint: .topLeading, endPoint: .bottomTrailing)).frame(width: 132, height: 132).overlay(Image(systemName: "music.note").font(.title).foregroundStyle(.white.opacity(0.6)))
                            Text(index == 0 ? "おすすめの曲" : "音楽ステーション").font(.caption).lineLimit(1)
                        }.frame(width: 132)
                    }
                }
            }
        }
    }

    private var miniPlayer: some View {
        Button { showingNowPlaying = true } label: {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 8).fill(LinearGradient(colors: [.purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing)).frame(width: 48, height: 48).overlay(Image(systemName: "music.note").foregroundStyle(.white))
                VStack(alignment: .leading) { Text(player.title).font(.subheadline.weight(.semibold)).lineLimit(1); Text(player.artist).font(.caption).foregroundStyle(.secondary) }
                Spacer(); Button { player.toggle() } label: { Image(systemName: player.isPlaying ? "pause.fill" : "play.fill").font(.title3) }.buttonStyle(.plain)
            }.padding(10).background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        }.buttonStyle(.plain)
    }

    private var nowPlayingScreen: some View {
        ZStack {
            LinearGradient(colors: [.purple.opacity(0.65), .black, .black], startPoint: .top, endPoint: .bottom).ignoresSafeArea()
            VStack(spacing: 24) {
                HStack { Button("閉じる") { showingNowPlaying = false }; Spacer(); Image(systemName: "ellipsis") }.padding(.horizontal)
                Spacer()
                RoundedRectangle(cornerRadius: 28).fill(LinearGradient(colors: [.purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing)).frame(width: 300, height: 300).overlay(Image(systemName: "music.note").font(.system(size: 72)).foregroundStyle(.white.opacity(0.7)))
                VStack(alignment: .leading, spacing: 6) { Text(player.title).font(.title2.bold()); Text(player.artist).foregroundStyle(.white.opacity(0.7)) }.frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 28)
                Slider(value: Binding(get: { player.position }, set: { player.seek(to: $0) }), in: 0...max(player.duration, 1)).tint(.white).padding(.horizontal, 28)
                HStack { Spacer(); Button { player.toggle() } label: { Image(systemName: player.isPlaying ? "pause.circle.fill" : "play.circle.fill").font(.system(size: 72)) }; Spacer() }
                Spacer()
            }.foregroundStyle(.white)
        }
    }

    private var urlPlayerSheet: some View {
        NavigationStack { Form { TextField("https://音声URL", text: $mediaURL).textInputAutocapitalization(.never).keyboardType(.URL); TextField("タイトル", text: $mediaTitle); Button("再生") { guard let url = URL(string: mediaURL), url.scheme == "https" || url.scheme == "http" else { return }; player.play(url: url, title: mediaTitle.isEmpty ? "音声" : mediaTitle); showingURLPlayer = false } }.navigationTitle("音声URL").toolbar { Button("閉じる") { showingURLPlayer = false } }.presentationDetents([.medium]) }
    }

    private func header(_ title: String) -> some View { HStack { Text(title).font(.largeTitle.bold()); Spacer(); Image(systemName: "bell").font(.title3) }.foregroundStyle(.white) }
    private func runSearch() { searching = true; searchError = nil; Task { do { results = try await YouTubeMusicSearch().search(query) } catch { searchError = error.localizedDescription }; searching = false } }
    private func resultRow(_ track: SearchTrack) -> some View { HStack(spacing: 12) { AsyncImage(url: track.thumbnailURL) { image in image.resizable().scaledToFill() } placeholder: { Color.purple.opacity(0.35) }.frame(width: 58, height: 58).clipShape(RoundedRectangle(cornerRadius: 10)); VStack(alignment: .leading) { Text(track.title).font(.headline).foregroundStyle(.white).lineLimit(1); Text(track.artist).font(.subheadline).foregroundStyle(.secondary).lineLimit(1) }; Spacer(); Image(systemName: "ellipsis") }.padding(.vertical, 5) }
    private func libraryTile(_ title: String, _ icon: String, _ color: Color) -> some View { VStack(spacing: 10) { Image(systemName: icon).font(.title); Text(title).font(.subheadline.weight(.semibold)) }.frame(maxWidth: .infinity, minHeight: 120).background(color.opacity(0.22), in: RoundedRectangle(cornerRadius: 18)).overlay(RoundedRectangle(cornerRadius: 18).stroke(color.opacity(0.35))) }
    private func emptyState(icon: String, title: String, subtitle: String) -> some View { VStack(spacing: 10) { Image(systemName: icon).font(.system(size: 42)); Text(title).font(.headline); Text(subtitle).font(.subheadline).foregroundStyle(.secondary) }.frame(maxWidth: .infinity).padding(40).foregroundStyle(.white.opacity(0.75)) }
}
