import Foundation
import Security

// Keychain 기반 민감 정보 저장소
// API 키 등 비밀 값을 평문(UserDefaults) 대신 시스템 Keychain에 안전하게 보관한다.
enum KeychainStore {

    // Keychain 항목 식별용 서비스 이름 (번들 식별자 기반)
    private static let service: String = {
        Bundle.main.bundleIdentifier ?? "com.dockling.myagentondock"
    }()

    // MARK: - 저장

    // 문자열 값을 Keychain에 저장한다. 동일 키가 있으면 갱신, 빈 값이면 삭제한다.
    @discardableResult
    static func set(_ value: String, for key: String) -> Bool {
        // 빈 문자열은 항목 제거로 처리 (UserDefaults 빈값 동작과 일치)
        guard !value.isEmpty else {
            return delete(key)
        }

        guard let data = value.data(using: .utf8) else { return false }

        // 기존 항목이 있으면 업데이트, 없으면 추가
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
        ]

        let attributes: [String: Any] = [
            kSecValueData as String: data,
            // 기기 잠금 해제 후에만 접근 가능 (마이그레이션 불가, 보안 강화)
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
        ]

        let updateStatus = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if updateStatus == errSecSuccess {
            return true
        }

        if updateStatus == errSecItemNotFound {
            // 신규 추가
            var addQuery = query
            addQuery[kSecValueData as String] = data
            addQuery[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
            let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
            return addStatus == errSecSuccess
        }

        return false
    }

    // MARK: - 조회

    // Keychain에서 문자열 값을 조회한다. 없으면 nil.
    static func get(_ key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            return nil
        }

        return value
    }

    // MARK: - 삭제

    // Keychain에서 항목을 삭제한다. 없어도 성공으로 간주한다.
    @discardableResult
    static func delete(_ key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
        ]

        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
}
