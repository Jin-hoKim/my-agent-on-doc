import Foundation

// 대화 기록 관리 서비스 (Application Support에 JSON 저장)
@MainActor
class ChatHistoryService: ObservableObject {
    static let shared = ChatHistoryService()

    @Published var conversations: [Conversation] = []

    private let fileName = "conversations.json"

    private var storageURL: URL? {
        guard let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first else { return nil }

        let appDir = appSupport.appendingPathComponent("MyAgentOnDock", isDirectory: true)
        try? FileManager.default.createDirectory(at: appDir, withIntermediateDirectories: true)
        return appDir.appendingPathComponent(fileName)
    }

    init() {
        loadFromDisk()
    }

    // 대화 저장 (신규 or 업데이트)
    func saveConversation(_ conversation: Conversation) {
        if let idx = conversations.firstIndex(where: { $0.id == conversation.id }) {
            conversations[idx] = conversation
        } else {
            conversations.insert(conversation, at: 0)
        }
        // 최대 50개 유지
        if conversations.count > 50 {
            conversations = Array(conversations.prefix(50))
        }
        saveToDisk()
    }

    // 대화 삭제
    func deleteConversation(id: UUID) {
        conversations.removeAll { $0.id == id }
        saveToDisk()
    }

    // 전체 삭제
    func deleteAll() {
        conversations.removeAll()
        saveToDisk()
    }

    // 최근 대화 목록 (최대 5개)
    var recentConversations: [Conversation] {
        Array(conversations.prefix(5))
    }

    // 디스크 저장
    private func saveToDisk() {
        guard let url = storageURL else { return }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        do {
            let data = try encoder.encode(conversations)
            try data.write(to: url, options: .atomic)
        } catch {
            // 저장 실패는 무시 (앱 기능에 영향 없음)
        }
    }

    // 디스크 로드
    private func loadFromDisk() {
        guard let url = storageURL,
              FileManager.default.fileExists(atPath: url.path) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        do {
            let data = try Data(contentsOf: url)
            conversations = try decoder.decode([Conversation].self, from: data)
        } catch {
            // 로드 실패 시 빈 배열 유지
            conversations = []
        }
    }
}
