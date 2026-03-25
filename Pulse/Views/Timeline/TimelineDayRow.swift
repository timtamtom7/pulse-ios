import SwiftUI

struct TimelineDayRow: View {
    let summary: DayEmotionSummary

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            // Date indicator
            VStack(spacing: 2) {
                Text(summary.dayNumber)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.Colors.charcoal)

                Text(summary.monthAbbreviation)
                    .font(Theme.Typography.captionFont)
                    .foregroundColor(Theme.Colors.warmGray)
            }
            .frame(width: 44)

            // Emotion bar
            HStack(spacing: Theme.Spacing.md) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(summary.dominantEmotionColor)
                    .frame(width: 4)

                VStack(alignment: .leading, spacing: 4) {
                    if let emotion = summary.dominantEmotion {
                        Text(emotion.label)
                            .font(Theme.Typography.bodyFont)
                            .foregroundColor(Theme.Colors.charcoal)
                    } else {
                        Text("No moments")
                            .font(Theme.Typography.bodyFont)
                            .foregroundColor(Theme.Colors.warmGray)
                    }

                    if summary.momentCount > 0 {
                        Text("\(summary.momentCount) moment\(summary.momentCount == 1 ? "" : "s")")
                            .font(Theme.Typography.captionFont)
                            .foregroundColor(Theme.Colors.warmGray)
                    }
                }

                Spacer()
            }
            .padding(Theme.Spacing.md)
            .background(Theme.Colors.cardBackground)
            .cornerRadius(Theme.CornerRadius.medium)

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Theme.Colors.warmGray)
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(Theme.CornerRadius.large)
        .shadow(color: .black.opacity(0.03), radius: 4, y: 2)
    }
}

#Preview {
    VStack {
        TimelineDayRow(summary: DayEmotionSummary(
            date: Date(),
            moments: [
                Moment(type: .journal, content: "Great day!", emotionScore: 0.8, emotionTags: [EmotionTag(category: .joy, confidence: 0.9)])
            ]
        ))
    }
    .padding()
    .background(Theme.Colors.primaryBackground)
}
