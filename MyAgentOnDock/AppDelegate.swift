import AppKit
import SwiftUI

// 앱 생명주기 관리
class AppDelegate: NSObject, NSApplicationDelegate {
    private var dockPanel: AgentDockPanel?
    private var promptWindow: NSWindow?
    private var settingsWindow: NSWindow?
    private var promptObserver: NSObjectProtocol?
    private var settingsObserver: NSObjectProtocol?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Dock 아이콘 숨기기
        NSApp.setActivationPolicy(.accessory)

        // Dock 위 캐릭터 패널 생성
        Task { @MainActor in
            let panel = AgentDockPanel()
            self.dockPanel = panel

            if AppSettings.shared.isPanelVisible {
                panel.orderFront(nil)
            }
        }

        // 프롬프트 창 토글 이벤트 감지
        promptObserver = NotificationCenter.default.addObserver(
            forName: .togglePromptWindow,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.togglePromptWindow()
        }

        // 설정 창 열기 이벤트 감지
        settingsObserver = NotificationCenter.default.addObserver(
            forName: .openSettings,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.openSettingsWindow()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        dockPanel?.close()
        promptWindow?.close()
        settingsWindow?.close()
        if let observer = promptObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        if let observer = settingsObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    // 프롬프트 창 토글
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
        self.promptWindow = window
    }

    // 설정 창 열기
    private func openSettingsWindow() {
        if let window = settingsWindow, window.isVisible {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 580),
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
        self.settingsWindow = window
    }
}
