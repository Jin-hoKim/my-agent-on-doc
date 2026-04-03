# Privacy Policy — My Agent on Dock

Last updated: 2026-04-03

## Overview

My Agent on Dock ("the App") is a macOS application that provides a personal AI agent powered by the Claude API (Anthropic). This privacy policy explains how the App handles user data.

## Data Collection

The App does **not** collect, store, or transmit any personal data to the developer.

## Data Stored Locally

The following data is stored **only on your device**:

| Data | Location | Purpose |
|------|----------|---------|
| Claude API Key | macOS UserDefaults (encrypted) | Authenticate with Anthropic API |
| App Settings | macOS UserDefaults | Character, model, size, voice preferences |
| Conversation History | `~/Library/Application Support/MyAgentOnDock/` | Restore previous conversations |

All locally stored data can be deleted by uninstalling the App or clearing Application Support.

## Data Transmitted to Third Parties

The App transmits data **only** to:

- **Anthropic API** (`api.anthropic.com`): Your chat messages and conversation history are sent to the Claude API to generate AI responses. This transmission is governed by [Anthropic's Privacy Policy](https://www.anthropic.com/privacy).

No other network connections are made by the App.

## API Key Security

- Your Claude API key is stored in macOS UserDefaults and is never sent anywhere except to `api.anthropic.com`.
- The App uses HTTPS for all API communications.
- The API key is never logged, shared, or uploaded to any server.

## Analytics and Tracking

The App contains **no analytics, tracking, or crash reporting** tools.

## Children's Privacy

The App is not directed at children under 13. If you are under 13, please do not use this App.

## Changes to This Policy

Updates to this policy will be noted in the App's release notes.

## Contact

If you have questions about this privacy policy, contact: [your-email@example.com]
