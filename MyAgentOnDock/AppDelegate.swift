import AppKit
import SwiftUI

// 앱 생명주기 관리
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
    private var promptObserver: NSObjectProtocol?
    private var settingsObserver: NSObjectProtocol?
    private var setupObserver: NSObjectProtocol?
    private var teamModeObserver: NSObjectProtocol?

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

        // 메뉴바 아이콘 + 팝오버 설정
        setupStatusItem()

        // 서비스 초기화 체인
        agentsConfigService.bookmarkService = bookmarkService
        processMonitorService.agentsConfigService = agentsConfigService

        // 앱 시작: bookmark 복원 시도
        Task { @MainActor in
            let restored = bookmarkService.restoreBookmark()
            if restored {
                // agents.json 자동 로드
                await agentsConfigService.loadAgents()
                if agentsConfigService.connectionStatus == .connected {
                    showTeamPanel()
                } else {
                    showSoloPanel()
                }
            } else {
                // bookmark 없음 → Solo 모드로 시작
                showSoloPanel()
            }
        }

        // 이벤트 옵저버 등록
        promptObserver = NotificationCenter.default.addObserver(
            forName: .togglePromptWindow,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.togglePromptWindow() }
        }

        settingsObserver = NotificationCenter.default.addObserver(
            forName: .openSettings,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.openSettingsWindow() }
        }

        setupObserver = NotificationCenter.default.addObserver(
            forName: .openSetup,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.openSetupWindow() }
        }

        teamModeObserver = NotificationCenter.default.addObserver(
            forName: .teamModeActivated,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.switchToTeamMode() }
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        dockPanel?.close()
        teamPanel?.close()
        promptWindow?.close()
        settingsWindow?.close()
        setupWindow?.close()
        bookmarkService.stopAccessing()
        processMonitorService.stopMonitoring()
        [promptObserver, settingsObserver, setupObserver, teamModeObserver].compactMap { $0 }.forEach {
            NotificationCenter.default.removeObserver($0)
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
        pop.contentSize = NSSize(width: 280, height: 360)
        pop.behavior = .transient
        pop.animates = true
        pop.contentViewController = NSHostingController(
            rootView: MenuBarView()
                .environmentObject(agentsConfigService)
        )
        popover = pop
    }

    @objc private func togglePopover() {
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

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 560),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "My Agent"
        window.contentView = NSHostingView(rootView: PromptWindowView())
        window.center()
        window.isReleasedWhenClosed = false
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

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 640),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "설정"
        window.contentView = NSHostingView(rootView: SettingsView())
        window.center()
        window.isReleasedWhenClosed = false
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

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 600),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "팀 프로젝트 연결"
        window.contentView = NSHostingView(
            rootView: SetupView()
                .environmentObject(agentsConfigService)
                .environmentObject(bookmarkService)
        )
        window.center()
        window.isReleasedWhenClosed = false
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        setupWindow = window
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let openSetup = Notification.Name("openSetup")
    static let teamModeActivated = Notification.Name("teamModeActivated")
}
