import SwiftUI

// 사용자가 선택 가능한 에이전트 캐릭터 타입
enum CharacterType: String, CaseIterable, Codable, Identifiable {
    case developer = "developer"
    case robot = "robot"
    case cat = "cat"
    case penguin = "penguin"
    case astronaut = "astronaut"
    case ninja = "ninja"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .developer: return "개발자"
        case .robot: return "로봇"
        case .cat: return "고양이"
        case .penguin: return "펭귄"
        case .astronaut: return "우주인"
        case .ninja: return "닌자"
        }
    }

    var workingEmoji: String {
        switch self {
        case .developer: return "👨‍💻"
        case .robot: return "🤖"
        case .cat: return "🐱"
        case .penguin: return "🐧"
        case .astronaut: return "🧑‍🚀"
        case .ninja: return "🥷"
        }
    }

    var idleEmoji: String {
        switch self {
        case .developer: return "😎"
        case .robot: return "🤖"
        case .cat: return "😺"
        case .penguin: return "🐧"
        case .astronaut: return "🧑‍🚀"
        case .ninja: return "🥷"
        }
    }

    var thinkingEmoji: String {
        switch self {
        case .developer: return "🤔"
        case .robot: return "⚙️"
        case .cat: return "🐱"
        case .penguin: return "🐧"
        case .astronaut: return "🔭"
        case .ninja: return "🥷"
        }
    }

    // 캐릭터별 테마 색상
    var themeColor: Color {
        switch self {
        case .developer: return .blue
        case .robot: return .cyan
        case .cat: return .orange
        case .penguin: return .indigo
        case .astronaut: return .purple
        case .ninja: return .red
        }
    }
}
