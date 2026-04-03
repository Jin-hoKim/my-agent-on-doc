import SwiftUI

// 프롬프트 입력 및 대화 창
struct PromptWindowView: View {
    @ObservedObject private var apiService = ClaudeAPIService.shared
    @ObservedObject private var settings = AppSettings.shared
    @State private var inputText = ""
    @FocusState private var isInputFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // 헤더
            headerView

            Divider()

            // API 키 미설정 시 안내
            if !settings.isAPIKeySet {
                apiKeyWarningView
            } else {
                // 대화 영역
                chatAreaView

                Divider()

                // 입력 영역
                inputAreaView
            }
        }
        .frame(width: 480, height: 560)
        .background(.ultraThickMaterial)
    }

    // 헤더
    private var headerView: some View {
        HStack {
            Text(settings.characterType.workingEmoji)
                .font(.title2)
            VStack(alignment: .leading, spacing: 2) {
                Text("My Agent")
                    .font(.headline)
                Text(settings.claudeModel.shortName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            // 대화 초기화
            Button(action: { apiService.clearMessages() }) {
                Image(systemName: "trash")
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            .help("대화 초기화")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // API 키 미설정 안내
    private var apiKeyWarningView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "key.fill")
                .font(.system(size: 40))
                .foregroundColor(.orange)
            Text("API 키를 설정해주세요")
                .font(.headline)
            Text("메뉴바 아이콘 → 설정에서\nClaude API 키를 입력하세요.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding()
    }

    // 대화 영역
    private var chatAreaView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    if apiService.messages.isEmpty {
                        emptyStateView
                    }

                    ForEach(apiService.messages) { message in
                        MessageBubbleView(message: message, characterEmoji: settings.characterType.workingEmoji)
                            .id(message.id)
                    }

                    // 로딩 인디케이터
                    if apiService.state.isWorking {
                        HStack(spacing: 8) {
                            Text(settings.characterType.thinkingEmoji)
                                .font(.title3)
                            TypingIndicatorView()
                        }
                        .padding(.horizontal, 16)
                        .id("loading")
                    }
                }
                .padding(.vertical, 12)
            }
            .onChange(of: apiService.messages.count) { _, _ in
                withAnimation {
                    if let lastId = apiService.messages.last?.id {
                        proxy.scrollTo(lastId, anchor: .bottom)
                    } else {
                        proxy.scrollTo("loading", anchor: .bottom)
                    }
                }
            }
        }
    }

    // 빈 상태 뷰
    private var emptyStateView: some View {
        VStack(spacing: 8) {
            Text(settings.characterType.idleEmoji)
                .font(.system(size: 48))
            Text("무엇을 도와드릴까요?")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }

    // 입력 영역
    private var inputAreaView: some View {
        HStack(spacing: 8) {
            TextField("메시지를 입력하세요...", text: $inputText, axis: .vertical)
                .textFieldStyle(.plain)
                .lineLimit(1...5)
                .focused($isInputFocused)
                .onSubmit {
                    if !NSEvent.modifierFlags.contains(.shift) {
                        sendMessage()
                    }
                }

            Button(action: sendMessage) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title2)
                    .foregroundColor(canSend ? settings.characterType.themeColor : .gray)
            }
            .buttonStyle(.plain)
            .disabled(!canSend)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .onAppear {
            isInputFocused = true
        }
    }

    private var canSend: Bool {
        !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !apiService.state.isWorking
    }

    private func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !apiService.state.isWorking else { return }
        inputText = ""
        Task {
            await apiService.sendMessage(text)
        }
    }
}

// 메시지 말풍선
struct MessageBubbleView: View {
    let message: ChatMessage
    let characterEmoji: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if message.role == .assistant {
                Text(characterEmoji)
                    .font(.title3)
                    .frame(width: 28)
            }

            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(message.role == .user
                                  ? Color.accentColor.opacity(0.15)
                                  : Color.secondary.opacity(0.1))
                    )
                    .textSelection(.enabled)

                Text(timeString(message.timestamp))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: 360, alignment: message.role == .user ? .trailing : .leading)

            if message.role == .user {
                Image(systemName: "person.circle.fill")
                    .font(.title3)
                    .foregroundColor(.accentColor)
                    .frame(width: 28)
            }
        }
        .frame(maxWidth: .infinity, alignment: message.role == .user ? .trailing : .leading)
        .padding(.horizontal, 16)
    }

    private func timeString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

// 타이핑 인디케이터
struct TypingIndicatorView: View {
    @State private var dotCount = 0

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(Color.secondary)
                    .frame(width: 6, height: 6)
                    .opacity(dotCount == index ? 1.0 : 0.3)
            }
        }
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 0.4, repeats: true) { _ in
                dotCount = (dotCount + 1) % 3
            }
        }
    }
}
