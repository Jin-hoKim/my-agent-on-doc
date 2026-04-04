# Docklings - Project Plan

## Project Overview

A Solo-mode macOS app that displays an AI agent character above the Dock. Powered by the user's Claude API key — click the character to open a prompt window and chat with Claude.

## Core Features

### 1. Dock Character Display
- One agent character displayed above the Dock at all times
- Animations change based on state (idle / thinking / responding / error)
- Click character to open prompt window

### 2. Prompt Window (Chat)
- Open and close by clicking the character
- Real-time conversation via Claude API (SSE streaming)
- Chat history maintained, with option to reset

### 3. Settings
- **API Key**: Enter and save Claude API key
- **Character**: Developer, Robot, Cat, Penguin, Astronaut, Ninja
- **Character Size**: 40pt–120pt slider
- **Voice**: None, Male, Female, Robot (TTS)
- **Claude Model**: Haiku 4.5 / Sonnet 4.6 / Opus 4.6

### 4. Menu Bar
- Persistent system tray icon for quick access
- API connection status display
- Agent state display
- Access to settings and quit

## Tech Stack
- Swift 5.9+ / SwiftUI / AppKit (NSPanel)
- Lottie (character animations)
- Claude API (Messages API v1, SSE streaming)
- macOS 14.0 (Sonoma)+

## Implementation Status

### Phase 1: Project Structure & Models ✅
- [x] Package.swift, Info.plist
- [x] CharacterType, AgentState, ClaudeModel, VoiceType, ChatMessage models
- [x] Successful build

### Phase 2: Service Layer ✅
- [x] AppSettings (UserDefaults-based settings management)
- [x] ClaudeAPIService (API calls, conversation management)
- [x] PanelManager (Dock panel positioning)

### Phase 3: UI Views ✅
- [x] DockCharacterView (character above Dock)
- [x] PromptWindowView (chat window)
- [x] SettingsView (settings panel)
- [x] MenuBarView (menu bar dropdown)

### Phase 4: App Integration ✅
- [x] MyAgentOnDockApp (main app)
- [x] AppDelegate (lifecycle management)
- [x] Full build success

### Phase 5: Feature Completion ✅
- [x] Lottie animations (20+ expressions per character)
- [x] TTS voice output (male / female / robot)
- [x] SSE streaming responses
- [x] Local chat history persistence
- [x] App Store submission

### Phase 6: App Store Release ✅
- [x] App Sandbox & network entitlements
- [x] Code signing (Apple Developer)
- [x] App icon (ICNS with all required sizes)
- [x] Screenshots and metadata
- [x] Privacy Policy (English & Korean)
- [x] Age rating & content rights
- [x] Submitted for review (April 4, 2026)
