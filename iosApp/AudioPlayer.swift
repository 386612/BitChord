import AVFoundation
import MediaPlayer
import Combine

@MainActor
final class AudioPlayer: ObservableObject {
    static let shared = AudioPlayer()

    @Published private(set) var isPlaying = false
    @Published private(set) var title = "未再生"
    @Published private(set) var artist = "BitChord"
    @Published private(set) var duration: TimeInterval = 0
    @Published private(set) var position: TimeInterval = 0
    @Published var errorMessage: String?

    private let player = AVPlayer()
    private var timeObserver: Any?

    private init() {
        configureAudioSession()
        configureRemoteCommands()
        timeObserver = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.25, preferredTimescale: 600),
            queue: .main
        ) { [weak self] time in
            guard let self else { return }
            position = time.seconds.isFinite ? max(0, time.seconds) : 0
            updateNowPlaying()
        }
        NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance(),
            queue: .main
        ) { [weak self] note in
            guard let self,
                  let info = note.userInfo,
                  let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
                  let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }
            if type == .began { isPlaying = false }
            if type == .ended,
               let optionsValue = info[AVAudioSessionInterruptionOptionKey] as? UInt,
               AVAudioSession.InterruptionOptions(rawValue: optionsValue).contains(.shouldResume) {
                player.play(); isPlaying = true
            }
        }
    }

    func play(url: URL, title: String, artist: String = "BitChord") {
        do {
            try AVAudioSession.sharedInstance().setActive(true)
            self.title = title
            self.artist = artist
            let item = AVPlayerItem(url: url)
            player.replaceCurrentItem(with: item)
            player.play()
            isPlaying = true
            errorMessage = nil
            updateNowPlaying()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func toggle() {
        if isPlaying { player.pause() } else { player.play() }
        isPlaying.toggle()
        updateNowPlaying()
    }

    func seek(to seconds: TimeInterval) {
        player.seek(to: CMTime(seconds: max(0, seconds), preferredTimescale: 600))
    }

    private func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .spokenAudio, options: [])
            try session.setActive(true)
        } catch { errorMessage = error.localizedDescription }
    }

    private func configureRemoteCommands() {
        let center = MPRemoteCommandCenter.shared()
        center.playCommand.addTarget { [weak self] _ in self?.player.play(); self?.isPlaying = true; return .success }
        center.pauseCommand.addTarget { [weak self] _ in self?.player.pause(); self?.isPlaying = false; return .success }
        center.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let event = event as? MPChangePlaybackPositionCommandEvent else { return .commandFailed }
            self?.seek(to: event.positionTime); return .success
        }
    }

    private func updateNowPlaying() {
        var info: [String: Any] = [MPMediaItemPropertyTitle: title, MPMediaItemPropertyArtist: artist]
        if duration > 0 { info[MPMediaItemPropertyPlaybackDuration] = duration }
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = position
        info[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }
}
