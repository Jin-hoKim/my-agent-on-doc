import Foundation
import Combine
import AppKit

// agents.json 연결 상태
enum ConnectionStatus: Equatable {
    case notConnected
    case connected
    case error(String)

    var displayText: String {
        switch self {
        case .notConnected: return "연결 안됨"
        case .connected: return "연결됨"
        case .error(let msg): return "오류: \(msg)"
        }
    }

    var isConnected: Bool {
        if case .connected = self { return true }
        return false
    }
}

// agents.json 파싱 + FSEvents 파일 감시
@MainActor
class AgentsConfigService: ObservableObject {
    @Published var agents: [TeamAgent] = []
    @Published var connectionStatus: ConnectionStatus = .notConnected

    // AppDelegate에서 주입
    weak var bookmarkService: BookmarkService?

    private var fileMonitorSource: DispatchSourceFileSystemObject?
    private var fileDescriptor: Int32 = -1
    private var debounceTask: Task<Void, Never>?

    // agents.json 로드
    func loadAgents() async {
        guard let bookmark = bookmarkService, let projectURL = bookmark.projectURL else {
            connectionStatus = .notConnected
            return
        }

        let agentsURL = projectURL.appendingPathComponent("team/agents.json")

        guard FileManager.default.fileExists(atPath: agentsURL.path) else {
            connectionStatus = .notConnected
            stopFileMonitor()
            return
        }

        do {
            let data = try Data(contentsOf: agentsURL)
            let config = try JSONDecoder().decode(TeamConfiguration.self, from: data)
            agents = buildTeamAgents(from: config)
            connectionStatus = .connected
            startFileMonitor(url: agentsURL)
        } catch {
            connectionStatus = .error(error.localizedDescription)
        }
    }

    // 특정 경로로 로드 (SetupView 미리보기용)
    func previewAgents(from projectPath: String) async -> [TeamAgent]? {
        let agentsPath = (projectPath as NSString).appendingPathComponent("team/agents.json")

        guard FileManager.default.fileExists(atPath: agentsPath),
              let data = try? Data(contentsOf: URL(fileURLWithPath: agentsPath)),
              let config = try? JSONDecoder().decode(TeamConfiguration.self, from: data) else {
            return nil
        }

        return buildTeamAgents(from: config)
    }

    // 에이전트 활성 상태 업데이트
    func updateAgentStatus(id: String, isActive: Bool, pid: String?) {
        if let index = agents.firstIndex(where: { $0.id == id }) {
            agents[index].isActive = isActive
            agents[index].pid = pid
        }
    }

    // MARK: - FSEvents 파일 감시

    private func startFileMonitor(url: URL) {
        stopFileMonitor()

        let fd = open(url.path, O_EVTONLY)
        guard fd >= 0 else { return }

        fileDescriptor = fd
        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd,
            eventMask: [.write, .delete, .rename],
            queue: DispatchQueue.global()
        )

        source.setEventHandler { [weak self] in
            self?.handleFileChange()
        }

        source.setCancelHandler { [weak self] in
            if let fd = self?.fileDescriptor, fd >= 0 {
                close(fd)
                self?.fileDescriptor = -1
            }
        }

        source.resume()
        fileMonitorSource = source
    }

    private func handleFileChange() {
        // debounce 0.5초
        debounceTask?.cancel()
        debounceTask = Task {
            try? await Task.sleep(for: .milliseconds(500))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                Task { await self.loadAgents() }
            }
        }
    }

    private func stopFileMonitor() {
        fileMonitorSource?.cancel()
        fileMonitorSource = nil
    }

    // 연결 해제
    func disconnect() {
        stopFileMonitor()
        agents = []
        connectionStatus = .notConnected
        bookmarkService?.clearBookmark()
    }
}
