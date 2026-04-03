# 변경 이력

## 2026-04-03 - Team 모드 구현 + 메뉴바 팝오버 버그 수정

### 신규 파일 (Team 모드)
- `MyAgentOnDock/Models/AgentRole.swift` — 역할별 이모지 매핑 (leader/frontend/backend 등)
- `MyAgentOnDock/Models/TeamAgent.swift` — 팀 에이전트 모델 (id/model/name/emoji/isActive)
- `MyAgentOnDock/Models/TeamConfiguration.swift` — agents.json 구조 + 파싱 함수
- `MyAgentOnDock/Services/AgentsConfigService.swift` — agents.json 파싱/FSEvents 감시
- `MyAgentOnDock/Services/BookmarkService.swift` — Security-Scoped Bookmark 관리
- `MyAgentOnDock/Services/ProcessMonitorService.swift` — Claude CLI 프로세스 감지 (ps aux, 3초 폴링)
- `MyAgentOnDock/Services/TeamPanelManager.swift` — 멀티 캐릭터 NSPanel (동적 너비)
- `MyAgentOnDock/Views/AgentCharacterView.swift` — 개별 에이전트 캐릭터 뷰 (이모지+상태표시)
- `MyAgentOnDock/Views/TeamDockView.swift` — HStack 기반 멀티 캐릭터 Dock 뷰
- `MyAgentOnDock/Views/SetupView.swift` — 프로젝트 폴더 선택 + agents.json 미리보기 + 연결 UI

### 수정 파일
- `MyAgentOnDock/AppDelegate.swift` — @MainActor 추가, NSStatusItem+NSPopover 메뉴바 구현, Team 모드 서비스 체인 초기화
- `MyAgentOnDock/main.swift` — MainActor.assumeIsolated로 @MainActor AppDelegate 초기화
- `MyAgentOnDock/MyAgentOnDockApp.swift` — @main 제거, AppDelegate로 위임

### 버그 수정
- 메뉴바 아이콘 클릭 시 팝오버 미표시 문제: MenuBarExtra(.window) + .accessory 정책 충돌
  → NSStatusItem + NSPopover(.transient) 직접 구현으로 교체

## 2026-04-03 - Phase 5 기능 구현 완료 (SSE 스트리밍, 대화 저장, TTS)

### 신규 파일
- `MyAgentOnDock/Models/Conversation.swift` — 대화 세션 모델 (Codable, Identifiable)
- `MyAgentOnDock/Services/ChatHistoryService.swift` — Application Support JSON 저장/로드, CRUD
- `MyAgentOnDock/Services/TTSService.swift` — AVSpeechSynthesizer TTS 서비스

### 수정 파일
- `MyAgentOnDock/Models/AgentState.swift` — `.streaming` case 추가
- `MyAgentOnDock/Models/ChatMessage.swift` — Codable 추가
- `MyAgentOnDock/Models/ClaudeModel.swift` — 최신 모델 ID 반영 (claude-sonnet-4-6, claude-opus-4-6)
- `MyAgentOnDock/Models/VoiceType.swift` — AVSpeechSynthesizer 피치/속도 매핑
- `MyAgentOnDock/Services/AppSettings.swift` — ttsEnabled, useAnimation 설정 추가
- `MyAgentOnDock/Services/ClaudeAPIService.swift` — SSE 스트리밍(`bytes(for:)`), 대화 저장 연동, TTS 연동
- `MyAgentOnDock/Views/DockCharacterView.swift` — `.streaming` case 처리, 배경 그래디언트 수정
- `MyAgentOnDock/Views/PromptWindowView.swift` — StreamingBubbleView (커서 애니메이션), ConversationListView, 대화 기록 UI
- `MyAgentOnDock/Views/SettingsView.swift` — TTS 활성화 토글, 음성 선택, 테스트 버튼
- `MyAgentOnDock/Views/MenuBarView.swift` — 최근 대화 메뉴 섹션 추가
- `MyAgentOnDock/AppDelegate.swift` — 기존 구조 유지

### Phase 5-5: App Store 배포 준비
- `MyAgentOnDock/Info.plist` — NSAllowsArbitraryLoads=false, api.anthropic.com 도메인 예외 추가, displayName/minOS/copyright 추가
- `MyAgentOnDock/MyAgentOnDock.entitlements` — 신규: App Sandbox (com.apple.security.app-sandbox=true), 네트워크 클라이언트 권한
- `PRIVACY_POLICY.md` — 신규: 개인정보 처리방침 (로컬 저장, Anthropic API만 전송, 분석/추적 없음)

### 변경 사유
- Phase 5-1: SSE 스트리밍으로 토큰 단위 실시간 응답 표시 (UX 개선)
- Phase 5-2: 대화 기록 JSON 저장 → 앱 재시작 시 복원, 최근 대화 5개 메뉴바 표시
- Phase 5-3: TTS 활성화 토글, 음성 선택(남성/여성/로봇), 테스트 재생 버튼 SettingsView 추가
- Phase 5-4: AVSpeechSynthesizer TTS — 남성/여성/로봇 음성 3종 지원
- Phase 5-5: App Store 제출 요건 충족 (Sandbox, 네트워크 클라이언트, 개인정보방침)
- 빌드 에러 수정: DockCharacterView `.streaming` case 누락 → switch 문 보완
- TTSService @unchecked Sendable 추가 (AVSpeechSynthesizer Sendable 경고 제거)

---

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
