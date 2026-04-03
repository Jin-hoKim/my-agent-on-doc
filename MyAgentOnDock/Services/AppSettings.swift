import SwiftUI
import Combine

// 앱 설정 관리 (UserDefaults 기반)
@MainActor
class AppSettings: ObservableObject {
    static let shared = AppSettings()

    // API 키
    @AppStorage("apiKey") var apiKey: String = ""

    // 캐릭터 설정
    @AppStorage("characterType") var characterTypeRaw: String = CharacterType.developer.rawValue
    @AppStorage("characterSize") var characterSize: Double = 64.0

    // 음성 설정
    @AppStorage("voiceType") var voiceTypeRaw: String = VoiceType.none.rawValue

    // 모델 설정
    @AppStorage("claudeModel") var claudeModelRaw: String = ClaudeModel.sonnet.rawValue

    // 패널 표시 여부
    @AppStorage("characterPanelVisible") var isPanelVisible: Bool = true

    var characterType: CharacterType {
        get { CharacterType(rawValue: characterTypeRaw) ?? .developer }
        set { characterTypeRaw = newValue.rawValue }
    }

    var voiceType: VoiceType {
        get { VoiceType(rawValue: voiceTypeRaw) ?? .none }
        set { voiceTypeRaw = newValue.rawValue }
    }

    var claudeModel: ClaudeModel {
        get { ClaudeModel(rawValue: claudeModelRaw) ?? .sonnet }
        set { claudeModelRaw = newValue.rawValue }
    }

    var isAPIKeySet: Bool {
        !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // 캐릭터 사이즈 범위
    static let minSize: Double = 40.0
    static let maxSize: Double = 120.0
}
