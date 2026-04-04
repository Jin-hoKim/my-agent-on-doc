# Docklings

A charming AI companion that lives right above your macOS Dock. Powered by Claude, it features animated robot characters that express emotions and react to conversations in real time.

## Features

- **Dock Companion** — An animated AI character sits above your Dock, always ready to chat
- **Real-time Conversation** — Click the character to open a chat window powered by Claude (SSE streaming)
- **Expressive Animations** — 6 characters with 20+ Lottie-animated expressions that react to conversation context
- **Chat History** — Conversations saved locally with quick access from the menu bar
- **Model Selection** — Choose between Claude Haiku, Sonnet, and Opus
- **Text-to-Speech** — Have responses read aloud with multiple voice options (male, female, robot)
- **Menu Bar Control** — Status, settings, and quick toggles from the menu bar
- **Character Customization** — Resize characters (40pt–120pt) and pick your favorite

## Characters

| Nova | Sprout |
|------|--------|
| Blue robot with tech-savvy personality | Green robot with cheerful personality |

Each character has 20+ expressions including happy, sad, surprised, thinking, typing, error, and more.

## Requirements

- macOS 14.0 (Sonoma) or later
- Anthropic API key (get one at [console.anthropic.com](https://console.anthropic.com))

## Installation

### App Store

Docklings is available on the [Mac App Store](https://apps.apple.com/app/docklings/id6761625663) for $3.99.

### Build from Source

```bash
# Clone
git clone https://github.com/Jin-hoKim/my-agent-on-doc.git
cd my-agent-on-doc

# Build
swift build

# Run
swift run MyAgentOnDock

# Release build
swift build -c release
```

## Setup

After launching, click the menu bar icon and open Settings:

1. **Connection Mode** — Choose between Claude CLI or API mode
2. **API Key** — Enter your Anthropic API key (API mode)
3. **Character** — Pick your companion (Developer, Robot, Cat, Penguin, Astronaut, Ninja)
4. **Character Size** — Adjust size (40pt–120pt)
5. **Claude Model** — Select Haiku, Sonnet, or Opus
6. **Voice** — Choose TTS voice for read-aloud

## Tech Stack

- Swift 5.9+ / SwiftUI / AppKit (NSPanel, NSStatusItem, NSPopover)
- Claude Messages API (SSE streaming)
- AVSpeechSynthesizer (TTS)
- Lottie for iOS (character animations)

## Privacy

Docklings respects your privacy. All data is stored locally on your device. Chat messages are sent to Anthropic's Claude API only to generate responses. See our [Privacy Policy](https://jin-hokim.github.io/my-agent-on-doc/privacy-policy.html).

## License

Copyright 2026 Jin-ho Kim. All rights reserved.

---

[한국어](README-ko.md)
