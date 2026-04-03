# 변경 이력

## 2026-04-03 - 메뉴바 팝오버 안열림 버그 수정

### 수정 파일
- `MyAgentOnDock/AppDelegate.swift`
  - `togglePopover` 메서드: `NSApp.activate(ignoringOtherApps: true)` 호출 순서를 `pop.show()` 이전으로 변경 (이전: show→activate로 `.transient` behavior가 즉시 닫아버림)
  - `NSPopover.behavior`: `.transient` → `.applicationDefined` (앱이 활성화되어도 팝오버 유지)
  - 버튼 action: `#selector(togglePopover)` → `#selector(togglePopover(_:))` (sender 파라미터 일치)
  - `button.sendAction(on: [.leftMouseUp])` 추가 (마우스업 이벤트로 정확히 트리거)

### 빌드 결과
경고 0, 에러 0, Build complete

---

## 2026-04-03 - 캐릭터 표정 다양화 (20가지 감정 상태)

### 수정 파일
- `MyAgentOnDock/Models/AgentState.swift` — 기존 5가지 상태에서 20가지 감정 상태로 확장
  - 추가: voiceMode, excited, angry, winking, surprised, loading, pleased, sad, laughing, snoozing, neutral, outOfService, lowBattery, crazy, heartEyes, newMessage, unknown
  - `autoRevertDelay` 프로퍼티 추가: 감정 표현 후 자동 idle 복귀 시간
- `MyAgentOnDock/Models/CharacterType.swift` — 20가지 상태 × 6 캐릭터 이모지 매핑
  - 기존 단순 프로퍼티 → `emoji(for state: AgentState) -> String` 메서드로 일원화
  - 캐릭터별 특성 반영: 고양이는 😺😸😾🙀😻😹😿 등 고양이 이모지 활용
  - 로봇은 ⚙️🖥️🔊💤🔴 등 기계적 이모지 활용
  - 우주인은 🔭🛰️📡🚀🌌 등 우주 이모지 활용
- `MyAgentOnDock/Views/DockCharacterView.swift` — 감정 상태별 비주얼 완전 리디자인
  - 배경 그래디언트: 긍정(초록/노랑), 부정(빨강/파랑), 중립(회색) 등 감정별 색상
  - 그림자 색상/크기 감정별 차별화
  - 이모지 크기 스케일 감정별 차별화 (excited: 1.2x, outOfService: 0.85x)
  - emotionBadge: voiceMode 음파 인디케이터, newMessage 빨간 점, snoozing 💤, lowBattery ⚠️
  - 상태 텍스트 색상 감정별 차별화 (긍정: green, 부정: red, 특별: purple 등)
- `MyAgentOnDock/Services/ClaudeAPIService.swift` — 상황별 자동 감정 전환 로직
  - 메시지 전송 시: newMessage → thinking → streaming
  - 응답 완료 시: 응답 길이/키워드 분석 → laughing/heartEyes/excited/pleased/winking 자동 결정
  - 에러 종류별: 401→sad, 429→angry→lowBattery, 500→outOfService, 파싱→crazy, 기타→surprised
  - 5분 idle 시 snoozing 자동 전환 (snoozingTask 타이머)
  - TTS 재생 중 voiceMode 상태 유지

### 빌드 결과
경고 0, 에러 0, Build complete

---

## 2026-04-03 - Team 모드 구현 완성 + 메뉴바 팝오버 버그 수정 (최종)

### 수정 파일 (이번 세션)
- `MyAgentOnDock/AppDelegate.swift` — @MainActor 클래스, NSStatusItem+NSPopover 메뉴바, Team/Solo 패널 전환, 창 관리 일원화
- `MyAgentOnDock/Views/MenuBarView.swift` — Team/Solo 모드 통합 뷰, 팀 에이전트 상태 목록, 팀 설정 버튼 추가

### 버그 수정 (최종)
- MenuBarExtra(.window) + .accessory 정책 충돌로 메뉴창 미표시 문제 완전 해결
  → NSStatusItem + NSPopover(.transient) 직접 구현 (AppDelegate에서 직접 관리)
- AppDelegate 서비스 초기화를 applicationDidFinishLaunching으로 이동하여 @MainActor 충돌 방지

---

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
