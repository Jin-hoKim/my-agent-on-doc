import Foundation

// Claude API 호출 서비스
@MainActor
class ClaudeAPIService: ObservableObject {
    static let shared = ClaudeAPIService()

    @Published var state: AgentState = .idle
    @Published var messages: [ChatMessage] = []

    private let apiURL = "https://api.anthropic.com/v1/messages"
    private let apiVersion = "2023-06-01"

    // 시스템 프롬프트
    private let systemPrompt = """
    당신은 사용자의 개인 AI 에이전트입니다. 친절하고 유용한 답변을 제공하세요.
    한국어로 대화하되, 사용자가 다른 언어를 사용하면 해당 언어로 응답하세요.
    """

    // 메시지 전송
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

        do {
            let response = try await callAPI(
                apiKey: settings.apiKey,
                model: settings.claudeModel.rawValue,
                messages: messages
            )
            state = .responding

            let assistantChat = ChatMessage(role: .assistant, content: response)
            messages.append(assistantChat)
            state = .idle
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    // 대화 초기화
    func clearMessages() {
        messages.removeAll()
        state = .idle
    }

    // Claude API 호출
    private func callAPI(apiKey: String, model: String, messages: [ChatMessage]) async throws -> String {
        guard let url = URL(string: apiURL) else {
            throw APIError.invalidURL
        }

        // 메시지 배열 구성
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

        // 응답 파싱
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
