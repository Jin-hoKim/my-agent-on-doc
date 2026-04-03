import AppKit
import SwiftUI

// 앱 생명주기 관리 (@MainActor — 모든 UI 작업 메인 스레드)
@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    // Solo 모드 패널
    private var dockPanel: AgentDockPanel?
    // Team 모드 패널
    private var teamPanel: TeamDockPanel?

    // 창 관리
    private var promptWindow: NSWindow?
    private var settingsWindow: NSWindow?
    private var setupWindow: NSWindow?

    // 알림 옵저버
    private var observers: [NSObjectProtocol] = []

    // 메뉴바 (NSStatusItem + NSPopover)
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?

    // 서비스
    let bookmarkService = BookmarkService()
    let agentsConfigService: AgentsConfigService
    let processMonitorService: ProcessMonitorService

    override init() {
        agentsConfigService = AgentsConfigService()
        processMonitorService = ProcessMonitorService()
        super.init()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Dock 아이콘 숨기기
        NSApp.setActivationPolicy(.accessory)

        // 서비스 체인 연결
        agentsConfigService.bookmarkService = bookmarkService
        processMonitorService.agentsConfigService = agentsConfigService

        // 메뉴바 아이콘 + 팝오버 설정
        setupStatusItem()

        // 앱 시작: bookmark 복원 → 팀 또는 Solo 패널
        Task {
            let restored = bookmarkService.restoreBookmark()
            if restored {
                await agentsConfigService.loadAgents()
                if agentsConfigService.connectionStatus == .connected {
                    showTeamPanel()
                } else {
                    showSoloPanel()
                }
            } else {
                showSoloPanel()
            }
        }

        // 이벤트 옵저버 등록
        registerObservers()
    }

    func applicationWillTerminate(_ notification: Notification) {
        dockPanel?.close()
        teamPanel?.close()
        promptWindow?.close()
        settingsWindow?.close()
        setupWindow?.close()
        bookmarkService.stopAccessing()
        processMonitorService.stopMonitoring()
        observers.forEach { NotificationCenter.default.removeObserver($0) }
    }

    // MARK: - 알림 등록

    private func registerObservers() {
        let pairs: [(Notification.Name, @MainActor () -> Void)] = [
            (.togglePromptWindow, { [weak self] in self?.togglePromptWindow() }),
            (.openSettings,        { [weak self] in self?.openSettingsWindow() }),
            (.openSetup,           { [weak self] in self?.openSetupWindow() }),
            (.teamModeActivated,   { [weak self] in self?.switchToTeamMode() })
        ]

        observers = pairs.map { (name, handler) in
            NotificationCenter.default.addObserver(forName: name, object: nil, queue: .main) { _ in
                Task { @MainActor in handler() }
            }
        }
    }

    // MARK: - 메뉴바 설정

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "sparkle", accessibilityDescription: "My Agent on Dock")
            button.action = #selector(togglePopover)
            button.target = self
        }

        let pop = NSPopover()
        pop.contentSize = NSSize(width: 280, height: 380)
        pop.behavior = .transient
        pop.animates = true
        pop.contentViewController = NSHostingController(
            rootView: MenuBarView()
                .environmentObject(agentsConfigService)
        )
        popover = pop
    }

    @objc func togglePopover() {
        guard let button = statusItem?.button, let pop = popover else { return }

        if pop.isShown {
            pop.performClose(nil)
        } else {
            pop.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    // MARK: - 패널 전환

    private func showSoloPanel() {
        teamPanel?.close()
        teamPanel = nil

        let panel = AgentDockPanel()
        dockPanel = panel
        if AppSettings.shared.isPanelVisible {
            panel.orderFront(nil)
        }
    }

    private func showTeamPanel() {
        dockPanel?.close()
        dockPanel = nil

        let panel = TeamDockPanel(agentsConfigService: agentsConfigService)
        teamPanel = panel
        panel.orderFront(nil)
        processMonitorService.startMonitoring()
    }

    private func switchToTeamMode() {
        showTeamPanel()
        popover?.performClose(nil)
    }

    // MARK: - 창 관리

    private func togglePromptWindow() {
        if let window = promptWindow, window.isVisible {
            window.close()
            return
        }

        let window = makeWindow(
            size: NSRect(x: 0, y: 0, width: 480, height: 560),
            title: "My Agent",
            style: [.titled, .closable, .resizable, .miniaturizable]
        )
        window.contentView = NSHostingView(rootView: PromptWindowView())
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        promptWindow = window
    }

    private func openSettingsWindow() {
        if let window = settingsWindow, window.isVisible {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let window = makeWindow(
            size: NSRect(x: 0, y: 0, width: 400, height: 640),
            title: "설정",
            style: [.titled, .closable]
        )
        window.contentView = NSHostingView(rootView: SettingsView())
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        settingsWindow = window
    }

    private func openSetupWindow() {
        if let window = setupWindow, window.isVisible {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let window = makeWindow(
            size: NSRect(x: 0, y: 0, width: 520, height: 600),
            title: "팀 프로젝트 연결",
            style: [.titled, .closable]
        )
        window.contentView = NSHostingView(
            rootView: SetupView()
                .environmentObject(agentsConfigService)
                .environmentObject(bookmarkService)
        )
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        setupWindow = window
    }

    private func makeWindow(size: NSRect, title: String, style: NSWindow.StyleMask) -> NSWindow {
        let window = NSWindow(
            contentRect: size,
            styleMask: style,
            backing: .buffered,
            defer: false
        )
        window.title = title
        window.center()
        window.isReleasedWhenClosed = false
        return window
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let openSetup = Notification.Name("openSetup")
    static let teamModeActivated = Notification.Name("teamModeActivated")
}
