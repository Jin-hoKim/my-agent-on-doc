# Change History

## 2026-04-04 — App Store Submission & Documentation

### New Files
- `MyAgentOnDock/Resources/AppIcon.icns` — Generated ICNS icon with all required sizes (16–512@2x) using iconutil
- `docs/privacy-policy.html` — English privacy policy page (GitHub Pages)
- `docs/privacy-policy-ko.html` — Korean privacy policy page
- `README-ko.md` — Korean README

### Modified Files
- `MyAgentOnDock/Info.plist` — Added `CFBundleIconFile` (AppIcon) and `ITSAppUsesNonExemptEncryption` (NO)
- `Dockling.xcodeproj/project.pbxproj` — Added AppIcon.icns file reference and resource build phase
- `README.md` — Rewritten in English with full app description, App Store link, features, setup guide

### Changes
- Fixed App Store upload validation error: "Missing required icon in ICNS format containing 512pt x 512pt @2x"
- Created privacy policy pages hosted on GitHub Pages for App Store compliance
- Submitted to App Store review ($3.99, Utilities category, 4+ age rating)

---

## 2026-04-03 — Team Mode Code Separation (Solo-only Cleanup)

### Deleted Files (Team mode → moved to my-agents-on-dock project)
- `MyAgentOnDock/Models/AgentRole.swift`
- `MyAgentOnDock/Models/TeamAgent.swift`
- `MyAgentOnDock/Models/TeamConfiguration.swift`
- `MyAgentOnDock/Services/AgentsConfigService.swift`
- `MyAgentOnDock/Services/BookmarkService.swift`
- `MyAgentOnDock/Services/ProcessMonitorService.swift`
- `MyAgentOnDock/Services/TeamPanelManager.swift`
- `MyAgentOnDock/Views/AgentCharacterView.swift`
- `MyAgentOnDock/Views/SetupView.swift`
- `MyAgentOnDock/Views/TeamDockView.swift`

### Modified Files
- `MyAgentOnDock/AppDelegate.swift` — Removed Team mode panels/services/observers, restored to Solo-only
- `MyAgentOnDock/Views/MenuBarView.swift` — Removed team status section and team settings menu
- `README.md` — Removed Team mode documentation

### Reason
- Separated Solo mode (my-agent-on-dock) and Team mode (my-agents-on-dock) into independent projects
- Team mode developed independently at https://github.com/Jin-hoKim/my-agents-on-doc

---

## 2026-04-03 — Menu Bar Popover Bug Fix

### Modified Files
- `MyAgentOnDock/AppDelegate.swift`
  - `togglePopover`: Moved `NSApp.activate(ignoringOtherApps: true)` before `pop.show()` (previously show→activate caused `.transient` behavior to dismiss immediately)
  - `NSPopover.behavior`: Changed from `.transient` to `.applicationDefined` (popover persists when app activates)
  - Button action: `#selector(togglePopover)` → `#selector(togglePopover(_:))` (sender parameter match)
  - Added `button.sendAction(on: [.leftMouseUp])` (trigger on mouse-up event)

### Build Result
0 warnings, 0 errors, Build complete

---

## 2026-04-03 — Character Expression Diversification (20 Emotion States)

### Modified Files
- `MyAgentOnDock/Models/AgentState.swift` — Expanded from 5 states to 20 emotion states
  - Added: voiceMode, excited, angry, winking, surprised, loading, pleased, sad, laughing, snoozing, neutral, outOfService, lowBattery, crazy, heartEyes, newMessage, unknown
  - Added `autoRevertDelay` property: auto-revert to idle after emotion expression
- `MyAgentOnDock/Models/CharacterType.swift` — 20 states × 6 characters emoji mapping
  - Unified to `emoji(for state: AgentState) -> String` method
  - Character-specific traits: cat uses cat emojis (😺😸😾🙀😻😹😿), robot uses mechanical (⚙️🖥️🔊💤🔴), astronaut uses space (🔭🛰️📡🚀🌌)
- `MyAgentOnDock/Views/DockCharacterView.swift` — Complete visual redesign per emotion state
  - Background gradients: positive (green/yellow), negative (red/blue), neutral (gray)
  - Shadow color/size differentiated by emotion
  - Emoji scale per emotion (excited: 1.2x, outOfService: 0.85x)
  - emotionBadge: voiceMode wave indicator, newMessage red dot, snoozing 💤, lowBattery ⚠️
- `MyAgentOnDock/Services/ClaudeAPIService.swift` — Context-aware automatic emotion transitions
  - On send: newMessage → thinking → streaming
  - On response: analyze length/keywords → laughing/heartEyes/excited/pleased/winking
  - Per error type: 401→sad, 429→angry→lowBattery, 500→outOfService, parse→crazy, other→surprised
  - 5-minute idle → snoozing auto-transition (snoozingTask timer)

### Build Result
0 warnings, 0 errors, Build complete

---

## 2026-04-03 — Phase 5 Feature Completion (SSE Streaming, Chat History, TTS)

### New Files
- `MyAgentOnDock/Models/Conversation.swift` — Conversation session model (Codable, Identifiable)
- `MyAgentOnDock/Services/ChatHistoryService.swift` — Application Support JSON save/load, CRUD
- `MyAgentOnDock/Services/TTSService.swift` — AVSpeechSynthesizer TTS service

### Modified Files
- `MyAgentOnDock/Models/AgentState.swift` — Added `.streaming` case
- `MyAgentOnDock/Models/ChatMessage.swift` — Added Codable conformance
- `MyAgentOnDock/Models/ClaudeModel.swift` — Updated to latest model IDs (claude-sonnet-4-6, claude-opus-4-6)
- `MyAgentOnDock/Models/VoiceType.swift` — AVSpeechSynthesizer pitch/rate mapping
- `MyAgentOnDock/Services/AppSettings.swift` — Added ttsEnabled, useAnimation settings
- `MyAgentOnDock/Services/ClaudeAPIService.swift` — SSE streaming (`bytes(for:)`), chat history integration, TTS integration
- `MyAgentOnDock/Views/DockCharacterView.swift` — `.streaming` case handling, background gradient update
- `MyAgentOnDock/Views/PromptWindowView.swift` — StreamingBubbleView (cursor animation), ConversationListView, chat history UI
- `MyAgentOnDock/Views/SettingsView.swift` — TTS toggle, voice selection, test button
- `MyAgentOnDock/Views/MenuBarView.swift` — Recent conversations menu section

### Phase 5-5: App Store Preparation
- `MyAgentOnDock/Info.plist` — NSAllowsArbitraryLoads=false, api.anthropic.com domain exception, displayName/minOS/copyright
- `MyAgentOnDock/MyAgentOnDock.entitlements` — App Sandbox (com.apple.security.app-sandbox=true), network client entitlement
- `PRIVACY_POLICY.md` — Privacy policy (local storage, Anthropic API only, no analytics/tracking)

### Reason
- Phase 5-1: SSE streaming for token-by-token real-time response display (UX improvement)
- Phase 5-2: Chat history JSON persistence → restore on app restart, 5 recent conversations in menu bar
- Phase 5-3: TTS toggle, voice selection (male/female/robot), test play button in SettingsView
- Phase 5-4: AVSpeechSynthesizer TTS — 3 voice types (male/female/robot)
- Phase 5-5: App Store submission requirements (Sandbox, network client, privacy policy)

---

## 2026-04-03 — Initial Project Creation

### New Files
- `Package.swift` — SPM project definition (Lottie dependency)
- `MyAgentOnDock/main.swift` — App entry point
- `MyAgentOnDock/MyAgentOnDockApp.swift` — SwiftUI app structure, menu bar setup
- `MyAgentOnDock/AppDelegate.swift` — App lifecycle, panel/window management
- `MyAgentOnDock/Info.plist` — App configuration (LSUIElement, networking)
- `MyAgentOnDock/Models/CharacterType.swift` — 6 character types (Developer/Robot/Cat/Penguin/Astronaut/Ninja)
- `MyAgentOnDock/Models/AgentState.swift` — Agent states (idle/thinking/responding/error)
- `MyAgentOnDock/Models/ClaudeModel.swift` — Claude model selection (Haiku/Sonnet/Opus)
- `MyAgentOnDock/Models/VoiceType.swift` — Voice types (for TTS)
- `MyAgentOnDock/Models/ChatMessage.swift` — Chat message model
- `MyAgentOnDock/Services/AppSettings.swift` — UserDefaults-based settings management
- `MyAgentOnDock/Services/ClaudeAPIService.swift` — Claude API service
- `MyAgentOnDock/Services/PanelManager.swift` — Dock panel management (NSPanel)
- `MyAgentOnDock/Views/DockCharacterView.swift` — Character view above Dock
- `MyAgentOnDock/Views/PromptWindowView.swift` — Prompt chat window
- `MyAgentOnDock/Views/SettingsView.swift` — Settings panel
- `MyAgentOnDock/Views/MenuBarView.swift` — Menu bar dropdown

### Reason
- New Solo-mode macOS app project
- Single agent powered by user's Claude API key
- Character click → prompt chat interaction
