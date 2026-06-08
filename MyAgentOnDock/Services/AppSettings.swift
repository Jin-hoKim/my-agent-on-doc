import SwiftUI
import Combine

// 앱 설정 관리 (UserDefaults 기반, 단 민감 정보는 Keychain 사용)
@MainActor
class AppSettings: ObservableObject {
    static let shared = AppSettings()

    // API 모드 (CLI / API)
    @AppStorage("apiMode") var apiModeRaw: String = APIMode.api.rawValue

    // API 키 (Keychain에 저장 — 평문 UserDefaults 미사용)
    // 외부 접근 API는 기존과 동일(get/set)하게 유지하여 호출부 변경 최소화
    @Published var apiKey: String = "" {
        didSet {
            // 값 변경 시 즉시 Keychain에 반영
            guard apiKey != oldValue else { return }
            KeychainStore.set(apiKey, for: Self.apiKeyKeychainKey)
        }
    }

    // Keychain 항목 키 + 마이그레이션 식별용 상수
    private static let apiKeyKeychainKey = "apiKey"
    private static let apiKeyMigratedFlag = "apiKeyMigratedToKeychain"

    // 캐릭터 설정
    @AppStorage("characterType") var characterTypeRaw: String = CharacterType.blueRobot.rawValue
    @AppStorage("characterSize") var characterSize: Double = 64.0

    // 음성 설정
    @AppStorage("voiceType") var voiceTypeRaw: String = VoiceType.none.rawValue

    // 모델 설정
    @AppStorage("claudeModel") var claudeModelRaw: String = ClaudeModel.sonnet.rawValue

    // 패널 표시 여부
    @AppStorage("characterPanelVisible") var isPanelVisible: Bool = true

    // TTS 활성화
    @AppStorage("ttsEnabled") var ttsEnabled: Bool = false

    // Lottie 애니메이션 사용 여부 (향후 Lottie 파일 준비 후 활성화)
    @AppStorage("useAnimation") var useAnimation: Bool = false

    // MARK: - 초기화 & 마이그레이션

    private init() {
        // 기존 UserDefaults 평문 키 → Keychain 1회 마이그레이션
        migrateAPIKeyIfNeeded()
        // Keychain에 저장된 키를 메모리로 로드 (didSet 재진입 방지 위해 직접 대입)
        let stored = KeychainStore.get(Self.apiKeyKeychainKey) ?? ""
        // didSet은 동일 값이면 무시되지만, init 단계에서는 안전하게 직접 할당
        if !stored.isEmpty {
            apiKey = stored
        }
    }

    // UserDefaults에 평문으로 남아있던 API 키를 Keychain으로 옮기고 평문은 제거한다. (최초 1회)
    private func migrateAPIKeyIfNeeded() {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: Self.apiKeyMigratedFlag) else { return }

        if let legacyKey = defaults.string(forKey: Self.apiKeyKeychainKey),
           !legacyKey.isEmpty {
            // Keychain으로 이전
            KeychainStore.set(legacyKey, for: Self.apiKeyKeychainKey)
        }
        // 평문 흔적 제거
        defaults.removeObject(forKey: Self.apiKeyKeychainKey)
        defaults.set(true, forKey: Self.apiKeyMigratedFlag)
    }

    var apiMode: APIMode {
        get { APIMode(rawValue: apiModeRaw) ?? .api }
        set { apiModeRaw = newValue.rawValue }
    }

    var characterType: CharacterType {
        get { CharacterType(rawValue: characterTypeRaw) ?? .blueRobot }
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

    // CLI 모드면 항상 true, API 모드면 키 필요
    var isAPIKeySet: Bool {
        if apiMode == .cli { return true }
        return !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // 캐릭터 사이즈 범위
    static let minSize: Double = 60.0
    static let maxSize: Double = 300.0
}
