import AppKit
import SwiftUI
import Combine

// 멀티 캐릭터 NSPanel — Team 모드 Dock 위 표시
class TeamDockPanel: NSPanel {
    private let agentsConfigService: AgentsConfigService
    private var cancellables = Set<AnyCancellable>()
    private var hostingView: NSView?

    init(agentsConfigService: AgentsConfigService) {
        self.agentsConfigService = agentsConfigService

        let initialSize = TeamDockPanel.panelSize(for: agentsConfigService.agents.count)

        super.init(
            contentRect: NSRect(x: 0, y: 0, width: initialSize.width, height: initialSize.height),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        level = .floating
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        isMovableByWindowBackground = true

        // SwiftUI 뷰 연결
        let dockView = TeamDockView()
            .environmentObject(agentsConfigService)
        let hosting = NSHostingView(rootView: dockView)
        contentView = hosting
        hostingView = hosting

        positionAboveDock()
        setupObservers()
    }

    // 캐릭터 수에 따른 패널 크기 계산
    static func panelSize(for count: Int) -> CGSize {
        let characterSize: CGFloat = AppSettings.shared.characterSize
        let perChar: CGFloat = characterSize + 16  // 캐릭터 너비 + 간격
        let labelHeight: CGFloat = 30
        let padding: CGFloat = 20

        let agentCount = max(count, 1)

        // 최대 화면 너비의 80%
        let screenWidth = NSScreen.main?.frame.width ?? 1440
        let maxWidth = screenWidth * 0.8

        let rawWidth = perChar * CGFloat(agentCount) + padding
        let finalWidth = min(rawWidth, maxWidth)
        let finalHeight = characterSize + labelHeight + padding

        return CGSize(width: finalWidth, height: finalHeight)
    }

    private func setupObservers() {
        // 화면 변경 감지
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenChanged),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )

        // 에이전트 수 변경 시 패널 크기 재계산
        agentsConfigService.$agents
            .receive(on: DispatchQueue.main)
            .sink { [weak self] agents in
                self?.updatePanelSize(for: agents.count)
            }
            .store(in: &cancellables)
    }

    @objc private func screenChanged() {
        positionAboveDock()
    }

    private func updatePanelSize(for count: Int) {
        let size = TeamDockPanel.panelSize(for: count)
        setContentSize(size)
        positionAboveDock()
    }

    // Solo 모드 PanelManager와 동일한 Dock 위치 로직
    func positionAboveDock() {
        guard let screen = NSScreen.main else { return }

        let visibleFrame = screen.visibleFrame
        let fullFrame = screen.frame

        let dockHeight = visibleFrame.origin.y - fullFrame.origin.y
        let dockWidth = fullFrame.width - visibleFrame.width

        let panelFrame = frame

        if dockHeight > 0 {
            // Dock 하단
            let x = (fullFrame.width - panelFrame.width) / 2 + fullFrame.origin.x
            let y = fullFrame.origin.y + dockHeight + 5
            setFrameOrigin(NSPoint(x: x, y: y))
        } else if dockWidth > 0 && visibleFrame.origin.x > fullFrame.origin.x {
            // Dock 왼쪽
            let x = fullFrame.origin.x + dockWidth + 5
            let y = fullFrame.origin.y + 80
            setFrameOrigin(NSPoint(x: x, y: y))
        } else if dockWidth > 0 {
            // Dock 오른쪽
            let x = fullFrame.origin.x + fullFrame.width - dockWidth - panelFrame.width - 5
            let y = fullFrame.origin.y + 80
            setFrameOrigin(NSPoint(x: x, y: y))
        } else {
            // Dock 자동 숨김
            let x = (fullFrame.width - panelFrame.width) / 2 + fullFrame.origin.x
            let y = fullFrame.origin.y + 10
            setFrameOrigin(NSPoint(x: x, y: y))
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
