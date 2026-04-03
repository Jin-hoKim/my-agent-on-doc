import SwiftUI

// Team 모드 Dock 위 멀티 캐릭터 뷰
struct TeamDockView: View {
    @EnvironmentObject private var configService: AgentsConfigService
    @ObservedObject private var settings = AppSettings.shared

    var body: some View {
        if configService.agents.isEmpty {
            // 에이전트 없을 때 안내
            Text("팀 연결 중...")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(8)
        } else {
            HStack(spacing: 8) {
                ForEach(configService.agents) { agent in
                    AgentCharacterView(agent: agent)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
        }
    }
}
