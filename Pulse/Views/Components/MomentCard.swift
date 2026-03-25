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

                // Content preview
                if moment.type == .photo {
                    if let data = Data(base64Encoded: moment.content),
                       let image = UIImage(data: data) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 120)
                            .clipped()
                            .cornerRadius(Theme.CornerRadius.small)
                    }
                } else {
                    Text(moment.content)
                        .font(Theme.Typography.bodyFont)
                        .foregroundColor(Theme.Colors.charcoal)
                        .lineLimit(2)
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
            }
            .padding(Theme.Spacing.md)
        }
        .background(Theme.Colors.cardBackground)
        .cornerRadius(Theme.CornerRadius.card)
        .shadow(color: .black.opacity(0.04), radius: 8, y: 4)
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
            content: "Feeling a bit anxious about the upcoming presentation but excited to share our work.",
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
