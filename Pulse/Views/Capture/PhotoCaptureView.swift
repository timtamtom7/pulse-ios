import SwiftUI

struct PhotoCaptureView: View {
    @Bindable var viewModel: CaptureViewModel
    @Binding var showingPicker: Bool

    var body: some View {
        VStack(spacing: Theme.Spacing.xl) {
            Spacer()

            if let image = viewModel.capturedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 300)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.large))
                    .shadow(color: .black.opacity(0.1), radius: 16, y: 8)

                if viewModel.isAnalyzing {
                    HStack(spacing: Theme.Spacing.sm) {
                        ProgressView()
                            .tint(Theme.Colors.mutedRose)
                        Text("Analyzing...")
                            .font(Theme.Typography.bodyFont)
                            .foregroundColor(Theme.Colors.warmGray)
                    }
                }
            } else {
                // Empty state
                VStack(spacing: Theme.Spacing.md) {
                    ZStack {
                        Circle()
                            .fill(Theme.Colors.softBlush)
                            .frame(width: 120, height: 120)

                        Image(systemName: "photo.fill")
                            .font(.system(size: 48))
                            .foregroundColor(Theme.Colors.mutedRose.opacity(0.6))
                    }

                    Text("Capture a moment")
                        .font(Theme.Typography.headlineFont)
                        .foregroundColor(Theme.Colors.charcoal)

                    Text("Take a photo or choose from your library to understand how you're feeling")
                        .font(Theme.Typography.bodyFont)
                        .foregroundColor(Theme.Colors.warmGray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Theme.Spacing.xl)

                    PulseButton(title: "Choose Photo", icon: "photo.on.rectangle") {
                        showingPicker = true
                    }
                }
            }

            Spacer()

            // Action buttons
            if viewModel.capturedImage != nil && !viewModel.isAnalyzing {
                HStack(spacing: Theme.Spacing.md) {
                    Button {
                        viewModel.reset()
                    } label: {
                        Label("Retake", systemImage: "arrow.counterclockwise")
                            .font(Theme.Typography.bodyFont)
                            .foregroundColor(Theme.Colors.warmGray)
                            .padding(.horizontal, Theme.Spacing.lg)
                            .padding(.vertical, Theme.Spacing.md)
                            .background(Theme.Colors.softBlush)
                            .cornerRadius(Theme.CornerRadius.button)
                    }

                    PulseButton(title: "Analyze", icon: "sparkles") {
                        // Already analyzing or captured
                    }
                }
            }

            if let error = viewModel.errorMessage {
                Text(error)
                    .font(Theme.Typography.captionFont)
                    .foregroundColor(Theme.Colors.deepEmber)
                    .padding()
            }
        }
        .padding(.vertical, Theme.Spacing.xl)
    }
}

#Preview {
    PhotoCaptureView(viewModel: CaptureViewModel(), showingPicker: .constant(false))
}
