import Foundation

// 음성 타입 (AVSpeechSynthesizer 연동)
enum VoiceType: String, CaseIterable, Codable, Identifiable {
    case none = "none"
    case male = "male"
    case female = "female"
    case robot = "robot"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .none: return "음성 없음"
        case .male: return "기본 음성 (KO)"
        case .female: return "여성 음성 (KO)"
        case .robot: return "로봇 음성 (느린 피치)"
        }
    }

    // AVSpeechSynthesizer 피치 배율
    var pitchMultiplier: Float {
        switch self {
        case .none: return 1.0
        case .male: return 0.85       // 낮은 피치
        case .female: return 1.2      // 높은 피치
        case .robot: return 0.6       // 매우 낮은 피치 (로봇)
        }
    }

    // 읽기 속도
    var speechRate: Float {
        switch self {
        case .none: return 0.5
        case .male: return 0.48
        case .female: return 0.50
        case .robot: return 0.38      // 느린 속도
        }
    }
}
