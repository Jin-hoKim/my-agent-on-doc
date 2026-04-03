import SwiftUI

// 프롬프트 입력 및 대화 창
struct PromptWindowView: View {
    @ObservedObject private var apiService = ClaudeAPIService.shared
    @ObservedObject private var settings = AppSettings.shared
    @ObservedObject private var historyService = ChatHistoryService.shared
    @State private var inputText = ""
    @FocusState private var isInputFocused: Bool
    @State private var showConversationList = false

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
        .frame(width: 480, height: 580)
        .background(.ultraThickMaterial)
        .sheet(isPresented: $showConversationList) {
            ConversationListView(onSelect: { conversation in
                apiService.loadConversation(conversation)
                showConversationList = false
            })
        }
    }

    // 헤더
    private var headerView: some View {
        HStack(spacing: 8) {
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

            // TTS 중지 버튼
            if settings.ttsEnabled && settings.voiceType != .none {
                Button(action: { TTSService.shared.stop() }) {
                    Image(systemName: "speaker.slash")
                        .foregroundColor(.orange)
                }
                .buttonStyle(.plain)
                .help("음성 중지")
            }

            // 대화 기록
            Button(action: { showConversationList = true }) {
                Image(systemName: "clock.arrow.circlepath")
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            .help("대화 기록")

            // 새 대화
            Button(action: { apiService.startNewConversation() }) {
                Image(systemName: "square.and.pencil")
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            .help("새 대화")

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
        .frame(maxHeight: .infinity)
    }

    // 대화 영역
    private var chatAreaView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    if apiService.messages.isEmpty && apiService.streamingText.isEmpty {
                        emptyStateView
                    }

                    ForEach(apiService.messages) { message in
                        MessageBubbleView(
                            message: message,
                            characterEmoji: settings.characterType.workingEmoji
                        )
                        .id(message.id)
                    }

                    // 스트리밍 중 임시 버블
                    if !apiService.streamingText.isEmpty {
                        StreamingBubbleView(
                            text: apiService.streamingText,
                            characterEmoji: settings.characterType.workingEmoji
                        )
                        .id("streaming")
                    }

                    // 생각 중 인디케이터
                    if apiService.state == .thinking {
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
            .onChange(of: apiService.streamingText) { _, _ in
                withAnimation(.easeOut(duration: 0.1)) {
                    proxy.scrollTo("streaming", anchor: .bottom)
                }
            }
            .onChange(of: apiService.messages.count) { _, _ in
                withAnimation {
                    if let lastId = apiService.messages.last?.id {
                        proxy.scrollTo(lastId, anchor: .bottom)
                    }
                }
            }
            .onChange(of: apiService.state) { _, newState in
                if newState == .thinking {
                    withAnimation {
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
            TextField("메시지를 입력하세요... (Enter 전송, Shift+Enter 줄바꿈)", text: $inputText, axis: .vertical)
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

// 스트리밍 중 실시간 버블
struct StreamingBubbleView: View {
    let text: String
    let characterEmoji: String
    @State private var cursorVisible = true
    @State private var cursorTimer: Timer?

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text(characterEmoji)
                .font(.title3)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                (Text(text) + Text(cursorVisible ? "▋" : " ").foregroundColor(.accentColor))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.secondary.opacity(0.1))
                    )
                    .textSelection(.enabled)
            }
            .frame(maxWidth: 360, alignment: .leading)

            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .onAppear {
            cursorTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
                cursorVisible.toggle()
            }
        }
        .onDisappear {
            cursorTimer?.invalidate()
            cursorTimer = nil
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
    @State private var timer: Timer?

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
            timer = Timer.scheduledTimer(withTimeInterval: 0.4, repeats: true) { _ in
                dotCount = (dotCount + 1) % 3
            }
        }
        .onDisappear {
            timer?.invalidate()
            timer = nil
        }
    }
}

// 대화 목록 시트
struct ConversationListView: View {
    @ObservedObject private var historyService = ChatHistoryService.shared
    var onSelect: (Conversation) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("대화 기록")
                    .font(.headline)
                Spacer()
                Button("닫기") { dismiss() }
                    .buttonStyle(.plain)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider()

            if historyService.conversations.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "clock")
                        .font(.system(size: 36))
                        .foregroundColor(.secondary)
                    Text("저장된 대화가 없습니다")
                        .foregroundColor(.secondary)
                    Spacer()
                }
            } else {
                List {
                    ForEach(historyService.conversations) { conversation in
                        Button(action: { onSelect(conversation) }) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(conversation.title)
                                    .font(.subheadline.weight(.medium))
                                    .lineLimit(1)
                                HStack {
                                    Text("\(conversation.messages.count)개 메시지")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text(relativeTime(conversation.updatedAt))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                    .onDelete { indexSet in
                        for idx in indexSet {
                            historyService.deleteConversation(id: historyService.conversations[idx].id)
                        }
                    }
                }
                .listStyle(.plain)

                Divider()

                Button(role: .destructive) {
                    historyService.deleteAll()
                } label: {
                    HStack {
                        Image(systemName: "trash")
                        Text("전체 삭제")
                    }
                    .foregroundColor(.red)
                    .font(.subheadline)
                }
                .buttonStyle(.plain)
                .padding(.vertical, 10)
            }
        }
        .frame(width: 360, height: 440)
        .background(.ultraThickMaterial)
    }

    private func relativeTime(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
