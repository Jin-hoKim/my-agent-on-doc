import Foundation

// Claude API 호출 서비스 (스트리밍 SSE 지원)
@MainActor
class ClaudeAPIService: ObservableObject {
    static let shared = ClaudeAPIService()

    @Published var state: AgentState = .idle
    @Published var messages: [ChatMessage] = []
    @Published var streamingText: String = ""   // 스트리밍 중 임시 텍스트

    private let apiURL = "https://api.anthropic.com/v1/messages"
    private let apiVersion = "2023-06-01"

    // 히스토리 서비스
    private let historyService = ChatHistoryService.shared

    // 현재 대화 ID
    var currentConversationId: UUID?

    // 시스템 프롬프트
    private let systemPrompt = """
    당신은 사용자의 개인 AI 에이전트입니다. 친절하고 유용한 답변을 제공하세요.
    한국어로 대화하되, 사용자가 다른 언어를 사용하면 해당 언어로 응답하세요.
    """

    // 메시지 전송 (스트리밍)
    func sendMessage(_ userMessage: String) async {
        let settings = AppSettings.shared

        guard settings.isAPIKeySet else {
            state = .error("API 키를 설정해주세요")
            return
        }

        // 사용자 메시지 추가
        let userChat = ChatMessage(role: .user, content: userMessage)
        messages.append(userChat)
        state = .thinking
        streamingText = ""

        do {
            state = .streaming
            let finalText = try await streamAPI(
                apiKey: settings.apiKey,
                model: settings.claudeModel.rawValue,
                messages: messages
            )

            // 스트리밍 완료 → 최종 메시지로 변환
            streamingText = ""
            let assistantChat = ChatMessage(role: .assistant, content: finalText)
            messages.append(assistantChat)
            state = .idle

            // TTS 재생
            if settings.voiceType != .none {
                TTSService.shared.speak(finalText, voiceType: settings.voiceType)
            }

            // 대화 기록 저장
            saveCurrentConversation()

        } catch {
            streamingText = ""
            state = .error(error.localizedDescription)
        }
    }

    // 대화 초기화
    func clearMessages() {
        messages.removeAll()
        streamingText = ""
        state = .idle
        currentConversationId = nil
    }

    // 대화 불러오기
    func loadConversation(_ conversation: Conversation) {
        messages = conversation.messages
        currentConversationId = conversation.id
        state = .idle
        streamingText = ""
    }

    // 새 대화 시작
    func startNewConversation() {
        clearMessages()
        currentConversationId = UUID()
    }

    // 현재 대화 저장
    private func saveCurrentConversation() {
        guard !messages.isEmpty else { return }
        let id = currentConversationId ?? UUID()
        currentConversationId = id

        // 첫 번째 사용자 메시지를 제목으로 사용
        let title: String
        if let firstUser = messages.first(where: { $0.role == .user }) {
            let raw = firstUser.content
            title = raw.count > 30 ? String(raw.prefix(30)) + "..." : raw
        } else {
            title = "대화 \(Date().formatted(date: .abbreviated, time: .shortened))"
        }

        let conversation = Conversation(
            id: id,
            title: title,
            messages: messages,
            createdAt: messages.first?.timestamp ?? Date(),
            updatedAt: Date()
        )
        historyService.saveConversation(conversation)
    }

    // SSE 스트리밍 API 호출
    private func streamAPI(apiKey: String, model: String, messages: [ChatMessage]) async throws -> String {
        guard let url = URL(string: apiURL) else {
            throw APIError.invalidURL
        }

        // 메시지 배열 구성 (assistant 메시지 제외하고 현재 전송할 메시지까지)
        let apiMessages = messages.map { msg in
            ["role": msg.role.rawValue, "content": msg.content]
        }

        let body: [String: Any] = [
            "model": model,
            "max_tokens": 4096,
            "system": systemPrompt,
            "stream": true,
            "messages": apiMessages
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue(apiVersion, forHTTPHeaderField: "anthropic-version")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        request.timeoutInterval = 120

        var fullText = ""

        let (asyncBytes, response) = try await URLSession.shared.bytes(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            // 에러 본문 수집
            var errorData = Data()
            for try await byte in asyncBytes {
                errorData.append(byte)
            }
            let errorBody = String(data: errorData, encoding: .utf8) ?? "알 수 없는 오류"
            if httpResponse.statusCode == 401 {
                throw APIError.invalidAPIKey
            }
            throw APIError.httpError(statusCode: httpResponse.statusCode, message: errorBody)
        }

        // SSE 라인별 파싱
        for try await line in asyncBytes.lines {
            guard line.hasPrefix("data: ") else { continue }
            let jsonStr = String(line.dropFirst(6))
            guard jsonStr != "[DONE]" else { break }

            guard let data = jsonStr.data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                continue
            }

            let eventType = json["type"] as? String

            if eventType == "content_block_delta",
               let delta = json["delta"] as? [String: Any],
               let deltaType = delta["type"] as? String,
               deltaType == "text_delta",
               let text = delta["text"] as? String {
                fullText += text
                // 메인 스레드에서 streamingText 업데이트
                await MainActor.run {
                    self.streamingText = fullText
                }
            }
        }

        return fullText
    }

    // 폴백: 비스트리밍 API 호출
    func callAPIFallback(apiKey: String, model: String, messages: [ChatMessage]) async throws -> String {
        guard let url = URL(string: apiURL) else {
            throw APIError.invalidURL
        }

        let apiMessages = messages.map { msg in
            ["role": msg.role.rawValue, "content": msg.content]
        }

        let body: [String: Any] = [
            "model": model,
            "max_tokens": 4096,
            "system": systemPrompt,
            "messages": apiMessages
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue(apiVersion, forHTTPHeaderField: "anthropic-version")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        request.timeoutInterval = 120

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            let errorBody = String(data: data, encoding: .utf8) ?? "알 수 없는 오류"
            if httpResponse.statusCode == 401 {
                throw APIError.invalidAPIKey
            }
            throw APIError.httpError(statusCode: httpResponse.statusCode, message: errorBody)
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = json["content"] as? [[String: Any]],
              let firstBlock = content.first,
              let text = firstBlock["text"] as? String else {
            throw APIError.parseError
        }

        return text
    }
}

// API 에러 정의
enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case invalidAPIKey
    case httpError(statusCode: Int, message: String)
    case parseError

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "잘못된 API URL"
        case .invalidResponse: return "잘못된 응답"
        case .invalidAPIKey: return "유효하지 않은 API 키"
        case .httpError(let code, let msg): return "HTTP \(code): \(msg)"
        case .parseError: return "응답 파싱 실패"
        }
    }
}
