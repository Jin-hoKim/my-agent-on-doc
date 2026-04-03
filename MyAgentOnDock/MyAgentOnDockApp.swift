import SwiftUI

// 메인 앱 구조체
struct MyAgentOnDockApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        MenuBarExtra {
            MenuBarContentView()
        } label: {
            Image(systemName: "sparkle")
        }
        .menuBarExtraStyle(.window)
    }
}

// 메뉴바 콘텐츠 래퍼
struct MenuBarContentView: View {
    var body: some View {
        MenuBarView()
    }
}
