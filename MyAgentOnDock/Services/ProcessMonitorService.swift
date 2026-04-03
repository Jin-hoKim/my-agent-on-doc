import Foundation
import AppKit

// Claude CLI 프로세스 감지 서비스
// App Sandbox 환경에서는 Process() 실행이 제한될 수 있어 sysctl 기반으로 구현
@MainActor
class ProcessMonitorService: ObservableObject {
    weak var agentsConfigService: AgentsConfigService?

    private var timer: Timer?
    private let pollingInterval: TimeInterval = 3.0

    func startMonitoring() {
        stopMonitoring()
        timer = Timer.scheduledTimer(withTimeInterval: pollingInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.pollProcesses()
            }
        }
        // 즉시 한 번 실행
        Task { await pollProcesses() }
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }

    // 프로세스 목록 폴링
    private func pollProcesses() async {
        guard let configService = agentsConfigService,
              !configService.agents.isEmpty else { return }

        // App Sandbox에서 NSWorkspace.runningApplications는 앱만 감지 (claude CLI X)
        // Process()를 통한 ps 실행 시도 (개발 빌드/Sandbox 외부 실행 시 동작)
        let runningRoles = await detectClaudeProcesses()

        for agent in configService.agents {
            let isActive = runningRoles[agent.id] != nil
            let pid = runningRoles[agent.id]
            configService.updateAgentStatus(id: agent.id, isActive: isActive, pid: pid)
        }
    }

    // Claude CLI 프로세스 감지 (ps aux 파싱)
    // App Sandbox에서는 entitlement 없이 동작하지 않을 수 있음
    // → 실패 시 빈 딕셔너리 반환 (UI는 idle 상태로 표시)
    private func detectClaudeProcesses() async -> [String: String] {
        var result: [String: String] = [:]

        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .background).async {
                let process = Process()
                process.executableURL = URL(fileURLWithPath: "/bin/ps")
                process.arguments = ["aux"]

                let pipe = Pipe()
                process.standardOutput = pipe
                process.standardError = Pipe()

                do {
                    try process.launch()
                    let data = pipe.fileHandleForReading.readDataToEndOfFile()
                    process.waitUntilExit()

                    if let output = String(data: data, encoding: .utf8) {
                        result = self.parseProcessOutput(output)
                    }
                } catch {
                    // Sandbox 환경에서는 실패 — 조용히 빈 딕셔너리 반환
                }

                continuation.resume(returning: result)
            }
        }

        return result
    }

    // ps aux 출력에서 claude 프로세스 파싱
    // team/run.sh 실행 형식: ./team/run.sh <role> <project>
    // 또는 claude --role <role> 형식
    private func parseProcessOutput(_ output: String) -> [String: String] {
        var result: [String: String] = [:]
        let lines = output.components(separatedBy: "\n")

        for line in lines {
            // claude 또는 claude-code 프로세스만 처리
            guard line.contains("claude") || line.contains("team/run.sh") else { continue }

            let parts = line.split(separator: " ", omittingEmptySubsequences: true)
            guard parts.count > 1 else { continue }

            let pid = String(parts[1])

            // 역할명 추출: --role <role> 또는 run.sh <role> 패턴
            if let roleIdx = parts.firstIndex(where: { $0 == "--role" || $0 == "run.sh" }),
               roleIdx + 1 < parts.count {
                let role = String(parts[roleIdx + 1])
                result[role] = pid
            }
        }

        return result
    }
}
