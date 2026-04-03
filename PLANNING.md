# My Agent on Dock - 기획서

## 프로젝트 개요

macOS Dock 위에 AI 에이전트 캐릭터를 표시하는 Solo 모드 앱. 사용자의 Claude API 키로 작동하며, 캐릭터를 클릭하면 프롬프트 창이 열려 Claude와 대화할 수 있다.

## 핵심 기능

### 1. Dock 위 캐릭터 표시
- 에이전트 캐릭터 1개가 Dock 위에 상시 표시
- 상태에 따라 애니메이션 변화 (대기/생각 중/응답 중/에러)
- 캐릭터 클릭 시 프롬프트 창 열림

### 2. 프롬프트 창 (대화)
- 캐릭터 클릭으로 열고 닫기
- Claude API를 통한 실시간 대화
- 대화 기록 유지, 초기화 가능

### 3. 설정
- **API 키**: Claude API 키 입력/저장
- **캐릭터 선택**: 개발자, 로봇, 고양이, 펭귄, 우주인, 닌자
- **캐릭터 크기**: 40pt ~ 120pt 슬라이더
- **음성 선택**: 없음, 남성, 여성, 로봇 (향후 TTS 연동)
- **Claude 모델**: Haiku 4.5 / Sonnet 4.6 / Opus 4.6

### 4. 메뉴바
- 시스템 트레이 아이콘으로 상시 접근
- API 연결 상태 표시
- 에이전트 상태 표시
- 설정/종료 접근

## 기술 스택
- Swift 5.9+ / SwiftUI / AppKit (NSPanel)
- Lottie (향후 애니메이션용)
- Claude API (Messages API v1)
- macOS 14.0 (Sonoma)+

## 구현 상태

### Phase 1: 프로젝트 구조 및 모델 ✅
- [x] Package.swift, Info.plist
- [x] CharacterType, AgentState, ClaudeModel, VoiceType, ChatMessage 모델
- [x] 빌드 성공

### Phase 2: 서비스 레이어 ✅
- [x] AppSettings (UserDefaults 기반 설정 관리)
- [x] ClaudeAPIService (API 호출, 대화 관리)
- [x] PanelManager (Dock 위 패널 위치 관리)

### Phase 3: UI 뷰 ✅
- [x] DockCharacterView (Dock 위 캐릭터)
- [x] PromptWindowView (대화 창)
- [x] SettingsView (설정 창)
- [x] MenuBarView (메뉴바 드롭다운)

### Phase 4: 앱 통합 ✅
- [x] MyAgentOnDockApp (메인 앱)
- [x] AppDelegate (생명주기 관리)
- [x] 전체 빌드 성공

### Phase 5: 향후 개선 (예정)
- [ ] Lottie 애니메이션 적용
- [ ] TTS 음성 출력 연동
- [ ] 스트리밍 응답 (SSE)
- [ ] 대화 기록 로컬 저장
- [ ] 앱스토어 배포
