import SwiftUI

// 메뉴바 드롭다운 뷰 (Solo 모드 전용)
struct MenuBarView: View {
    @ObservedObject private var settings = AppSettings.shared
    @ObservedObject private var apiService = ClaudeAPIService.shared
    @ObservedObject private var historyService = ChatHistoryService.shared

    var body: some View {
        VStack(spacing: 0) {
            // 헤더
            HStack {
                Text(settings.characterType.workingEmoji)
                    .font(.title3)
                VStack(alignment: .leading, spacing: 2) {
                    Text("My Agent on Dock")
                        .font(.headline)
                    HStack(spacing: 4) {
                        Circle()
                            .fill(settings.isAPIKeySet ? .green : .red)
                            .frame(width: 6, height: 6)
                        Text(settings.isAPIKeySet ? "API 연결됨" : "API 키 미설정")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)

            Divider()

            // 에이전트 상태
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

            // 모델 정보
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

            Divider()

            // 메뉴 항목들
            VStack(spacing: 0) {
                // 대화 창 열기
                MenuButton(
                    icon: "message.fill",
                    title: "대화 창 열기",
                    shortcut: "Click Character"
                ) {
                    NotificationCenter.default.post(name: .togglePromptWindow, object: nil)
                }

                // Dock 캐릭터 표시 토글
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

                // 최근 대화 섹션
                if !historyService.recentConversations.isEmpty {
                    Divider().padding(.vertical, 4)

                    HStack {
                        Image(systemName: "clock")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(width: 20)
                        Text("최근 대화")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.secondary)
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
                                Image(systemName: "bubble.left")
                                    .font(.caption)
                                    .frame(width: 20)
                                Text(conversation.title)
                                    .font(.caption)
                                    .lineLimit(1)
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

                // 설정
                MenuButton(icon: "gearshape.fill", title: "설정") {
                    NotificationCenter.default.post(name: .openSettings, object: nil)
                }

                Divider().padding(.vertical, 4)

                // 종료
                MenuButton(icon: "power", title: "종료") {
                    NSApplication.shared.terminate(nil)
                }
            }
            .padding(.vertical, 4)
        }
        .frame(width: 280)
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
