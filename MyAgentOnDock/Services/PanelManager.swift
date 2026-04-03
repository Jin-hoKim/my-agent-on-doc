import AppKit
import SwiftUI

// Dock 위 캐릭터 패널 관리
class AgentDockPanel: NSPanel {
    private var defaultsObserver: NSObjectProtocol?

    init() {
        let size = AppSettings.shared.characterSize
        let panelWidth = size + 20
        let panelHeight = size + 30

        super.init(
            contentRect: NSRect(x: 0, y: 0, width: panelWidth, height: panelHeight),
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
        let hostingView = NSHostingView(rootView: DockCharacterView())
        contentView = hostingView

        positionAboveDock()
        setupObservers()
    }

    private func setupObservers() {
        // 화면 변경 감지
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenChanged),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )

        // 패널 표시 토글 감지
        defaultsObserver = NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            let visible = UserDefaults.standard.bool(forKey: "characterPanelVisible")
            if visible {
                self?.orderFront(nil)
            } else {
                self?.orderOut(nil)
            }
        }
    }

    @objc private func screenChanged() {
        positionAboveDock()
    }

    // Dock 위에 패널 위치 조정
    func positionAboveDock() {
        guard let screen = NSScreen.main else { return }

        let visibleFrame = screen.visibleFrame
        let fullFrame = screen.frame

        let dockHeight = visibleFrame.origin.y - fullFrame.origin.y
        let dockWidth = fullFrame.width - visibleFrame.width

        let panelFrame = frame

        if dockHeight > 0 {
            // Dock이 하단에 위치
            let x = (fullFrame.width - panelFrame.width) / 2 + fullFrame.origin.x
            let y = fullFrame.origin.y + dockHeight + 5
            setFrameOrigin(NSPoint(x: x, y: y))
        } else if dockWidth > 0 && visibleFrame.origin.x > fullFrame.origin.x {
            // Dock이 왼쪽에 위치
            let x = fullFrame.origin.x + dockWidth + 5
            let y = fullFrame.origin.y + 80
            setFrameOrigin(NSPoint(x: x, y: y))
        } else if dockWidth > 0 {
            // Dock이 오른쪽에 위치
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

    // 패널 사이즈 업데이트
    func updateSize(_ size: Double) {
        let panelWidth = size + 20
        let panelHeight = size + 30
        setContentSize(NSSize(width: panelWidth, height: panelHeight))
        positionAboveDock()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        if let observer = defaultsObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
}
