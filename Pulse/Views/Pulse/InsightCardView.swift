import SwiftUI

struct InsightCardView: View {
    let insight: Insight
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack {
                Image(systemName: insight.category.icon)
                    .foregroundColor(Theme.Colors.mutedRose)
                    .font(.system(size: 20))

                Text("Insight of the Week")
                    .font(Theme.Typography.captionFont)
                    .foregroundColor(Theme.Colors.warmGray)
                    .textCase(.uppercase)
                    .tracking(1)

                Spacer()
            }

            Text(insight.title)
                .font(Theme.Typography.insightTitle)
                .foregroundColor(Theme.Colors.charcoal)
                .multilineTextAlignment(.leading)

            Text(insight.body)
                .font(Theme.Typography.insightBody)
                .foregroundColor(Theme.Colors.warmGray)
                .multilineTextAlignment(.leading)
                .lineLimit(isExpanded ? nil : 2)

            if insight.supportingDataPointCount > 0 {
                HStack {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 12))
                    Text("Based on \(insight.supportingDataPointCount) moments")
                        .font(Theme.Typography.captionFont)
                }
                .foregroundColor(Theme.Colors.warmGray.opacity(0.8))
            }

            Button {
                withAnimation(Theme.Animations.slowEaseInOut) {
                    isExpanded.toggle()
                }
            } label: {
                Text(isExpanded ? "Show less" : "Read more")
                    .font(Theme.Typography.captionFont)
                    .foregroundColor(Theme.Colors.mutedRose)
            }
        }
        .padding(Theme.Spacing.cardPadding)
        .background(
            LinearGradient(
                colors: [Theme.Colors.softBlush.opacity(0.5), Theme.Colors.cardBackground],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(Theme.CornerRadius.card)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.card)
                .stroke(Theme.Colors.softBlush, lineWidth: 1)
        )
        .shadow(color: Theme.Colors.charcoal.opacity(0.08), radius: 16, y: 4)
        .onTapGesture {
            withAnimation(Theme.Animations.slowEaseInOut) {
                isExpanded.toggle()
            }
        }
    }
}

#Preview {
    InsightCardView(insight: Insight(
        title: "You feel best on Tuesdays",
        body: "Your emotional wellbeing peaks on Tuesdays. Consider scheduling important activities on this day to take advantage of your natural positivity.",
        category: .pattern,
        supportingDataPointCount: 12
    ))
    .padding()
    .background(Theme.Colors.primaryBackground)
}
