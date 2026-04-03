import AppKit
import SwiftUI

// 앱 생명주기 관리 (@MainActor — 모든 UI 작업 메인 스레드)
@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    private var dockPanel: AgentDockPanel?
    private var promptWindow: NSWindow?
    private var settingsWindow: NSWindow?

    // 메뉴바 (NSStatusItem + NSPopover)
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?

    // 알림 옵저버
    private var observers: [NSObjectProtocol] = []

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Dock 아이콘 숨기기
        NSApp.setActivationPolicy(.accessory)

        // 메뉴바 아이콘 + 팝오버 설정
        setupStatusItem()

        // Solo 모드 패널 표시
        let panel = AgentDockPanel()
        dockPanel = panel
        if AppSettings.shared.isPanelVisible {
            panel.orderFront(nil)
        }

        // 이벤트 옵저버 등록
        registerObservers()
    }

    func applicationWillTerminate(_ notification: Notification) {
        dockPanel?.close()
        promptWindow?.close()
        settingsWindow?.close()
        observers.forEach { NotificationCenter.default.removeObserver($0) }
    }

    // MARK: - 알림 등록

    private func registerObservers() {
        let pairs: [(Notification.Name, @MainActor () -> Void)] = [
            (.togglePromptWindow, { [weak self] in self?.togglePromptWindow() }),
            (.openSettings,       { [weak self] in self?.openSettingsWindow() }),
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
            button.action = #selector(togglePopover(_:))
            button.target = self
            button.sendAction(on: [.leftMouseUp])
        }

        let pop = NSPopover()
        pop.contentSize = NSSize(width: 280, height: 380)
        pop.behavior = .applicationDefined
        pop.animates = true
        pop.contentViewController = NSHostingController(rootView: MenuBarView())
        popover = pop
    }

    @objc func togglePopover(_ sender: AnyObject?) {
        guard let button = statusItem?.button, let pop = popover else { return }

        if pop.isShown {
            pop.performClose(nil)
        } else {
            NSApp.activate(ignoringOtherApps: true)
            pop.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
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
