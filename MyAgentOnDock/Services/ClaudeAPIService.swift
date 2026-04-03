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

    // Snoozing 타이머 (5분 이상 idle 시 snoozing 상태)
    private var snoozingTask: Task<Void, Never>?
    private let snoozingDelay: TimeInterval = 300  // 5분

    // 초기화 시 snoozing 타이머 시작
    init() {
        resetSnoozingTimer()
    }

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

        // Snoozing 타이머 리셋 (활동 감지)
        resetSnoozingTimer()

        // 새 메시지 수신 표정 (잠깐)
        state = .newMessage
        try? await Task.sleep(nanoseconds: 600_000_000)

        // 사용자 메시지 추가
        let userChat = ChatMessage(role: .user, content: userMessage)
        messages.append(userChat)
        state = .thinking
        streamingText = ""

        do {
            // 스트리밍 시작 전 잠깐 loading 상태
            try? await Task.sleep(nanoseconds: 300_000_000)
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

            // 응답 길이에 따른 감정 표현
            let responseEmotionState = determineCompletionEmotion(for: finalText)
            state = responseEmotionState

            // TTS 재생
            if settings.voiceType != .none {
                state = .voiceMode
                TTSService.shared.speak(finalText, voiceType: settings.voiceType)
                // TTS 완료 대기 (평균 읽기 속도 기준 예상)
                let estimatedDuration = Double(finalText.count) * 0.06
                let clampedDuration = min(max(estimatedDuration, 1.0), 30.0)
                try? await Task.sleep(nanoseconds: UInt64(clampedDuration * 1_000_000_000))
            }

            // 감정 상태 자동 복귀
            if let delay = responseEmotionState.autoRevertDelay {
                if settings.voiceType == .none {
                    try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            }
            state = .idle

            // 대화 기록 저장
            saveCurrentConversation()

        } catch let apiError as APIError {
            streamingText = ""
            // 에러 종류별 감정 표현
            switch apiError {
            case .invalidAPIKey:
                state = .sad
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                state = .error("유효하지 않은 API 키")
            case .httpError(let code, let msg):
                if code == 429 {
                    state = .angry
                    try? await Task.sleep(nanoseconds: 2_000_000_000)
                    state = .lowBattery
                    try? await Task.sleep(nanoseconds: 1_500_000_000)
                    state = .error("요청 한도 초과 (429)")
                } else if code >= 500 {
                    state = .outOfService
                    try? await Task.sleep(nanoseconds: 2_000_000_000)
                    state = .error("서버 오류 (\(code))")
                } else {
                    state = .surprised
                    try? await Task.sleep(nanoseconds: 1_500_000_000)
                    state = .error("HTTP \(code): \(msg)")
                }
            case .parseError:
                state = .crazy
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                state = .error("응답 파싱 실패")
            default:
                state = .surprised
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                state = .error(apiError.localizedDescription)
            }
        } catch {
            streamingText = ""
            state = .sad
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            state = .error(error.localizedDescription)
        }
    }

    // 응답 완료 시 감정 결정
    private func determineCompletionEmotion(for text: String) -> AgentState {
        let length = text.count
        // 웃음/유머 키워드 감지
        let laughKeywords = ["😂", "🤣", "하하", "ㅋㅋ", "농담", "재미있"]
        let heartKeywords = ["❤️", "💕", "사랑", "감사", "훌륭", "완벽", "최고"]

        if laughKeywords.contains(where: { text.contains($0) }) {
            return .laughing
        } else if heartKeywords.contains(where: { text.contains($0) }) {
            return .heartEyes
        } else if length > 800 {
            return .excited  // 긴 응답 → 흥분
        } else if length > 300 {
            return .pleased  // 보통 응답 → 만족
        } else {
            return .winking  // 짧은 응답 → 윙크
        }
    }

    // Snoozing 타이머 리셋
    private func resetSnoozingTimer() {
        snoozingTask?.cancel()
        snoozingTask = Task { [weak self] in
            guard let self else { return }
            try? await Task.sleep(nanoseconds: UInt64(self.snoozingDelay * 1_000_000_000))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                if case .idle = self.state {
                    self.state = .snoozing
                }
            }
        }
    }

    // 대화 초기화
    func clearMessages() {
        messages.removeAll()
        streamingText = ""
        state = .idle
        currentConversationId = nil
        resetSnoozingTimer()
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
