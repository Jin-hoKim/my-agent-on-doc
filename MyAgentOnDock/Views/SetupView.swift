import SwiftUI
import AppKit

// 팀 프로젝트 연결 설정 뷰
struct SetupView: View {
    @EnvironmentObject private var configService: AgentsConfigService
    @EnvironmentObject private var bookmarkService: BookmarkService

    @State private var previewAgents: [TeamAgent] = []
    @State private var previewStatus: PreviewStatus = .idle
    @State private var isConnecting = false

    enum PreviewStatus {
        case idle
        case checking
        case found([TeamAgent])
        case notFound
        case parseError(String)
    }

    var body: some View {
        VStack(spacing: 0) {
            // 헤더
            HStack {
                Image(systemName: "person.3.fill")
                    .font(.title3)
                    .foregroundColor(.accentColor)
                VStack(alignment: .leading, spacing: 2) {
                    Text("팀 프로젝트 연결")
                        .font(.headline)
                    Text("agents.json이 있는 프로젝트 폴더를 선택하세요")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)

            Divider()

            ScrollView {
                VStack(spacing: 20) {

                    // 섹션 1: 프로젝트 폴더 선택
                    sectionFolderSelect

                    Divider().padding(.horizontal)

                    // 섹션 2: agents.json 상태
                    sectionStatus

                    // 섹션 3: 팀 미리보기 (파싱 성공 시)
                    if case .found(let agents) = previewStatus {
                        Divider().padding(.horizontal)
                        sectionPreview(agents: agents)
                    }

                    // 섹션 4: 연결 버튼
                    sectionConnectButton

                    Spacer(minLength: 20)
                }
                .padding(.vertical, 16)
            }
        }
        .frame(width: 520, height: 600)
        .background(.ultraThickMaterial)
        .onAppear {
            // 이미 연결된 경우 현재 상태 표시
            if configService.connectionStatus == .connected {
                previewStatus = .found(configService.agents)
            } else if !bookmarkService.projectPath.isEmpty {
                Task { await checkAgentsJson() }
            }
        }
    }

    // MARK: - 섹션 1: 폴더 선택

    private var sectionFolderSelect: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("프로젝트 폴더", systemImage: "folder.fill")
                .font(.subheadline.weight(.semibold))

            HStack(spacing: 10) {
                // 경로 표시
                Text(bookmarkService.projectPath.isEmpty
                     ? "폴더를 선택하세요"
                     : bookmarkService.projectPath)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(bookmarkService.projectPath.isEmpty ? .secondary : .primary)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(8)
                    .background(RoundedRectangle(cornerRadius: 6).fill(Color.secondary.opacity(0.08)))

                // 폴더 선택 버튼
                Button("폴더 선택") {
                    selectFolder()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - 섹션 2: 상태 표시

    private var sectionStatus: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("agents.json 상태", systemImage: "doc.text.magnifyingglass")
                .font(.subheadline.weight(.semibold))

            HStack(spacing: 8) {
                statusIcon
                statusText
                Spacer()
            }
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 8).fill(statusBackgroundColor))
        }
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var statusIcon: some View {
        switch previewStatus {
        case .idle:
            Image(systemName: "circle.dashed").foregroundColor(.secondary)
        case .checking:
            ProgressView().controlSize(.small)
        case .found:
            Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
        case .notFound:
            Image(systemName: "xmark.circle.fill").foregroundColor(.red)
        case .parseError:
            Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.orange)
        }
    }

    @ViewBuilder
    private var statusText: some View {
        switch previewStatus {
        case .idle:
            Text("프로젝트 폴더를 선택하면 자동 감지됩니다")
                .font(.caption).foregroundColor(.secondary)
        case .checking:
            Text("agents.json 확인 중...").font(.caption).foregroundColor(.secondary)
        case .found(let agents):
            Text("팀 구성 감지됨 — 에이전트 \(agents.count)명").font(.caption).foregroundColor(.green)
        case .notFound:
            VStack(alignment: .leading, spacing: 2) {
                Text("agents.json을 찾을 수 없습니다").font(.caption).foregroundColor(.red)
                Text("경로: {프로젝트}/team/agents.json").font(.caption2).foregroundColor(.secondary)
            }
        case .parseError(let msg):
            VStack(alignment: .leading, spacing: 2) {
                Text("파싱 오류: \(msg)").font(.caption).foregroundColor(.orange)
                Text("agents.json 형식을 확인하세요").font(.caption2).foregroundColor(.secondary)
            }
        }
    }

    private var statusBackgroundColor: Color {
        switch previewStatus {
        case .found: return .green.opacity(0.08)
        case .notFound: return .red.opacity(0.08)
        case .parseError: return .orange.opacity(0.08)
        default: return .secondary.opacity(0.06)
        }
    }

    // MARK: - 섹션 3: 팀 미리보기

    private func sectionPreview(agents: [TeamAgent]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("팀 구성 미리보기", systemImage: "person.3")
                .font(.subheadline.weight(.semibold))

            VStack(spacing: 0) {
                // 헤더
                HStack {
                    Text("역할").frame(width: 80, alignment: .leading)
                    Text("이름").frame(width: 100, alignment: .leading)
                    Text("모델").frame(width: 70, alignment: .leading)
                    Text("설명").frame(maxWidth: .infinity, alignment: .leading)
                }
                .font(.caption.weight(.semibold))
                .foregroundColor(.secondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.secondary.opacity(0.06))

                Divider()

                ForEach(agents) { agent in
                    HStack {
                        HStack(spacing: 4) {
                            Text(agent.emoji)
                            Text(agent.id)
                                .font(.caption)
                                .lineLimit(1)
                        }
                        .frame(width: 80, alignment: .leading)

                        Text(agent.name)
                            .font(.caption)
                            .lineLimit(1)
                            .frame(width: 100, alignment: .leading)

                        HStack(spacing: 2) {
                            Text(agent.modelBadge)
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(modelColor(agent.model)))
                            Text(agent.model)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                        .frame(width: 70, alignment: .leading)

                        Text(agent.roleDescription)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)

                    if agent.id != agents.last?.id {
                        Divider().padding(.horizontal, 10)
                    }
                }
            }
            .background(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.2)))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - 섹션 4: 연결 버튼

    private var sectionConnectButton: some View {
        HStack(spacing: 12) {
            // 연결 해제 (연결된 경우)
            if configService.connectionStatus == .connected {
                Button("연결 해제") {
                    configService.disconnect()
                    previewStatus = .idle
                }
                .buttonStyle(.bordered)
                .foregroundColor(.red)
            }

            Spacer()

            // 닫기 버튼
            Button("닫기") {
                closeWindow()
            }
            .buttonStyle(.bordered)

            // 팀 연결 버튼
            Button(action: connectTeam) {
                if isConnecting {
                    ProgressView().controlSize(.small)
                } else {
                    Label(configService.connectionStatus == .connected ? "재연결" : "팀 연결", systemImage: "person.3.fill")
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(!canConnect || isConnecting)
        }
        .padding(.horizontal, 20)
    }

    private var canConnect: Bool {
        if case .found = previewStatus { return true }
        return false
    }

    // MARK: - Actions

    private func selectFolder() {
        let result = bookmarkService.selectProjectFolder()
        if result {
            Task { await checkAgentsJson() }
        }
    }

    private func checkAgentsJson() async {
        guard !bookmarkService.projectPath.isEmpty else { return }
        previewStatus = .checking

        do {
            try await Task.sleep(for: .milliseconds(300))
        } catch {}

        let path = bookmarkService.projectPath
        let agentsPath = (path as NSString).appendingPathComponent("team/agents.json")

        guard FileManager.default.fileExists(atPath: agentsPath) else {
            previewStatus = .notFound
            return
        }

        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: agentsPath))
            let config = try JSONDecoder().decode(TeamConfiguration.self, from: data)
            let agents = buildTeamAgents(from: config)
            previewStatus = .found(agents)
        } catch {
            previewStatus = .parseError(error.localizedDescription)
        }
    }

    private func connectTeam() {
        guard case .found = previewStatus else { return }
        isConnecting = true

        Task {
            await configService.loadAgents()
            isConnecting = false

            if configService.connectionStatus == .connected {
                // Team 모드 활성화 알림
                NotificationCenter.default.post(name: .teamModeActivated, object: nil)
                closeWindow()
            }
        }
    }

    private func closeWindow() {
        NSApp.keyWindow?.close()
    }

    private func modelColor(_ model: String) -> Color {
        switch model.lowercased() {
        case let m where m.contains("opus"):   return .purple
        case let m where m.contains("sonnet"): return .blue
        case let m where m.contains("haiku"):  return .orange
        default: return .gray
        }
    }
}
