import SwiftUI

// 설정 창 뷰
struct SettingsView: View {
    @ObservedObject private var settings = AppSettings.shared
    @State private var showAPIKey = false
    @State private var tempAPIKey = ""

    var body: some View {
        VStack(spacing: 0) {
            // 헤더
            HStack {
                Image(systemName: "gearshape.fill")
                    .font(.title3)
                Text("설정")
                    .font(.headline)
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)

            Divider()

            ScrollView {
                VStack(spacing: 24) {
                    // API 키 섹션
                    apiKeySection

                    Divider().padding(.horizontal)

                    // 모델 선택 섹션
                    modelSection

                    Divider().padding(.horizontal)

                    // 캐릭터 선택 섹션
                    characterSection

                    Divider().padding(.horizontal)

                    // 캐릭터 사이즈 섹션
                    sizeSection

                    Divider().padding(.horizontal)

                    // 음성 선택 섹션
                    voiceSection
                }
                .padding(.vertical, 16)
            }
        }
        .frame(width: 400, height: 640)
        .background(.ultraThickMaterial)
        .onAppear {
            tempAPIKey = settings.apiKey
        }
    }

    // API 키 입력 섹션
    private var apiKeySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Claude API 키", systemImage: "key.fill")
                .font(.subheadline.weight(.semibold))

            HStack(spacing: 8) {
                Group {
                    if showAPIKey {
                        TextField("sk-ant-...", text: $tempAPIKey)
                    } else {
                        SecureField("sk-ant-...", text: $tempAPIKey)
                    }
                }
                .textFieldStyle(.roundedBorder)
                .font(.system(.body, design: .monospaced))

                Button(action: { showAPIKey.toggle() }) {
                    Image(systemName: showAPIKey ? "eye.slash" : "eye")
                }
                .buttonStyle(.plain)

                Button("저장") {
                    settings.apiKey = tempAPIKey
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }

            if settings.isAPIKeySet {
                Label("API 키가 설정되었습니다", systemImage: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.green)
            } else {
                Label("anthropic.com에서 API 키를 발급받으세요", systemImage: "info.circle")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 20)
    }

    // 모델 선택 섹션
    private var modelSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Claude 모델", systemImage: "cpu")
                .font(.subheadline.weight(.semibold))

            Picker("", selection: Binding(
                get: { settings.claudeModel },
                set: { settings.claudeModel = $0 }
            )) {
                ForEach(ClaudeModel.allCases) { model in
                    Text(model.displayName).tag(model)
                }
            }
            .pickerStyle(.radioGroup)
        }
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // 캐릭터 선택 섹션
    private var characterSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("캐릭터", systemImage: "person.fill")
                .font(.subheadline.weight(.semibold))

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
                ForEach(CharacterType.allCases) { char in
                    CharacterPickerItem(
                        character: char,
                        isSelected: settings.characterType == char
                    )
                    .onTapGesture {
                        settings.characterType = char
                    }
                }
            }
        }
        .padding(.horizontal, 20)
    }

    // 캐릭터 사이즈 섹션
    private var sizeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("캐릭터 크기", systemImage: "arrow.up.left.and.arrow.down.right")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text("\(Int(settings.characterSize))pt")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            HStack {
                Text("작게")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Slider(
                    value: $settings.characterSize,
                    in: AppSettings.minSize...AppSettings.maxSize,
                    step: 4
                )
                Text("크게")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            // 미리보기
            HStack {
                Spacer()
                Text(settings.characterType.idleEmoji)
                    .font(.system(size: settings.characterSize * 0.45))
                    .frame(width: settings.characterSize * 0.85, height: settings.characterSize * 0.85)
                    .background(Circle().fill(settings.characterType.themeColor.opacity(0.2)))
                Spacer()
            }
        }
        .padding(.horizontal, 20)
    }

    // 음성 선택 섹션
    private var voiceSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("음성 (TTS)", systemImage: "speaker.wave.2.fill")
                .font(.subheadline.weight(.semibold))

            // TTS 활성화 토글
            Toggle("응답 읽어주기 활성화", isOn: $settings.ttsEnabled)
                .toggleStyle(.switch)
                .controlSize(.small)

            if settings.ttsEnabled {
                Picker("", selection: Binding(
                    get: { settings.voiceType },
                    set: { settings.voiceType = $0 }
                )) {
                    ForEach(VoiceType.allCases.filter { $0 != .none }) { voice in
                        Text(voice.displayName).tag(voice)
                    }
                }
                .pickerStyle(.radioGroup)
                .disabled(!settings.ttsEnabled)

                // 테스트 재생 버튼
                Button(action: {
                    TTSService.shared.speak("안녕하세요! 저는 여러분의 AI 에이전트입니다.", voiceType: settings.voiceType)
                }) {
                    Label("음성 테스트", systemImage: "play.circle")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }

            Text(settings.ttsEnabled ? "에이전트 응답을 음성으로 읽어드립니다" : "응답을 읽어주기 기능이 비활성화되어 있습니다")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// 캐릭터 선택 아이템
struct CharacterPickerItem: View {
    let character: CharacterType
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 6) {
            Text(character.idleEmoji)
                .font(.system(size: 32))
                .frame(width: 56, height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected
                              ? character.themeColor.opacity(0.2)
                              : Color.secondary.opacity(0.05))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? character.themeColor : .clear, lineWidth: 2)
                )

            Text(character.displayName)
                .font(.caption2)
                .foregroundColor(isSelected ? .primary : .secondary)
        }
    }
}
