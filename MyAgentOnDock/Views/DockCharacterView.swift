import SwiftUI

// Dock 위에 표시되는 에이전트 캐릭터 뷰
struct DockCharacterView: View {
    @ObservedObject private var settings = AppSettings.shared
    @ObservedObject private var apiService = ClaudeAPIService.shared
    @State private var isAnimating = false
    @State private var showPromptWindow = false

    var body: some View {
        let character = settings.characterType
        let state = apiService.state
        let size = settings.characterSize

        VStack(spacing: 2) {
            // 캐릭터 이모지
            ZStack {
                // 배경 원
                Circle()
                    .fill(backgroundGradient(for: state, color: character.themeColor))
                    .frame(width: size * 0.85, height: size * 0.85)
                    .shadow(color: state.isWorking ? character.themeColor.opacity(0.6) : .black.opacity(0.2),
                            radius: state.isWorking ? 12 : 4)

                // 이모지 캐릭터
                Text(emojiForState(character: character, state: state))
                    .font(.system(size: size * 0.45))
                    .scaleEffect(isAnimating && state.isWorking ? 1.15 : 1.0)
                    .animation(
                        state.isWorking
                            ? .easeInOut(duration: 0.6).repeatForever(autoreverses: true)
                            : .easeInOut(duration: 0.3),
                        value: isAnimating
                    )

                // 작업 상태 인디케이터
                if state.isWorking {
                    Circle()
                        .fill(.green)
                        .frame(width: 10, height: 10)
                        .shadow(color: .green, radius: 3)
                        .offset(x: size * 0.32, y: -size * 0.32)
                }
            }

            // 상태 텍스트
            Text(state.statusText)
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(state.isWorking ? .green : .secondary)
                .lineLimit(1)
        }
        .frame(width: size + 10, height: size + 25)
        .onTapGesture {
            togglePromptWindow()
        }
        .onAppear {
            isAnimating = true
        }
        .onChange(of: apiService.state.isWorking) { _, working in
            isAnimating = working
            if working { isAnimating = true }
        }
    }

    // 상태별 배경 그래디언트
    private func backgroundGradient(for state: AgentState, color: Color) -> some ShapeStyle {
        switch state {
        case .thinking, .responding:
            return LinearGradient(
                colors: [color.opacity(0.3), color.opacity(0.6)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        default:
            return LinearGradient(
                colors: [.white.opacity(0.1), .white.opacity(0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    // 상태별 이모지
    private func emojiForState(character: CharacterType, state: AgentState) -> String {
        switch state {
        case .thinking: return character.thinkingEmoji
        case .responding: return character.workingEmoji
        case .error: return "❌"
        case .idle: return character.idleEmoji
        }
    }

    // 프롬프트 창 토글
    private func togglePromptWindow() {
        NotificationCenter.default.post(name: .togglePromptWindow, object: nil)
    }
}

extension Notification.Name {
    static let togglePromptWindow = Notification.Name("togglePromptWindow")
}
