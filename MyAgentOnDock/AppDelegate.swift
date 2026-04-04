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
    // 패널-프롬프트 창 간 오프셋 (패널 이동 시 추적용)
    private var promptOffset: NSPoint = .zero

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Dock 아이콘 숨기기
        NSApp.setActivationPolicy(.accessory)

        // 표준 Edit 메뉴 추가 (Cmd+C/V/X/A 지원)
        setupMainMenu()

        // 메뉴바 아이콘 + 팝오버 설정
        setupStatusItem()

        // Solo 모드 패널 표시
        let panel = AgentDockPanel()
        dockPanel = panel
        if AppSettings.shared.isPanelVisible {
            panel.orderFront(nil)
        }

        // 시작 사운드 재생
        SoundService.shared.playStartup()

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

        // 패널 이동 시 프롬프트 창 따라가기
        observers.append(
            NotificationCenter.default.addObserver(
                forName: .dockPanelDidMove, object: nil, queue: .main
            ) { [weak self] _ in
                Task { @MainActor in
                    guard let self,
                          let window = self.promptWindow, window.isVisible,
                          let panelFrame = self.dockPanel?.frame else { return }
                    let newX = panelFrame.origin.x + self.promptOffset.x
                    let newY = panelFrame.origin.y + self.promptOffset.y
                    window.setFrameOrigin(NSPoint(x: newX, y: newY))
                }
            }
        )

        // 윈도우 닫힐 때 accessory 모드로 복귀
        observers.append(
            NotificationCenter.default.addObserver(
                forName: NSWindow.willCloseNotification, object: nil, queue: .main
            ) { [weak self] notification in
                Task { @MainActor in
                    guard let self else { return }
                    let closingWindow = notification.object as? NSWindow
                    if closingWindow == self.settingsWindow || closingWindow == self.promptWindow {
                        // 다른 윈도우도 열려있으면 유지
                        let settingsVisible = self.settingsWindow?.isVisible == true && closingWindow != self.settingsWindow
                        let promptVisible = self.promptWindow?.isVisible == true && closingWindow != self.promptWindow
                        if !settingsVisible && !promptVisible {
                            NSApp.setActivationPolicy(.accessory)
                        }
                    }
                }
            }
        )
    }

    // MARK: - 메인 메뉴 (Cmd+C/V/X/A 지원)

    private func setupMainMenu() {
        let mainMenu = NSMenu()

        // App 메뉴
        let appMenu = NSMenu()
        appMenu.addItem(NSMenuItem(title: "Quit Dockling", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        let appMenuItem = NSMenuItem()
        appMenuItem.submenu = appMenu
        mainMenu.addItem(appMenuItem)

        // Edit 메뉴
        let editMenu = NSMenu(title: "Edit")
        editMenu.addItem(NSMenuItem(title: "Undo", action: Selector(("undo:")), keyEquivalent: "z"))
        editMenu.addItem(NSMenuItem(title: "Redo", action: Selector(("redo:")), keyEquivalent: "Z"))
        editMenu.addItem(NSMenuItem.separator())
        editMenu.addItem(NSMenuItem(title: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x"))
        editMenu.addItem(NSMenuItem(title: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c"))
        editMenu.addItem(NSMenuItem(title: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v"))
        editMenu.addItem(NSMenuItem(title: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a"))
        let editMenuItem = NSMenuItem()
        editMenuItem.submenu = editMenu
        mainMenu.addItem(editMenuItem)

        NSApp.mainMenu = mainMenu
    }

    // MARK: - 메뉴바 설정

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "sunglasses.fill", accessibilityDescription: "Dockling")
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

        let windowWidth: CGFloat = 360
        let windowHeight: CGFloat = 480
        let window = KeyablePanel(
            contentRect: NSRect(x: 0, y: 0, width: windowWidth, height: windowHeight),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = true
        window.level = .floating
        window.isMovableByWindowBackground = true
        window.isReleasedWhenClosed = false

        let hostingView = NSHostingView(rootView:
            PromptWindowView(onClose: { [weak self] in
                self?.promptWindow?.close()
            })
            .clipShape(RoundedRectangle(cornerRadius: 16))
        )
        hostingView.layer?.cornerRadius = 16
        hostingView.layer?.masksToBounds = true
        window.contentView = hostingView

        // 캐릭터 패널의 현재 위치 기준으로 바로 위에 배치
        if let panelFrame = dockPanel?.frame {
            let x = panelFrame.midX - windowWidth / 2
            let y = panelFrame.maxY + 4
            window.setFrameOrigin(NSPoint(x: x, y: y))

            // 화면 위로 넘치면 보정
            if let screen = NSScreen.main {
                let screenTop = screen.visibleFrame.maxY
                if y + windowHeight > screenTop {
                    window.setFrameOrigin(NSPoint(x: x, y: screenTop - windowHeight))
                }
            }

            // 현재 오프셋 기록 (패널 이동 추적용)
            promptOffset = NSPoint(
                x: window.frame.origin.x - panelFrame.origin.x,
                y: window.frame.origin.y - panelFrame.origin.y
            )
        } else {
            window.center()
        }

        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)

        promptWindow = window
    }

    private func openSettingsWindow() {
        if let window = settingsWindow, window.isVisible {
            NSApp.activate(ignoringOtherApps: true)
            window.makeKeyAndOrderFront(nil)
            return
        }

        let window = makeWindow(
            size: NSRect(x: 0, y: 0, width: 400, height: 640),
            title: "Settings",
            style: [.titled, .closable]
        )
        window.contentView = NSHostingView(rootView: SettingsView())
        // accessory 앱에서 키보드 입력을 받으려면 활성화 먼저
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
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

// borderless 패널이지만 키 입력을 받을 수 있는 패널
class KeyablePanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}
