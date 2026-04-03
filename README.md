# My Agent on Dock

macOS Dock 위에 AI 에이전트 캐릭터를 표시하는 앱. Claude API로 작동하는 Solo 모드 개인 AI 비서.

## 주요 기능

- **Dock 위 캐릭터**: AI 에이전트 캐릭터가 Dock 위에 상시 표시
- **프롬프트 대화**: 캐릭터 클릭 → 대화 창 → Claude와 채팅
- **캐릭터 커스터마이징**: 6종 캐릭터, 크기 조절
- **모델 선택**: Haiku / Sonnet / Opus
- **메뉴바 컨트롤**: 상태 확인, 설정, 토글

## 요구사항

- macOS 14.0 (Sonoma) 이상
- Claude API 키 ([anthropic.com](https://console.anthropic.com)에서 발급)

## 빌드 및 실행

```bash
# 빌드
swift build

# 실행
swift run MyAgentOnDock

# 릴리즈 빌드
swift build -c release
```

## 설정

앱 실행 후 메뉴바 아이콘(✦) → 설정에서:

1. **API 키** 입력
2. **캐릭터** 선택 (개발자/로봇/고양이/펭귄/우주인/닌자)
3. **캐릭터 크기** 조절 (40pt ~ 120pt)
4. **Claude 모델** 선택
5. **음성** 선택 (향후 TTS 지원)

## 기술 스택

- Swift 5.9+ / SwiftUI / AppKit
- Claude Messages API
- Lottie (애니메이션)

## GitHub

https://github.com/Jin-hoKim/my-agent-on-doc
