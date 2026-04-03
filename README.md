# My Agent on Dock

macOS Dock 위에 AI 에이전트 캐릭터를 표시하는 앱. **Solo 모드**(Claude API 직접 대화)와 **Team 모드**(Claude Code 팀 에이전트 상태 표시)를 지원.

## 주요 기능

### Solo 모드
- **Dock 위 캐릭터**: AI 에이전트 캐릭터가 Dock 위에 상시 표시
- **프롬프트 대화**: 캐릭터 클릭 → 대화 창 → Claude와 채팅 (SSE 스트리밍)
- **대화 기록**: 로컬 저장, 최근 5개 메뉴바 바로가기
- **캐릭터 커스터마이징**: 6종 캐릭터, 크기 조절
- **모델 선택**: Haiku / Sonnet / Opus
- **TTS 음성**: 응답 읽어주기 (남성/여성/로봇)

### Team 모드
- **agents.json 자동 감지**: `team/agents.json` 파일을 읽어 팀 구성 자동 인식
- **멀티 캐릭터 표시**: 역할 수만큼 캐릭터를 Dock 위에 동적 배치
- **역할별 이모지**: leader📋 / frontend⌨️ / backend💻 / database🗄️ / designer🎨 / qa🔍 / devops🔧
- **에이전트 상태**: 실행 중인 Claude CLI 프로세스와 매칭 (활성/대기 표시)
- **파일 감시**: agents.json 변경 시 FSEvents로 자동 리로드
- **Security-Scoped Bookmark**: App Sandbox 환경에서 폴더 접근 권한 영구 유지

## 요구사항

- macOS 14.0 (Sonoma) 이상
- **Solo 모드**: Claude API 키 ([anthropic.com](https://console.anthropic.com)에서 발급)
- **Team 모드**: Claude Code CLI 팀 프로젝트 (agents.json 포함)

## 빌드 및 실행

```bash
# 빌드
swift build

# 실행
swift run MyAgentOnDock

# 릴리즈 빌드
swift build -c release
```

## Team 모드 설정

### 1. agents.json 형식

프로젝트 루트의 `team/agents.json`:

```json
{
  "leader": {
    "model": "opus",
    "description": "PM 재혁 — 요구사항 분석, 팀원 배정",
    "prompt": "당신은 PM입니다..."
  },
  "frontend": {
    "model": "sonnet",
    "description": "프론트엔드 개발자 민지 — Vue 3 전문",
    "prompt": "..."
  }
}
```

### 2. 앱에서 연결

메뉴바 아이콘(✦) → **팀 프로젝트 연결** → 프로젝트 폴더 선택 → 팀 연결

## Solo 모드 설정

앱 실행 후 메뉴바 아이콘(✦) → 설정에서:

1. **API 키** 입력
2. **캐릭터** 선택 (개발자/로봇/고양이/펭귄/우주인/닌자)
3. **캐릭터 크기** 조절 (40pt ~ 120pt)
4. **Claude 모델** 선택
5. **음성** 선택 (TTS 지원)

## 기술 스택

- Swift 5.9+ / SwiftUI / AppKit (NSPanel, NSStatusItem, NSPopover)
- Claude Messages API (SSE 스트리밍)
- Security-Scoped Bookmarks (App Sandbox 파일 접근)
- FSEvents (agents.json 실시간 감시)
- AVSpeechSynthesizer (TTS)
- Lottie (애니메이션)

## GitHub

https://github.com/Jin-hoKim/my-agent-on-doc
