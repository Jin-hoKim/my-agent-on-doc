import Foundation
import AVFoundation

// TTS(Text-to-Speech) 서비스 - AVSpeechSynthesizer 래핑
class TTSService: NSObject, AVSpeechSynthesizerDelegate, @unchecked Sendable {
    static let shared = TTSService()

    private let synthesizer = AVSpeechSynthesizer()
    private(set) var isSpeaking = false

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    // 텍스트 읽기
    func speak(_ text: String, voiceType: VoiceType) {
        guard voiceType != .none else { return }
        stop()

        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = 0.5
        utterance.pitchMultiplier = voiceType.pitchMultiplier
        utterance.volume = 0.9

        if let voice = voice(for: voiceType) {
            utterance.voice = voice
        }

        isSpeaking = true
        synthesizer.speak(utterance)
    }

    // 중지
    func stop() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        isSpeaking = false
    }

    // 음성 선택
    private func voice(for voiceType: VoiceType) -> AVSpeechSynthesisVoice? {
        switch voiceType {
        case .none:
            return nil
        case .male:
            // 한국어 남성 음성 우선, 없으면 기본 한국어
            return AVSpeechSynthesisVoice(language: "ko-KR")
        case .female:
            return AVSpeechSynthesisVoice(language: "ko-KR")
        case .robot:
            // 영어 로봇 음성 (느린 속도, 낮은 피치로 설정)
            return AVSpeechSynthesisVoice(language: "ko-KR")
        }
    }

    // AVSpeechSynthesizerDelegate
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        isSpeaking = false
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        isSpeaking = false
    }
}
