import SwiftUI

// Dock 위에 표시되는 에이전트 캐릭터 뷰
struct DockCharacterView: View {
    @ObservedObject private var settings = AppSettings.shared
    @ObservedObject private var apiService = ClaudeAPIService.shared
    @State private var isAnimating = false
    @State private var pulseScale: CGFloat = 1.0

    var body: some View {
        let character = settings.characterType
        let state = apiService.state
        let size = settings.characterSize

        VStack(spacing: 2) {
            // 캐릭터 이모지
            ZStack {
                // 감정 상태별 배경 원
                Circle()
                    .fill(backgroundGradient(for: state, color: character.themeColor))
                    .frame(width: size * 0.85, height: size * 0.85)
                    .shadow(
                        color: shadowColor(for: state, themeColor: character.themeColor),
                        radius: shadowRadius(for: state)
                    )
                    .scaleEffect(isAnimating && state.isWorking ? pulseScale : 1.0)

                // 이모지 캐릭터 (상태별 표정)
                Text(character.emoji(for: state))
                    .font(.system(size: size * 0.45))
                    .scaleEffect(emojiScale(for: state))
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: state)

                // 작업 상태 인디케이터 (초록 점)
                if state.isWorking {
                    Circle()
                        .fill(workingIndicatorColor(for: state))
                        .frame(width: 10, height: 10)
                        .shadow(color: workingIndicatorColor(for: state), radius: 3)
                        .offset(x: size * 0.32, y: -size * 0.32)
                }

                // 감정 상태 오버레이 배지
                emotionBadge(for: state, size: size)
            }

            // 상태 텍스트
            Text(state.statusText)
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(statusTextColor(for: state))
                .lineLimit(1)
                .animation(.easeInOut(duration: 0.2), value: state)
        }
        .frame(width: size + 10, height: size + 25)
        .onTapGesture {
            togglePromptWindow()
        }
        .onAppear {
            startPulseAnimation()
        }
        .onChange(of: apiService.state.isWorking) { _, working in
            if working {
                startPulseAnimation()
            }
        }
    }

    // MARK: - 배경 그래디언트 (감정별)
    private func backgroundGradient(for state: AgentState, color: Color) -> some ShapeStyle {
        switch state {
        // 작업 중 상태: 테마 색상
        case .thinking, .loading:
            return LinearGradient(
                colors: [color.opacity(0.2), color.opacity(0.5)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        case .streaming:
            return LinearGradient(
                colors: [color.opacity(0.3), color.opacity(0.7)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        case .responding:
            return LinearGradient(
                colors: [color.opacity(0.2), color.opacity(0.4)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        case .voiceMode:
            return LinearGradient(
                colors: [.purple.opacity(0.3), .pink.opacity(0.5)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        // 긍정 감정: 따뜻한 색상
        case .excited:
            return LinearGradient(
                colors: [.yellow.opacity(0.3), .orange.opacity(0.5)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        case .pleased, .winking:
            return LinearGradient(
                colors: [.green.opacity(0.2), .mint.opacity(0.4)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        case .laughing:
            return LinearGradient(
                colors: [.yellow.opacity(0.2), .green.opacity(0.3)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        case .heartEyes:
            return LinearGradient(
                colors: [.pink.opacity(0.3), .red.opacity(0.4)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        case .newMessage:
            return LinearGradient(
                colors: [.blue.opacity(0.3), .cyan.opacity(0.4)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        // 부정 감정: 차가운/강한 색상
        case .angry:
            return LinearGradient(
                colors: [.red.opacity(0.3), .orange.opacity(0.5)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        case .sad:
            return LinearGradient(
                colors: [.blue.opacity(0.2), .indigo.opacity(0.3)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        case .error:
            return LinearGradient(
                colors: [.red.opacity(0.3), .red.opacity(0.5)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        case .outOfService:
            return LinearGradient(
                colors: [.gray.opacity(0.3), .gray.opacity(0.5)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        case .lowBattery:
            return LinearGradient(
                colors: [.orange.opacity(0.2), .red.opacity(0.3)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        case .surprised:
            return LinearGradient(
                colors: [.yellow.opacity(0.2), .orange.opacity(0.3)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        case .crazy:
            return LinearGradient(
                colors: [.purple.opacity(0.3), .pink.opacity(0.4)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        // 중립/대기 상태
        case .snoozing:
            return LinearGradient(
                colors: [.gray.opacity(0.1), .blue.opacity(0.2)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        default:
            return LinearGradient(
                colors: [.white.opacity(0.1), .white.opacity(0.2)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        }
    }

    // MARK: - 그림자 색상
    private func shadowColor(for state: AgentState, themeColor: Color) -> Color {
        switch state {
        case .thinking, .loading, .streaming, .responding: return themeColor.opacity(0.6)
        case .voiceMode:    return .purple.opacity(0.5)
        case .excited:      return .orange.opacity(0.5)
        case .pleased, .winking: return .green.opacity(0.4)
        case .laughing:     return .yellow.opacity(0.4)
        case .heartEyes:    return .pink.opacity(0.5)
        case .newMessage:   return .blue.opacity(0.5)
        case .angry:        return .red.opacity(0.5)
        case .sad:          return .indigo.opacity(0.3)
        case .error:        return .red.opacity(0.6)
        case .crazy:        return .purple.opacity(0.5)
        default:            return .black.opacity(0.2)
        }
    }

    // MARK: - 그림자 반경
    private func shadowRadius(for state: AgentState) -> CGFloat {
        switch state {
        case .thinking, .loading, .streaming, .responding, .voiceMode: return 12
        case .excited, .heartEyes, .laughing: return 10
        case .angry, .error: return 8
        case .snoozing, .neutral, .outOfService: return 2
        default: return 4
        }
    }

    // MARK: - 이모지 크기 스케일
    private func emojiScale(for state: AgentState) -> CGFloat {
        switch state {
        case .excited:      return 1.2
        case .angry:        return 1.1
        case .surprised:    return 1.15
        case .laughing:     return 1.1
        case .heartEyes:    return 1.15
        case .newMessage:   return 0.9
        case .snoozing:     return 0.95
        case .outOfService: return 0.85
        default:            return 1.0
        }
    }

    // MARK: - 작업 인디케이터 색상
    private func workingIndicatorColor(for state: AgentState) -> Color {
        switch state {
        case .voiceMode:    return .purple
        case .streaming:    return .green
        case .thinking, .loading: return .orange
        default:            return .green
        }
    }

    // MARK: - 감정 배지 오버레이
    @ViewBuilder
    private func emotionBadge(for state: AgentState, size: CGFloat) -> some View {
        switch state {
        case .voiceMode:
            // 음파 애니메이션 인디케이터
            HStack(spacing: 2) {
                ForEach(0..<3, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 1)
                        .fill(.purple)
                        .frame(width: 3, height: CGFloat([6, 10, 7][i]))
                        .animation(
                            .easeInOut(duration: 0.4).repeatForever().delay(Double(i) * 0.1),
                            value: isAnimating
                        )
                }
            }
            .offset(x: size * 0.3, y: size * 0.3)

        case .newMessage:
            // 새 메시지 빨간 점
            Circle()
                .fill(.red)
                .frame(width: 10, height: 10)
                .offset(x: size * 0.32, y: -size * 0.32)
                .transition(.scale)

        case .lowBattery:
            // 배터리 아이콘
            Text("⚠️")
                .font(.system(size: 10))
                .offset(x: size * 0.3, y: size * 0.3)

        case .snoozing:
            // 졸음 Z 표시
            Text("💤")
                .font(.system(size: size * 0.2))
                .offset(x: size * 0.3, y: -size * 0.3)

        default:
            EmptyView()
        }
    }

    // MARK: - 상태 텍스트 색상
    private func statusTextColor(for state: AgentState) -> Color {
        switch state {
        case .thinking, .loading, .streaming, .responding, .voiceMode: return .green
        case .excited, .pleased, .winking, .laughing, .heartEyes: return .green
        case .angry, .error, .outOfService: return .red
        case .sad, .lowBattery: return .orange
        case .snoozing: return .secondary
        case .newMessage: return .blue
        case .crazy, .surprised: return .purple
        default: return .secondary
        }
    }

    // MARK: - 펄스 애니메이션
    private func startPulseAnimation() {
        isAnimating = true
        withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
            pulseScale = 1.08
        }
    }

    // MARK: - 프롬프트 창 토글
    private func togglePromptWindow() {
        NotificationCenter.default.post(name: .togglePromptWindow, object: nil)
    }
}

extension Notification.Name {
    static let togglePromptWindow = Notification.Name("togglePromptWindow")
}
