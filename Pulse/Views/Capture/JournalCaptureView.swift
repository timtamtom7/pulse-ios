import SwiftUI

struct JournalCaptureView: View {
    @Bindable var viewModel: CaptureViewModel
    @FocusState private var isFocused: Bool

    private let prompts = [
        "How are you feeling right now?",
        "What's on your mind today?",
        "What made you smile recently?",
        "Any challenges you're facing?",
        "What are you grateful for?"
    ]

    @State private var randomPrompt: String = ""

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            // Prompt suggestion
            if viewModel.journalText.isEmpty && !isFocused {
                VStack(spacing: Theme.Spacing.sm) {
                    Text(randomPrompt)
                        .font(Theme.Typography.headlineFont)
                        .foregroundColor(Theme.Colors.charcoal)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Theme.Spacing.xl)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
                .padding(.top, Theme.Spacing.xl)
                .onAppear {
                    randomPrompt = prompts.randomElement() ?? prompts[0]
                }
            }

            // Text input area
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                if viewModel.journalText.isEmpty {
                    Text("Write your thoughts...")
                        .font(Theme.Typography.bodyFont)
                        .foregroundColor(Theme.Colors.warmGray.opacity(0.6))
                        .padding(.horizontal, Theme.Spacing.md)
                        .padding(.top, Theme.Spacing.md)
                }

                TextEditor(text: $viewModel.journalText)
                    .font(Theme.Typography.bodyFont)
                    .foregroundColor(Theme.Colors.charcoal)
                    .scrollContentBackground(.hidden)
                    .background(Theme.Colors.cardBackground)
                    .focused($isFocused)
                    .frame(minHeight: 200)
                    .padding(Theme.Spacing.sm)
            }
            .background(Theme.Colors.cardBackground)
            .cornerRadius(Theme.CornerRadius.large)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.large)
                    .stroke(Theme.Colors.softBlush, lineWidth: 1)
            )

            // Character count
            HStack {
                Spacer()
                Text("\(viewModel.journalText.count) characters")
                    .font(Theme.Typography.captionFont)
                    .foregroundColor(Theme.Colors.warmGray)
            }

            Spacer()

            // Analyze button
            if viewModel.isAnalyzing {
                HStack(spacing: Theme.Spacing.sm) {
                    ProgressView()
                        .tint(Theme.Colors.mutedRose)
                    Text("Analyzing your entry...")
                        .font(Theme.Typography.bodyFont)
                        .foregroundColor(Theme.Colors.warmGray)
                }
                .padding(.vertical, Theme.Spacing.md)
            } else {
                Button {
                    let vm = viewModel
                    Task { @MainActor in
                        await vm.submitJournal()
                    }
                } label: {
                    HStack(spacing: Theme.Spacing.sm) {
                        Image(systemName: "sparkles")
                        Text("Analyze")
                    }
                    .font(Theme.Typography.bodyFont)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, Theme.Spacing.lg)
                    .padding(.vertical, Theme.Spacing.md)
                    .background(
                        LinearGradient(
                            colors: viewModel.journalText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                ? [Theme.Colors.warmGray, Theme.Colors.warmGray.opacity(0.8)]
                                : [Theme.Colors.mutedRose, Theme.Colors.dustyRose],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(Theme.CornerRadius.button)
                }
                .disabled(viewModel.journalText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
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
        .padding(.vertical, Theme.Spacing.lg)
    }
}

#Preview {
    JournalCaptureView(viewModel: CaptureViewModel())
        .padding()
        .background(Theme.Colors.primaryBackground)
}
