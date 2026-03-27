import SwiftUI
import PhotosUI

struct CaptureView: View {
    @State private var viewModel = CaptureViewModel()
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var showingPhotoPicker = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Mode picker
                Picker("Capture Mode", selection: Binding(
                    get: { viewModel.captureMode },
                    set: { viewModel.captureMode = $0 }
                )) {
                    ForEach(CaptureMode.allCases, id: \.self) { mode in
                        Label(mode.rawValue, systemImage: mode.icon).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, Theme.Spacing.screenMargin)
                .padding(.vertical, Theme.Spacing.md)

                // Content based on mode
                Group {
                    switch viewModel.captureMode {
                    case .photo:
                        PhotoCaptureView(
                            viewModel: viewModel,
                            showingPicker: $showingPhotoPicker
                        )
                    case .voice:
                        VoiceCaptureView(viewModel: viewModel)
                    case .journal:
                        JournalCaptureView(viewModel: viewModel)
                    }
                }
                .padding(.horizontal, Theme.Spacing.screenMargin)
            }
            .background(Theme.Colors.primaryBackground)
            .navigationTitle("Capture")
            .sheet(isPresented: $viewModel.showAnalysisSheet) {
                AnalysisResultSheet(viewModel: viewModel)
            }
            .photosPicker(isPresented: $showingPhotoPicker, selection: $selectedPhotoItem, matching: .images)
            .onChange(of: selectedPhotoItem) { _, newItem in
                Task {
                    if let newItem,
                       let data = try? await newItem.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        await viewModel.capturePhoto(image)
                    }
                }
            }
        }
    }
}

struct AnalysisResultSheet: View {
    let viewModel: CaptureViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var note = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                    // Emotion tags
                    if let result = viewModel.analysisResult {
                        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                            Text("Detected Emotions")
                                .font(Theme.Typography.captionFont)
                                .foregroundColor(Theme.Colors.warmGray)
                                .textCase(.uppercase)

                            FlowLayout(spacing: Theme.Spacing.sm) {
                                ForEach(result.tags) { tag in
                                    EmotionTagView(tag: tag)
                                }
                            }
                        }

                        // Sentiment score visualization
                        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                            Text("Sentiment")
                                .font(Theme.Typography.captionFont)
                                .foregroundColor(Theme.Colors.warmGray)
                                .textCase(.uppercase)

                            HStack {
                                Text("Negative")
                                    .font(Theme.Typography.captionFont)
                                    .foregroundColor(Theme.Colors.warmGray)

                                GeometryReader { geometry in
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: Theme.CornerRadius.extraSmall)
                                            .fill(Theme.Colors.softBlush)

                                        RoundedRectangle(cornerRadius: Theme.CornerRadius.extraSmall)
                                            .fill(Theme.Colors.emotionColor(for: result.score))
                                            .frame(width: geometry.size.width * CGFloat((result.score + 1) / 2))
                                    }
                                }
                                .frame(height: 8)

                                Text("Positive")
                                    .font(Theme.Typography.captionFont)
                                    .foregroundColor(Theme.Colors.warmGray)
                            }
                        }

                        // Transcription if voice
                        if viewModel.captureMode == .voice && !viewModel.transcription.isEmpty {
                            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                                Text("Transcription")
                                    .font(Theme.Typography.captionFont)
                                    .foregroundColor(Theme.Colors.warmGray)
                                    .textCase(.uppercase)

                                Text(viewModel.transcription)
                                    .font(Theme.Typography.bodyFont)
                                    .foregroundColor(Theme.Colors.charcoal)
                                    .padding(Theme.Spacing.md)
                                    .background(Theme.Colors.softBlush)
                                    .cornerRadius(Theme.CornerRadius.medium)
                            }
                        }
                    }

                    // Add note
                    VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                        Text("Add a note (optional)")
                            .font(Theme.Typography.captionFont)
                            .foregroundColor(Theme.Colors.warmGray)
                            .textCase(.uppercase)

                        TextField("What's on your mind?", text: $note, axis: .vertical)
                            .lineLimit(3...6)
                            .padding(Theme.Spacing.md)
                            .background(Theme.Colors.cardBackground)
                            .cornerRadius(Theme.CornerRadius.medium)
                            .overlay(
                                RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                                    .stroke(Theme.Colors.softBlush, lineWidth: 1)
                            )
                    }

                    Spacer()
                }
                .padding(Theme.Spacing.screenMargin)
            }
            .background(Theme.Colors.primaryBackground)
            .navigationTitle("Analysis")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Discard") {
                        viewModel.reset()
                        dismiss()
                    }
                    .foregroundColor(Theme.Colors.warmGray)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        viewModel.saveMoment(note: note.isEmpty ? nil : note)
                        dismiss()
                    }
                    .foregroundColor(Theme.Colors.mutedRose)
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, spacing: spacing, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, spacing: spacing, subviews: subviews)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                       y: bounds.minY + result.positions[index].y),
                          proposal: .unspecified)
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []

        init(in maxWidth: CGFloat, spacing: CGFloat, subviews: Subviews) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var lineHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += lineHeight + spacing
                    lineHeight = 0
                }

                positions.append(CGPoint(x: x, y: y))
                lineHeight = max(lineHeight, size.height)
                x += size.width + spacing
            }

            self.size = CGSize(width: maxWidth, height: y + lineHeight)
        }
    }
}

#Preview {
    CaptureView()
}
