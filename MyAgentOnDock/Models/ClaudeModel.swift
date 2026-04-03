import Foundation

// 선택 가능한 Claude 모델
enum ClaudeModel: String, CaseIterable, Codable, Identifiable {
    case haiku = "claude-haiku-4-5-20251001"
    case sonnet = "claude-sonnet-4-6-20250514"
    case opus = "claude-opus-4-6-20250514"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .haiku: return "Haiku 4.5 (빠름, 저렴)"
        case .sonnet: return "Sonnet 4.6 (균형)"
        case .opus: return "Opus 4.6 (최고 성능)"
        }
    }

    var shortName: String {
        switch self {
        case .haiku: return "Haiku"
        case .sonnet: return "Sonnet"
        case .opus: return "Opus"
        }
    }
}
