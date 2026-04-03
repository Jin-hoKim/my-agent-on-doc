import AppKit
import SwiftUI

// Security-Scoped Bookmark으로 프로젝트 디렉토리 접근 권한 영구 저장
@MainActor
class BookmarkService: ObservableObject {
    private let bookmarkKey = "projectBookmarkData"
    private let pathKey = "projectPath"

    @Published var projectURL: URL? = nil
    @Published var projectPath: String = ""

    private var isAccessing = false

    init() {
        // 앱 시작 시 저장된 bookmark 복원 시도
        _ = restoreBookmark()
    }

    // NSOpenPanel로 프로젝트 폴더 선택
    func selectProjectFolder() -> Bool {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.message = "Claude Code 팀 프로젝트 폴더를 선택하세요"
        panel.prompt = "선택"

        guard panel.runModal() == .OK, let url = panel.url else { return false }

        return saveBookmark(for: url)
    }

    // Security-Scoped Bookmark 저장
    func saveBookmark(for url: URL) -> Bool {
        do {
            let bookmarkData = try url.bookmarkData(
                options: .withSecurityScope,
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
            UserDefaults.standard.set(bookmarkData, forKey: bookmarkKey)
            UserDefaults.standard.set(url.path, forKey: pathKey)
            setProjectURL(url)
            return true
        } catch {
            return false
        }
    }

    // 저장된 Bookmark 복원
    @discardableResult
    func restoreBookmark() -> Bool {
        guard let bookmarkData = UserDefaults.standard.data(forKey: bookmarkKey) else {
            return false
        }

        do {
            var isStale = false
            let url = try URL(
                resolvingBookmarkData: bookmarkData,
                options: .withSecurityScope,
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )

            if isStale {
                // stale bookmark → 재저장
                _ = saveBookmark(for: url)
            }

            setProjectURL(url)
            return true
        } catch {
            clearBookmark()
            return false
        }
    }

    // 접근 시작
    func startAccessing() {
        guard let url = projectURL, !isAccessing else { return }
        isAccessing = url.startAccessingSecurityScopedResource()
    }

    // 접근 종료
    func stopAccessing() {
        guard let url = projectURL, isAccessing else { return }
        url.stopAccessingSecurityScopedResource()
        isAccessing = false
    }

    // Bookmark 초기화
    func clearBookmark() {
        stopAccessing()
        UserDefaults.standard.removeObject(forKey: bookmarkKey)
        UserDefaults.standard.removeObject(forKey: pathKey)
        projectURL = nil
        projectPath = ""
    }

    private func setProjectURL(_ url: URL) {
        stopAccessing()
        projectURL = url
        projectPath = url.path
        startAccessing()
    }
}
