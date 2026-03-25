import SwiftUI

struct VoiceCaptureView: View {
    @Bindable var viewModel: CaptureViewModel

    var body: some View {
        VStack(spacing: Theme.Spacing.xl) {
            Spacer()

            if viewModel.isRecording {
                // Recording state
                VStack(spacing: Theme.Spacing.lg) {
                    // Animated recording indicator
                    ZStack {
                        ForEach(0..<3) { i in
                            Circle()
                                .stroke(Theme.Colors.mutedRose.opacity(0.3), lineWidth: 2)
                                .frame(width: CGFloat(100 + i * 40), height: CGFloat(100 + i * 40))
                                .scaleEffect(viewModel.isRecording ? 1.2 : 1.0)
                                .animation(
                                    .easeInOut(duration: 1.0)
                                    .repeatForever(autoreverses: true)
                                    .delay(Double(i) * 0.2),
                                    value: viewModel.isRecording
                                )
                        }

                        Circle()
                            .fill(Theme.Colors.mutedRose)
                            .frame(width: 100, height: 100)
                            .overlay {
                                Image(systemName: "waveform")
                                    .font(.system(size: 36))
                                    .foregroundColor(.white)
                            }
                    }

                    Text(viewModel.formattedDuration)
                        .font(.system(size: 48, weight: .light, design: .monospaced))
                        .foregroundColor(Theme.Colors.charcoal)

                    Text("Recording...")
                        .font(Theme.Typography.bodyFont)
                        .foregroundColor(Theme.Colors.warmGray)
                }
            } else if viewModel.isAnalyzing {
                // Analyzing state
                VStack(spacing: Theme.Spacing.lg) {
                    ZStack {
                        Circle()
                            .fill(Theme.Colors.softBlush)
                            .frame(width: 120, height: 120)

                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(Theme.Colors.mutedRose)
                    }

                    Text("Analyzing your voice...")
                        .font(Theme.Typography.headlineFont)
                        .foregroundColor(Theme.Colors.charcoal)

                    Text("Transcribing and detecting emotional tone")
                        .font(Theme.Typography.bodyFont)
                        .foregroundColor(Theme.Colors.warmGray)
                }
            } else {
                // Ready state
                VStack(spacing: Theme.Spacing.lg) {
                    ZStack {
                        Circle()
                            .fill(Theme.Colors.softBlush)
                            .frame(width: 120, height: 120)

                        Image(systemName: "waveform")
                            .font(.system(size: 48))
                            .foregroundColor(Theme.Colors.mutedRose.opacity(0.6))
                    }

                    Text("Record a voice note")
                        .font(Theme.Typography.headlineFont)
                        .foregroundColor(Theme.Colors.charcoal)

                    Text("Speak freely — Pulse will transcribe and analyze your emotional tone")
                        .font(Theme.Typography.bodyFont)
                        .foregroundColor(Theme.Colors.warmGray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Theme.Spacing.xl)

                    Button {
                        Task { @MainActor in
                            await viewModel.startRecording()
                        }
                    } label: {
                        HStack(spacing: Theme.Spacing.sm) {
                            Image(systemName: "mic.fill")
                            Text("Start Recording")
                        }
                        .font(Theme.Typography.bodyFont)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, Theme.Spacing.lg)
                        .padding(.vertical, Theme.Spacing.md)
                        .background(LinearGradient(colors: [Theme.Colors.mutedRose, Theme.Colors.dustyRose], startPoint: .leading, endPoint: .trailing))
                        .cornerRadius(Theme.CornerRadius.button)
                    }
                }
            }

            Spacer()

            // Stop button when recording
            if viewModel.isRecording {
                Button {
                    Task { @MainActor in
                        await viewModel.stopRecording()
                    }
                } label: {
                    HStack {
                        Image(systemName: "stop.fill")
                        Text("Stop")
                    }
                    .font(Theme.Typography.bodyFont)
                    .foregroundColor(.white)
                    .padding(.horizontal, Theme.Spacing.xl)
                    .padding(.vertical, Theme.Spacing.md)
                    .background(Theme.Colors.dustyRose)
                    .cornerRadius(Theme.CornerRadius.button)
                }
            }

            if let error = viewModel.errorMessage {
                VStack(spacing: Theme.Spacing.sm) {
                    Text(error)
                        .font(Theme.Typography.captionFont)
                        .foregroundColor(Theme.Colors.deepEmber)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    if error.contains("Settings") {
                        Button {
                            PermissionService.shared.openSettings()
                        } label: {
                            Text("Open Settings")
                                .font(Theme.Typography.captionFont)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .padding(.horizontal, Theme.Spacing.md)
                                .padding(.vertical, Theme.Spacing.sm)
                                .background(Theme.Colors.mutedRose)
                                .cornerRadius(Theme.CornerRadius.button)
                        }
                    }
                }
                .padding()
            }
        }
        .padding(.vertical, Theme.Spacing.xl)
    }
}

#Preview {
    VoiceCaptureView(viewModel: CaptureViewModel())
}
