# Docklings

macOS Dock 위에 살아 숨 쉬는 AI 컴패니언. Claude로 구동되며, 대화에 따라 실시간으로 감정을 표현하는 애니메이션 로봇 캐릭터가 특징입니다.

<p align="center">
  <img src="https://github.com/Jin-hoKim/my-agent-on-doc/raw/main/docs/screenshots/docklings-hero.png" alt="Docklings" width="600">
</p>

## 주요 기능

- **Dock 위 컴패니언** — 애니메이션 AI 캐릭터가 Dock 위에 상시 대기하며 언제든 대화 가능
- **실시간 대화** — 캐릭터 클릭으로 채팅 창을 열고 Claude와 대화 (SSE 스트리밍)
- **감정 표현 애니메이션** — 6종 캐릭터, 20가지 이상의 Lottie 애니메이션 표정이 대화 맥락에 따라 반응
- **대화 기록** — 로컬 저장, 메뉴바에서 빠른 접근
- **모델 선택** — Claude Haiku, Sonnet, Opus 중 선택
- **음성 읽기(TTS)** — 남성/여성/로봇 등 다양한 음성으로 응답 읽어주기
- **메뉴바 컨트롤** — 상태 확인, 설정, 토글을 메뉴바에서 바로 조작
- **캐릭터 커스터마이징** — 크기 조절(40pt~120pt), 원하는 캐릭터 선택

## 캐릭터

| Nova | Sprout |
|------|--------|
| 테크 감성의 파란색 로봇 | 밝고 활발한 초록색 로봇 |

각 캐릭터는 기쁨, 슬픔, 놀람, 생각, 타이핑, 에러 등 20가지 이상의 표정을 가지고 있습니다.

## 요구사항

- macOS 14.0 (Sonoma) 이상
- Anthropic API 키 ([console.anthropic.com](https://console.anthropic.com)에서 발급)

## 설치

### App Store

Docklings는 [Mac App Store](https://apps.apple.com/app/docklings/id6761625663)에서 $3.99에 구매할 수 있습니다.

### 소스에서 빌드

```bash
# 클론
git clone https://github.com/Jin-hoKim/my-agent-on-doc.git
cd my-agent-on-doc

# 빌드
swift build

# 실행
swift run MyAgentOnDock

# 릴리즈 빌드
swift build -c release
```

## 설정

앱 실행 후 메뉴바 아이콘을 클릭하고 설정을 엽니다:

1. **연결 모드** — Claude CLI 또는 API 모드 선택
2. **API 키** — Anthropic API 키 입력 (API 모드)
3. **캐릭터** — 컴패니언 선택 (개발자, 로봇, 고양이, 펭귄, 우주인, 닌자)
4. **캐릭터 크기** — 크기 조절 (40pt~120pt)
5. **Claude 모델** — Haiku, Sonnet, Opus 선택
6. **음성** — TTS 음성 선택

## 기술 스택

- Swift 5.9+ / SwiftUI / AppKit (NSPanel, NSStatusItem, NSPopover)
- Claude Messages API (SSE 스트리밍)
- AVSpeechSynthesizer (TTS)
- Lottie for iOS (캐릭터 애니메이션)

## 개인정보

Docklings는 사용자의 개인정보를 존중합니다. 모든 데이터는 사용자의 기기에 로컬로 저장됩니다. 채팅 메시지는 응답 생성을 위해서만 Anthropic의 Claude API로 전송됩니다. [개인정보 처리방침](https://jin-hokim.github.io/my-agent-on-doc/privacy-policy-ko.html)을 확인하세요.

## 라이선스

Copyright 2026 김진호. All rights reserved.

---

[English](README.md)
