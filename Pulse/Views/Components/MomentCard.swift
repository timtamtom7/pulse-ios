import SwiftUI

struct MomentCard: View {
    let moment: Moment
    var showDate: Bool = true

    private var dominantEmotion: EmotionTag? {
        moment.emotionTags.max(by: { $0.confidence < $1.confidence })
    }

    private var accentColor: Color {
        dominantEmotion?.color ?? Theme.Colors.warmGray
    }

    // R2: Waveform visualization for voice
    @State private var waveformHeights: [CGFloat] = []

    var body: some View {
        HStack(spacing: 0) {
            // Left accent bar
            RoundedRectangle(cornerRadius: 2)
                .fill(accentColor)
                .frame(width: 4)

            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                HStack {
                    Image(systemName: moment.type.icon)
                        .font(.system(size: 16))
                        .foregroundColor(accentColor)

                    Text(moment.type.displayName)
                        .font(Theme.Typography.bodyFont)
                        .foregroundColor(Theme.Colors.charcoal)

                    Spacer()

                    Text(showDate ? moment.formattedDate : moment.formattedTime)
                        .font(Theme.Typography.timestampFont)
                        .foregroundColor(Theme.Colors.warmGray)
                }

                // Content preview based on type
                contentView

                // R2: Voice waveform visualization
                if moment.type == .voice && !moment.content.isEmpty {
                    VoiceWaveformView(content: moment.content, color: accentColor)
                }

                // Emotion tags
                if !moment.emotionTags.isEmpty {
                    HStack(spacing: Theme.Spacing.xs) {
                        ForEach(moment.emotionTags.prefix(3)) { tag in
                            EmotionTagView(tag: tag)
                        }

                        if moment.emotionTags.count > 3 {
                            Text("+\(moment.emotionTags.count - 3)")
                                .font(Theme.Typography.captionFont)
                                .foregroundColor(Theme.Colors.warmGray)
                        }
                    }
                }

                // Optional note
                if let note = moment.note, !note.isEmpty {
                    Text(note)
                        .font(Theme.Typography.captionFont)
                        .foregroundColor(Theme.Colors.warmGray)
                        .italic()
                        .padding(.top, Theme.Spacing.xs)
                }

                // R2: Emotion score indicator
                emotionScoreBar
            }
            .padding(Theme.Spacing.md)
        }
        .background(Theme.Colors.cardBackground)
        .cornerRadius(Theme.CornerRadius.card)
        .shadow(color: .black.opacity(0.04), radius: 8, y: 4)
        .onAppear {
            generateWaveformIfNeeded()
        }
    }

    @ViewBuilder
    private var contentView: some View {
        switch moment.type {
        case .photo:
            if let data = Data(base64Encoded: moment.content),
               let image = UIImage(data: data) {
                // R2: Photo with scene context overlay
                ZStack(alignment: .bottomLeading) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 120)
                        .clipped()
                        .cornerRadius(Theme.CornerRadius.small)

                    // R2: Scene type badge
                    if let dominant = dominantEmotion {
                        Text(dominant.label)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(accentColor.opacity(0.8))
                            .cornerRadius(Theme.CornerRadius.extraSmall)
                            .padding(6)
                    }
                }
            }
        case .voice:
            // R2: Transcript preview with speaker indicator
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                HStack(spacing: 4) {
                    Image(systemName: "quote.opening")
                        .font(.system(size: 11))
                        .foregroundColor(Theme.Colors.warmGray)
                    Text("Transcript")
                        .font(Theme.Typography.captionFont)
                        .foregroundColor(Theme.Colors.warmGray)
                        .textCase(.uppercase)
                }

                Text(moment.content)
                    .font(Theme.Typography.bodyFont)
                    .foregroundColor(Theme.Colors.charcoal)
                    .lineLimit(3)
            }
            .padding(Theme.Spacing.sm)
            .background(Theme.Colors.softBlush.opacity(0.5))
            .cornerRadius(Theme.CornerRadius.small)

        case .journal:
            Text(moment.content)
                .font(Theme.Typography.bodyFont)
                .foregroundColor(Theme.Colors.charcoal)
                .lineLimit(2)
        }
    }

    @ViewBuilder
    private var emotionScoreBar: some View {
        HStack(spacing: Theme.Spacing.xs) {
            Text("Mood")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(Theme.Colors.warmGray)

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.extraSmall)
                        .fill(Theme.Colors.softBlush)
                        .frame(height: 4)

                    RoundedRectangle(cornerRadius: Theme.CornerRadius.extraSmall)
                        .fill(accentColor)
                        .frame(width: geometry.size.width * CGFloat((moment.emotionScore + 1) / 2), height: 4)
                }
            }
            .frame(height: 4)

            Text(String(format: "%.0f%%", (moment.emotionScore + 1) / 2 * 100))
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(accentColor)
                .frame(width: 36, alignment: .trailing)
        }
    }

    private func generateWaveformIfNeeded() {
        guard moment.type == .voice else { return }
        // Generate pseudo-random waveform from content
        let seed = moment.content.hashValue
        var rng = SeededRandomNumberGenerator(seed: UInt64(abs(seed)))
        waveformHeights = (0..<30).map { _ in CGFloat.random(in: 0.2...1.0, using: &rng) }
    }
}

// R2: Voice waveform visualization
struct VoiceWaveformView: View {
    let content: String
    let color: Color

    @State private var animatedHeights: [CGFloat] = []
    private let barCount = 25

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<barCount, id: \.self) { index in
                RoundedRectangle(cornerRadius: 1)
                    .fill(color.opacity(0.6))
                    .frame(width: 3, height: animatedHeights.indices.contains(index) ? animatedHeights[index] * 24 : 8)
            }
        }
        .frame(height: 24)
        .onAppear {
            generateWaveform()
            animateWaveform()
        }
    }

    private func generateWaveform() {
        let seed = content.hashValue
        var rng = SeededRandomNumberGenerator(seed: UInt64(abs(seed)))
        animatedHeights = (0..<barCount).map { _ in CGFloat.random(in: 0.15...1.0, using: &rng) }
    }

    private func animateWaveform() {
        withAnimation(Animation.easeInOut(duration: 0.6)) {
            // Initial animation
        }
    }
}

// Seeded random number generator for consistent waveform
struct SeededRandomNumberGenerator: RandomNumberGenerator {
    var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return state
    }
}

#Preview {
    VStack {
        MomentCard(moment: Moment(
            type: .journal,
            content: "Had a wonderful day at the park with friends. The weather was perfect and I felt so at peace.",
            emotionScore: 0.8,
            emotionTags: [
                EmotionTag(category: .joy, confidence: 0.9),
                EmotionTag(category: .trust, confidence: 0.7)
            ],
            note: "Remember this feeling"
        ))

        MomentCard(moment: Moment(
            type: .voice,
            content: "Feeling a bit anxious about the upcoming presentation but excited to share our work with the team.",
            emotionScore: 0.2,
            emotionTags: [
                EmotionTag(category: .fear, confidence: 0.6),
                EmotionTag(category: .anticipation, confidence: 0.5)
            ]
        ))
    }
    .padding()
    .background(Theme.Colors.primaryBackground)
}
