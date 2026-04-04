import AVFoundation

// 효과음 랜덤 재생 서비스
class SoundService {
    static let shared = SoundService()
    private var player: AVAudioPlayer?

    // 앱 실행 시 시작 사운드
    private let startupSounds = [
        "freesound_community-canto-robot-1-81459",
        "kuzu420-robot-broken-loading-206293",
    ]

    // 효과음 파일 목록
    private let soundFiles = [
        "freesound_community-3beeps-108353",
        "mightuser-sound-of-error-beep-hd-267280",
        "universfield-error-011-352286",
        "universfield-new-notification-027-383749",
        "universfield-new-notification-028-383966",
    ]

    // 앱 시작 사운드 랜덤 재생
    func playStartup() {
        guard let name = startupSounds.randomElement(),
              let url = Bundle.main.url(forResource: name, withExtension: "mp3") else {
            return
        }

        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.volume = 0.5
            player?.play()
        } catch {
            // 재생 실패 시 무시
        }
    }

    // 랜덤 효과음 재생
    func playRandom() {
        guard let name = soundFiles.randomElement(),
              let url = Bundle.main.url(forResource: name, withExtension: "mp3") else {
            return
        }

        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.volume = 0.5
            player?.play()
        } catch {
            // 재생 실패 시 무시
        }
    }
}
