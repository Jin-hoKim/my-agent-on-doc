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

    // 상태에 따른 이모지 반환 (20가지 표정)
    func emoji(for state: AgentState) -> String {
        switch self {
        case .developer: return developerEmoji(for: state)
        case .robot:     return robotEmoji(for: state)
        case .cat:       return catEmoji(for: state)
        case .penguin:   return penguinEmoji(for: state)
        case .astronaut: return astronautEmoji(for: state)
        case .ninja:     return ninjaEmoji(for: state)
        }
    }

    // 기존 호환성 유지
    var idleEmoji: String { emoji(for: .idle) }
    var workingEmoji: String { emoji(for: .streaming) }
    var thinkingEmoji: String { emoji(for: .thinking) }

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

    // MARK: - 개발자 이모지
    private func developerEmoji(for state: AgentState) -> String {
        switch state {
        case .idle:         return "😊"  // normal face
        case .thinking:     return "🤔"  // thinking/loading face
        case .loading:      return "⏳"  // loading face
        case .streaming:    return "👨‍💻"  // typing face
        case .responding:   return "😌"  // pleased face
        case .error:        return "😱"  // error face
        case .voiceMode:    return "🎤"  // voice mode
        case .excited:      return "🤩"  // excited face
        case .angry:        return "😠"  // angry face
        case .winking:      return "😉"  // winking face
        case .surprised:    return "😲"  // surprised face
        case .pleased:      return "😊"  // pleased face
        case .sad:          return "😢"  // sad face
        case .laughing:     return "😂"  // laughing face
        case .snoozing:     return "😴"  // snoozing face
        case .neutral:      return "😐"  // neutral face
        case .outOfService: return "🚫"  // out of service
        case .lowBattery:   return "🪫"  // low battery
        case .crazy:        return "🤪"  // crazy face
        case .heartEyes:    return "😍"  // heart face
        case .newMessage:   return "💬"  // new message face
        case .unknown:      return "🤷"  // unknown face
        }
    }

    // MARK: - 로봇 이모지
    private func robotEmoji(for state: AgentState) -> String {
        switch state {
        case .idle:         return "🤖"  // normal face
        case .thinking:     return "⚙️"  // thinking/loading
        case .loading:      return "🔄"  // loading
        case .streaming:    return "🖥️"  // typing face
        case .responding:   return "✅"  // responding
        case .error:        return "⚠️"  // error face
        case .voiceMode:    return "🔊"  // voice mode
        case .excited:      return "🤩"  // excited face
        case .angry:        return "😡"  // angry face
        case .winking:      return "😉"  // winking face
        case .surprised:    return "😯"  // surprised face
        case .pleased:      return "😄"  // pleased face
        case .sad:          return "😢"  // sad face
        case .laughing:     return "🤣"  // laughing face
        case .snoozing:     return "💤"  // snoozing
        case .neutral:      return "🤖"  // neutral
        case .outOfService: return "🔴"  // out of service
        case .lowBattery:   return "🔋"  // low battery
        case .crazy:        return "🌀"  // crazy face
        case .heartEyes:    return "💝"  // heart face
        case .newMessage:   return "📨"  // new message
        case .unknown:      return "❓"  // unknown face
        }
    }

    // MARK: - 고양이 이모지
    private func catEmoji(for state: AgentState) -> String {
        switch state {
        case .idle:         return "😺"  // normal face
        case .thinking:     return "🐱"  // thinking/loading
        case .loading:      return "🐱"  // loading
        case .streaming:    return "😸"  // typing face
        case .responding:   return "😸"  // responding
        case .error:        return "🙀"  // error face
        case .voiceMode:    return "😼"  // voice mode
        case .excited:      return "😻"  // excited face
        case .angry:        return "😾"  // angry face
        case .winking:      return "😼"  // winking face
        case .surprised:    return "🙀"  // surprised face
        case .pleased:      return "😸"  // pleased face
        case .sad:          return "😿"  // sad face
        case .laughing:     return "😹"  // laughing face
        case .snoozing:     return "😴"  // snoozing
        case .neutral:      return "😐"  // neutral
        case .outOfService: return "🙀"  // out of service
        case .lowBattery:   return "😿"  // low battery
        case .crazy:        return "🐱"  // crazy face
        case .heartEyes:    return "😻"  // heart face
        case .newMessage:   return "😺"  // new message
        case .unknown:      return "🐱"  // unknown face
        }
    }

    // MARK: - 펭귄 이모지
    private func penguinEmoji(for state: AgentState) -> String {
        switch state {
        case .idle:         return "🐧"  // normal face
        case .thinking:     return "🐧"  // thinking/loading
        case .loading:      return "🐧"  // loading
        case .streaming:    return "🐧"  // typing face
        case .responding:   return "🐧"  // responding
        case .error:        return "❄️"  // error face
        case .voiceMode:    return "🎵"  // voice mode
        case .excited:      return "🤩"  // excited face
        case .angry:        return "😠"  // angry face
        case .winking:      return "😉"  // winking face
        case .surprised:    return "😲"  // surprised face
        case .pleased:      return "😊"  // pleased face
        case .sad:          return "😢"  // sad face
        case .laughing:     return "😂"  // laughing face
        case .snoozing:     return "😴"  // snoozing
        case .neutral:      return "😐"  // neutral
        case .outOfService: return "❄️"  // out of service
        case .lowBattery:   return "🪫"  // low battery
        case .crazy:        return "🤪"  // crazy face
        case .heartEyes:    return "😍"  // heart face
        case .newMessage:   return "💬"  // new message
        case .unknown:      return "🐧"  // unknown face
        }
    }

    // MARK: - 우주인 이모지
    private func astronautEmoji(for state: AgentState) -> String {
        switch state {
        case .idle:         return "🧑‍🚀"  // normal face
        case .thinking:     return "🔭"  // thinking/loading
        case .loading:      return "🛸"  // loading
        case .streaming:    return "🛰️"  // typing face
        case .responding:   return "✨"  // responding
        case .error:        return "💥"  // error face
        case .voiceMode:    return "📡"  // voice mode
        case .excited:      return "🚀"  // excited face
        case .angry:        return "😠"  // angry face
        case .winking:      return "😉"  // winking face
        case .surprised:    return "😲"  // surprised face
        case .pleased:      return "🌟"  // pleased face
        case .sad:          return "😢"  // sad face
        case .laughing:     return "😂"  // laughing face
        case .snoozing:     return "😴"  // snoozing
        case .neutral:      return "😐"  // neutral
        case .outOfService: return "🚫"  // out of service
        case .lowBattery:   return "🪫"  // low battery
        case .crazy:        return "🌌"  // crazy face
        case .heartEyes:    return "🥰"  // heart face
        case .newMessage:   return "📻"  // new message
        case .unknown:      return "🌑"  // unknown face
        }
    }

    // MARK: - 닌자 이모지
    private func ninjaEmoji(for state: AgentState) -> String {
        switch state {
        case .idle:         return "🥷"  // normal face
        case .thinking:     return "🧠"  // thinking/loading
        case .loading:      return "⏳"  // loading
        case .streaming:    return "⚡"  // typing face
        case .responding:   return "🎯"  // responding
        case .error:        return "💢"  // error face
        case .voiceMode:    return "🎭"  // voice mode
        case .excited:      return "⚡"  // excited face
        case .angry:        return "😤"  // angry face
        case .winking:      return "😉"  // winking face
        case .surprised:    return "😲"  // surprised face
        case .pleased:      return "🎯"  // pleased face
        case .sad:          return "😢"  // sad face
        case .laughing:     return "😂"  // laughing face
        case .snoozing:     return "😴"  // snoozing
        case .neutral:      return "😐"  // neutral
        case .outOfService: return "🚫"  // out of service
        case .lowBattery:   return "🪫"  // low battery
        case .crazy:        return "🌀"  // crazy face
        case .heartEyes:    return "🥰"  // heart face
        case .newMessage:   return "💬"  // new message
        case .unknown:      return "🌑"  // unknown face
        }
    }
}
