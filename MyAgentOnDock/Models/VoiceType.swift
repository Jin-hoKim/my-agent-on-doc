import Foundation

// 음성 타입 (향후 TTS 연동용)
enum VoiceType: String, CaseIterable, Codable, Identifiable {
    case none = "none"
    case male = "male"
    case female = "female"
    case robot = "robot"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .none: return "음성 없음"
        case .male: return "남성 음성"
        case .female: return "여성 음성"
        case .robot: return "로봇 음성"
        }
    }
}
