import SwiftUI

// 개별 에이전트 캐릭터 뷰 (Team 모드)
struct AgentCharacterView: View {
    let agent: TeamAgent
    @State private var isAnimating = false
    @ObservedObject private var settings = AppSettings.shared

    var body: some View {
        let size = settings.characterSize

        VStack(spacing: 2) {
            ZStack {
                // 배경 원형 그래디언트
                Circle()
                    .fill(backgroundGradient)
                    .frame(width: size * 0.82, height: size * 0.82)
                    .shadow(
                        color: agent.isActive ? .green.opacity(0.5) : .black.opacity(0.15),
                        radius: agent.isActive ? 10 : 3
                    )

                // 역할 이모지
                Text(agent.emoji)
                    .font(.system(size: size * 0.4))
                    .scaleEffect(isAnimating && agent.isActive ? 1.1 : 1.0)
                    .animation(
                        agent.isActive
                            ? .easeInOut(duration: 0.8).repeatForever(autoreverses: true)
                            : .easeInOut(duration: 0.3),
                        value: isAnimating
                    )

                // 모델 뱃지 (우상단)
                VStack {
                    HStack {
                        Spacer()
                        Text(agent.modelBadge)
                            .font(.system(size: 7, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 3)
                            .padding(.vertical, 1)
                            .background(
                                Capsule()
                                    .fill(modelBadgeColor)
                            )
                    }
                    Spacer()
                }
                .frame(width: size * 0.82, height: size * 0.82)
                .padding(2)

                // 활성 상태 인디케이터 (하단)
                VStack {
                    Spacer()
                    Circle()
                        .fill(agent.isActive ? Color.green : Color.gray.opacity(0.4))
                        .frame(width: 8, height: 8)
                        .shadow(color: agent.isActive ? .green : .clear, radius: 3)
                        .offset(y: 4)
                }
                .frame(width: size * 0.82, height: size * 0.82)
            }

            // 이름 라벨
            Text(agent.name.isEmpty ? agent.id : agent.name)
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(agent.isActive ? .primary : .secondary)
                .lineLimit(1)
                .frame(maxWidth: size + 8)
        }
        .frame(width: size + 8, height: size + 26)
        .onAppear {
            isAnimating = agent.isActive
        }
        .onChange(of: agent.isActive) { _, active in
            withAnimation(.spring()) {
                isAnimating = active
            }
        }
    }

    // 배경 그래디언트 (active: 초록, idle: 회색)
    private var backgroundGradient: LinearGradient {
        if agent.isActive {
            return LinearGradient(
                colors: [Color.green.opacity(0.2), Color.green.opacity(0.4)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                colors: [Color.white.opacity(0.08), Color.white.opacity(0.18)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    // 모델 뱃지 색상
    private var modelBadgeColor: Color {
        switch agent.model.lowercased() {
        case let m where m.contains("opus"):   return .purple
        case let m where m.contains("sonnet"): return .blue
        case let m where m.contains("haiku"):  return .orange
        default: return .gray
        }
    }
}
