# 변경 이력

## 2026-04-03 - 프로젝트 초기 생성

### 신규 파일
- `Package.swift` — SPM 프로젝트 정의 (Lottie 의존성)
- `MyAgentOnDock/main.swift` — 앱 진입점
- `MyAgentOnDock/MyAgentOnDockApp.swift` — SwiftUI 앱 구조체, 메뉴바 설정
- `MyAgentOnDock/AppDelegate.swift` — 앱 생명주기, 패널/창 관리
- `MyAgentOnDock/Info.plist` — 앱 설정 (LSUIElement, 네트워크)
- `MyAgentOnDock/Models/CharacterType.swift` — 6종 캐릭터 타입 (개발자/로봇/고양이/펭귄/우주인/닌자)
- `MyAgentOnDock/Models/AgentState.swift` — 에이전트 상태 (대기/생각/응답/에러)
- `MyAgentOnDock/Models/ClaudeModel.swift` — Claude 모델 선택 (Haiku/Sonnet/Opus)
- `MyAgentOnDock/Models/VoiceType.swift` — 음성 타입 (향후 TTS용)
- `MyAgentOnDock/Models/ChatMessage.swift` — 채팅 메시지 모델
- `MyAgentOnDock/Services/AppSettings.swift` — UserDefaults 기반 설정 관리
- `MyAgentOnDock/Services/ClaudeAPIService.swift` — Claude API 호출 서비스
- `MyAgentOnDock/Services/PanelManager.swift` — Dock 위 NSPanel 관리
- `MyAgentOnDock/Views/DockCharacterView.swift` — Dock 위 캐릭터 뷰
- `MyAgentOnDock/Views/PromptWindowView.swift` — 프롬프트 대화 창
- `MyAgentOnDock/Views/SettingsView.swift` — 설정 창
- `MyAgentOnDock/Views/MenuBarView.swift` — 메뉴바 드롭다운

### 변경 사유
- Solo 모드 macOS 앱 신규 프로젝트 생성
- 사용자 Claude API 키로 1개 에이전트 운영
- 캐릭터 클릭 → 프롬프트 대화 구조
