import SwiftUI

// 메뉴바 드롭다운 뷰 (Solo + Team 모드 통합)
struct MenuBarView: View {
    @EnvironmentObject private var configService: AgentsConfigService
    @ObservedObject private var settings = AppSettings.shared
    @ObservedObject private var apiService = ClaudeAPIService.shared
    @ObservedObject private var historyService = ChatHistoryService.shared

    var isTeamMode: Bool {
        configService.connectionStatus == .connected && !configService.agents.isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            // 헤더
            headerSection

            Divider()

            // Team 모드 에이전트 상태 또는 Solo 모드 상태
            if isTeamMode {
                teamStatusSection
            } else {
                soloStatusSection
            }

            Divider()

            // 메뉴 항목
            menuActions

            .padding(.vertical, 4)
        }
        .frame(width: 280)
    }

    // MARK: - 헤더

    private var headerSection: some View {
        HStack {
            Text(isTeamMode ? "🤝" : settings.characterType.workingEmoji)
                .font(.title3)
            VStack(alignment: .leading, spacing: 2) {
                Text(isTeamMode ? "Team 모드" : "My Agent on Dock")
                    .font(.headline)
                HStack(spacing: 4) {
                    Circle()
                        .fill(headerStatusColor)
                        .frame(width: 6, height: 6)
                    Text(headerStatusText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    private var headerStatusColor: Color {
        if isTeamMode { return .green }
        return settings.isAPIKeySet ? .green : .red
    }

    private var headerStatusText: String {
        if isTeamMode {
            let active = configService.agents.filter { $0.isActive }.count
            return "\(active)/\(configService.agents.count)명 활성"
        }
        return settings.isAPIKeySet ? "API 연결됨" : "API 키 미설정"
    }

    // MARK: - Team 상태 섹션

    private var teamStatusSection: some View {
        VStack(spacing: 0) {
            ForEach(configService.agents) { agent in
                HStack(spacing: 8) {
                    Circle()
                        .fill(agent.isActive ? Color.green : Color.gray.opacity(0.4))
                        .frame(width: 7, height: 7)
                    Text(agent.emoji)
                        .font(.system(size: 13))
                    Text(agent.name.isEmpty ? agent.id : agent.name)
                        .font(.subheadline)
                    Spacer()
                    Text(agent.id)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 5)
            }
        }
    }

    // MARK: - Solo 상태 섹션

    private var soloStatusSection: some View {
        VStack(spacing: 0) {
            HStack {
                Circle()
                    .fill(apiService.state.isWorking ? .green : .gray.opacity(0.4))
                    .frame(width: 8, height: 8)
                Text(settings.characterType.displayName)
                    .font(.subheadline.weight(.medium))
                Spacer()
                Text(apiService.state.statusText)
                    .font(.caption)
                    .foregroundColor(apiService.state.isWorking ? .green : .secondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)

            HStack {
                Image(systemName: "cpu")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(settings.claudeModel.displayName)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 8)
        }
    }

    // MARK: - 메뉴 버튼들

    private var menuActions: some View {
        VStack(spacing: 0) {
            // Solo 모드: 대화 창 열기
            if !isTeamMode {
                MenuButton(
                    icon: "message.fill",
                    title: "대화 창 열기",
                    shortcut: "Click Character"
                ) {
                    NotificationCenter.default.post(name: .togglePromptWindow, object: nil)
                }
            }

            // Team 모드: 팀 프로젝트 연결 설정
            MenuButton(
                icon: isTeamMode ? "person.3.fill" : "link.badge.plus",
                title: isTeamMode ? "팀 설정" : "팀 프로젝트 연결"
            ) {
                NotificationCenter.default.post(name: .openSetup, object: nil)
            }

            // Solo 모드: Dock 캐릭터 표시 토글
            if !isTeamMode {
                Toggle(isOn: $settings.isPanelVisible) {
                    HStack {
                        Image(systemName: "dock.rectangle")
                            .font(.subheadline)
                            .frame(width: 20)
                        Text("Dock 위 캐릭터 표시")
                            .font(.subheadline)
                    }
                }
                .toggleStyle(.switch)
                .controlSize(.small)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
            }

            // 최근 대화 (Solo 모드)
            if !isTeamMode && !historyService.recentConversations.isEmpty {
                Divider().padding(.vertical, 4)

                HStack {
                    Image(systemName: "clock").font(.caption).foregroundColor(.secondary).frame(width: 20)
                    Text("최근 대화").font(.caption.weight(.semibold)).foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.horizontal, 14)
                .padding(.top, 4)

                ForEach(historyService.recentConversations) { conversation in
                    Button(action: {
                        apiService.loadConversation(conversation)
                        NotificationCenter.default.post(name: .togglePromptWindow, object: nil)
                    }) {
                        HStack {
                            Image(systemName: "bubble.left").font(.caption).frame(width: 20)
                            Text(conversation.title).font(.caption).lineLimit(1)
                            Spacer()
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 4)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }

            Divider().padding(.vertical, 4)

            MenuButton(icon: "gearshape.fill", title: "설정") {
                NotificationCenter.default.post(name: .openSettings, object: nil)
            }

            Divider().padding(.vertical, 4)

            MenuButton(icon: "power", title: "종료") {
                NSApplication.shared.terminate(nil)
            }
        }
    }
}

// 메뉴 버튼 컴포넌트
struct MenuButton: View {
    let icon: String
    let title: String
    var shortcut: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.subheadline)
                    .frame(width: 20)
                Text(title)
                    .font(.subheadline)
                Spacer()
                if let shortcut {
                    Text(shortcut)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

extension Notification.Name {
    static let openSettings = Notification.Name("openSettings")
}
