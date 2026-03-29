import SwiftUI
import AVFoundation

struct MacCaptureView: View {
    @Bindable var viewModel: CaptureViewModel
    @State private var selectedEmotion: EmotionCategory?

    // The 5 primary emotions for quick capture
    private let quickEmotions: [(category: EmotionCategory, icon: String, label: String)] = [
        (.joy, "face.smiling.fill", "Happy"),
        (.trust, "heart.fill", "Content"),
        (.surprise, "sparkles", "Surprised"),
        (.sadness, "cloud.rain.fill", "Sad"),
        (.neutral, "circle.fill", "Neutral")
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView

            Divider()

            // Main content
            ScrollView {
                VStack(spacing: MacTheme.Spacing.xl) {
                    // Mode picker
                    modePicker

                    // Capture area
                    captureArea
                }
                .padding(MacTheme.Spacing.screenMargin)
            }
        }
        .background(MacTheme.Colors.cream)
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            if let error = viewModel.errorMessage {
                Text(error)
            }
        }
    }

    // MARK: - Header

    private var headerView: some View {
        VStack(alignment: .leading, spacing: MacTheme.Spacing.sm) {
            Text("Capture")
                .font(MacTheme.Typography.displayFont)
                .foregroundColor(MacTheme.Colors.charcoal)

            Text("How are you right now?")
                .font(MacTheme.Typography.bodyFont)
                .foregroundColor(MacTheme.Colors.warmGray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(MacTheme.Spacing.screenMargin)
    }

    // MARK: - Mode Picker

    private var modePicker: some View {
        HStack(spacing: MacTheme.Spacing.md) {
            ForEach(CaptureMode.allCases, id: \.self) { mode in
                Button {
                    withAnimation(MacTheme.Animations.gentleEaseOut) {
                        viewModel.captureMode = mode
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: mode.icon)
                            .font(.system(size: 14))

                        Text(mode.rawValue.capitalized)
                            .font(MacTheme.Typography.calloutFont)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        viewModel.captureMode == mode
                        ? MacTheme.Colors.mutedRose
                        : MacTheme.Colors.warmWhite
                    )
                    .foregroundColor(
                        viewModel.captureMode == mode
                        ? .white
                        : MacTheme.Colors.warmGray
                    )
                    .cornerRadius(MacTheme.CornerRadius.large)
                    .shadow(
                        color: MacTheme.Colors.cardShadow,
                        radius: viewModel.captureMode == mode ? 8 : 4,
                        y: 2
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Capture Area

    @ViewBuilder
    private var captureArea: some View {
        switch viewModel.captureMode {
        case .photo:
            photoCaptureArea
        case .voice:
            voiceCaptureArea
        case .journal:
            journalCaptureArea
        }
    }

    // MARK: - Photo Capture

    private var photoCaptureArea: some View {
        VStack(spacing: MacTheme.Spacing.lg) {
            // Photo placeholder
            ZStack {
                RoundedRectangle(cornerRadius: MacTheme.CornerRadius.card)
                    .fill(MacTheme.Colors.warmWhite)
                    .shadow(color: MacTheme.Colors.cardShadow, radius: 12, y: 4)

                VStack(spacing: MacTheme.Spacing.md) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 48))
                        .foregroundColor(MacTheme.Colors.mutedRose.opacity(0.5))

                    Text("Photo capture coming soon")
                        .font(MacTheme.Typography.bodyFont)
                        .foregroundColor(MacTheme.Colors.warmGray)

                    Text("Use Voice or Journal to capture moments")
                        .font(MacTheme.Typography.captionFont)
                        .foregroundColor(MacTheme.Colors.warmGray.opacity(0.8))
                }
            }
            .frame(height: 300)

            // Analysis results
            if let result = viewModel.analysisResult {
                analysisResultsView(result)
            }
        }
    }

    // MARK: - Voice Capture

    private var voiceCaptureArea: some View {
        VStack(spacing: MacTheme.Spacing.lg) {
            // Recording UI
            ZStack {
                RoundedRectangle(cornerRadius: MacTheme.CornerRadius.card)
                    .fill(MacTheme.Colors.warmWhite)
                    .shadow(color: MacTheme.Colors.cardShadow, radius: 12, y: 4)

                VStack(spacing: MacTheme.Spacing.lg) {
                    // Waveform visualization
                    MacVoiceWaveformView(isRecording: viewModel.isRecording)
                        .frame(height: 80)

                    // Duration
                    Text(viewModel.formattedDuration)
                        .font(.system(size: 48, weight: .light, design: .monospaced))
                        .foregroundColor(MacTheme.Colors.charcoal)

                    // Record button
                    Button {
                        if viewModel.isRecording {
                            Task {
                                await viewModel.stopRecording()
                            }
                        } else {
                            Task {
                                await viewModel.startRecording()
                            }
                        }
                    } label: {
                        ZStack {
                            Circle()
                                .fill(MacTheme.Colors.mutedRose)
                                .frame(width: 72, height: 72)
                                .shadow(color: MacTheme.Colors.mutedRose.opacity(0.4), radius: 12, y: 4)

                            if viewModel.isRecording {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.white)
                                    .frame(width: 24, height: 24)
                            } else {
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 24, height: 24)
                            }
                        }
                    }
                    .buttonStyle(.plain)

                    Text(viewModel.isRecording ? "Tap to stop" : "Tap to record")
                        .font(MacTheme.Typography.captionFont)
                        .foregroundColor(MacTheme.Colors.warmGray)
                }
                .padding(MacTheme.Spacing.xl)
            }
            .frame(height: 340)

            // Transcription
            if !viewModel.transcription.isEmpty {
                VStack(alignment: .leading, spacing: MacTheme.Spacing.sm) {
                    Text("Transcription")
                        .font(MacTheme.Typography.captionFont)
                        .foregroundColor(MacTheme.Colors.warmGray)
                        .textCase(.uppercase)

                    Text(viewModel.transcription)
                        .font(MacTheme.Typography.bodyFont)
                        .foregroundColor(MacTheme.Colors.charcoal)
                        .padding(MacTheme.Spacing.md)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(MacTheme.Colors.softBlush)
                        .cornerRadius(MacTheme.CornerRadius.medium)
                }
            }

            // Analysis results
            if let result = viewModel.analysisResult {
                analysisResultsView(result)
            }
        }
    }

    // MARK: - Journal Capture

    private var journalCaptureArea: some View {
        VStack(spacing: MacTheme.Spacing.lg) {
            // Quick emotion selection
            VStack(alignment: .leading, spacing: MacTheme.Spacing.md) {
                Text("Quick capture — how are you?")
                    .font(MacTheme.Typography.calloutFont)
                    .foregroundColor(MacTheme.Colors.warmGray)

                HStack(spacing: MacTheme.Spacing.md) {
                    ForEach(quickEmotions, id: \.category) { emotion in
                        quickEmotionButton(emotion)
                    }
                }
            }

            // Journal text area
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: MacTheme.CornerRadius.card)
                    .fill(MacTheme.Colors.warmWhite)
                    .shadow(color: MacTheme.Colors.cardShadow, radius: 12, y: 4)

                VStack(spacing: 0) {
                    TextEditor(text: $viewModel.journalText)
                        .font(MacTheme.Typography.bodyFont)
                        .foregroundColor(MacTheme.Colors.charcoal)
                        .scrollContentBackground(.hidden)
                        .padding(MacTheme.Spacing.md)
                        .frame(minHeight: 200)

                    Divider()

                    HStack {
                        Text("\(viewModel.journalText.count) characters")
                            .font(MacTheme.Typography.captionFont)
                            .foregroundColor(MacTheme.Colors.warmGray)

                        Spacer()

                        Button("Clear") {
                            viewModel.journalText = ""
                        }
                        .font(MacTheme.Typography.captionFont)
                        .foregroundColor(MacTheme.Colors.warmGray)
                    }
                    .padding(MacTheme.Spacing.md)
                }
            }
            .frame(height: 280)

            // Analysis results
            if let result = viewModel.analysisResult {
                analysisResultsView(result)
            }

            // Submit button
            Button {
                Task {
                    await viewModel.submitJournal()
                }
            } label: {
                HStack {
                    if viewModel.isAnalyzing {
                        ProgressView()
                            .scaleEffect(0.8)
                            .padding(.trailing, 8)
                    }
                    Text(viewModel.isAnalyzing ? "Analyzing..." : "Analyze & Save")
                }
                .frame(maxWidth: .infinity)
                .padding(MacTheme.Spacing.md)
                .background(
                    viewModel.canSave
                    ? MacTheme.Colors.mutedRose
                    : MacTheme.Colors.warmGray
                )
                .foregroundColor(.white)
                .cornerRadius(MacTheme.CornerRadius.medium)
            }
            .buttonStyle(.plain)
            .disabled(!viewModel.canSave || viewModel.isAnalyzing)
        }
    }

    // MARK: - Quick Emotion Button

    private func quickEmotionButton(_ emotion: (category: EmotionCategory, icon: String, label: String)) -> some View {
        Button {
            withAnimation(MacTheme.Animations.springBack) {
                selectedEmotion = emotion.category
            }
        } label: {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(
                            selectedEmotion == emotion.category
                            ? emotion.category.color
                            : emotion.category.color.opacity(0.2)
                        )
                        .frame(width: 56, height: 56)

                    Image(systemName: emotion.icon)
                        .font(.system(size: 24))
                        .foregroundColor(
                            selectedEmotion == emotion.category
                            ? .white
                            : emotion.category.color
                        )
                }

                Text(emotion.label)
                    .font(MacTheme.Typography.captionFont)
                    .foregroundColor(MacTheme.Colors.charcoal)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Analysis Results

    private func analysisResultsView(_ result: (score: Double, tags: [EmotionTag])) -> some View {
        VStack(alignment: .leading, spacing: MacTheme.Spacing.md) {
            // Sentiment bar
            VStack(alignment: .leading, spacing: MacTheme.Spacing.sm) {
                Text("Sentiment Score")
                    .font(MacTheme.Typography.captionFont)
                    .foregroundColor(MacTheme.Colors.warmGray)
                    .textCase(.uppercase)

                HStack(spacing: MacTheme.Spacing.md) {
                    Text("Negative")
                        .font(MacTheme.Typography.captionFont)
                        .foregroundColor(MacTheme.Colors.warmGray)

                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(MacTheme.Colors.softBlush)
                                .frame(height: 8)

                            RoundedRectangle(cornerRadius: 4)
                                .fill(MacTheme.Colors.emotionColor(for: result.score))
                                .frame(width: geometry.size.width * CGFloat((result.score + 1) / 2), height: 8)
                        }
                    }
                    .frame(height: 8)

                    Text("Positive")
                        .font(MacTheme.Typography.captionFont)
                        .foregroundColor(MacTheme.Colors.warmGray)
                }
            }

            // Emotion tags
            VStack(alignment: .leading, spacing: MacTheme.Spacing.sm) {
                Text("Detected Emotions")
                    .font(MacTheme.Typography.captionFont)
                    .foregroundColor(MacTheme.Colors.warmGray)
                    .textCase(.uppercase)

                FlowLayout(spacing: MacTheme.Spacing.sm) {
                    ForEach(result.tags) { tag in
                        EmotionTagView(tag: tag)
                    }
                }
            }

            // Save button
            HStack(spacing: MacTheme.Spacing.md) {
                Button("Discard") {
                    viewModel.reset()
                }
                .font(MacTheme.Typography.calloutFont)
                .foregroundColor(MacTheme.Colors.warmGray)
                .padding(MacTheme.Spacing.md)
                .background(MacTheme.Colors.softBlush)
                .cornerRadius(MacTheme.CornerRadius.medium)

                Button("Save Moment") {
                    viewModel.saveMoment(note: nil)
                }
                .font(MacTheme.Typography.calloutFont.weight(.semibold))
                .foregroundColor(.white)
                .padding(MacTheme.Spacing.md)
                .background(MacTheme.Colors.calmSage)
                .cornerRadius(MacTheme.CornerRadius.medium)
            }
        }
        .padding(MacTheme.Spacing.cardPadding)
        .background(MacTheme.Colors.warmWhite)
        .cornerRadius(MacTheme.CornerRadius.card)
        .shadow(color: MacTheme.Colors.cardShadow, radius: 12, y: 4)
    }
}

// MARK: - Voice Waveform View

struct MacVoiceWaveformView: View {
    let isRecording: Bool
    @State private var phase: Double = 0

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let midY = size.height / 2
                let barCount = 30
                let barWidth = size.width / CGFloat(barCount * 2)

                for i in 0..<barCount {
                    let x = CGFloat(i) * (barWidth * 2) + barWidth / 2
                    let height = isRecording
                        ? sin(phase + Double(i) * 0.3) * (size.height * 0.4) + size.height * 0.2
                        : size.height * 0.1

                    let rect = CGRect(
                        x: x,
                        y: midY - height / 2,
                        width: barWidth,
                        height: max(4, height)
                    )

                    context.fill(
                        RoundedRectangle(cornerRadius: barWidth / 2)
                            .path(in: rect),
                        with: .color(MacTheme.Colors.mutedRose.opacity(isRecording ? 0.8 : 0.3))
                    )
                }
            }
        }
        .onChange(of: isRecording) { _, newValue in
            if newValue {
                withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                    phase = .infinity
                }
            }
        }
    }
}

#Preview {
    MacCaptureView(viewModel: CaptureViewModel())
}
