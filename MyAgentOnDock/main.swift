import AppKit

// NSApplication 직접 실행 (@main 대신 수동 진입점)
// AppDelegate가 @MainActor이므로 MainActor.assumeIsolated로 초기화
let app = NSApplication.shared
let delegate = MainActor.assumeIsolated { AppDelegate() }
app.delegate = delegate
app.run()
