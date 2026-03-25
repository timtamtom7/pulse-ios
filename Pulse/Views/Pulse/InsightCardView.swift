import SwiftUI

struct InsightCardView: View {
    let insight: Insight
    @State private var isExpanded = false
    @State private var appeared = false

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
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 10)

            Text(insight.body)
                .font(Theme.Typography.insightBody)
                .foregroundColor(Theme.Colors.warmGray)
                .multilineTextAlignment(.leading)
                .lineLimit(isExpanded ? nil : 2)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 10)

            if insight.supportingDataPointCount > 0 {
                HStack {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 12))
                    Text("Based on \(insight.supportingDataPointCount) moments")
                        .font(Theme.Typography.captionFont)
                }
                .foregroundColor(Theme.Colors.warmGray.opacity(0.8))
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 10)
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
            .opacity(appeared ? 1 : 0)
        }
        .padding(Theme.Spacing.cardPadding)
        .background(
            LinearGradient(
                colors: gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
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
        .onAppear {
            withAnimation(Theme.Animations.cardAppear.delay(0.1)) {
                appeared = true
            }
        }
    }

    private var gradientColors: [Color] {
        let baseColor = insightColor.opacity(0.3)
        return [baseColor, Theme.Colors.cardBackground]
    }

    private var insightColor: Color {
        switch insight.category {
        case .achievement:
            return Theme.Colors.gentleGold
        case .pattern:
            return Theme.Colors.calmSage
        case .correlation:
            return Theme.Colors.mutedRose
        case .concern:
            return Theme.Colors.dustyRose
        case .general:
            return Theme.Colors.warmGray
        }
    }
}

// R2: Animated insight card for weekly report
struct AnimatedInsightCard: View {
    let insight: Insight
    @State private var appeared = false
    @State private var gradientOffset: CGFloat = 0

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack {
                Image(systemName: insight.category.icon)
                    .foregroundColor(Theme.Colors.mutedRose)
                    .font(.system(size: 20))

                Text(insight.category.rawValue.capitalized)
                    .font(Theme.Typography.captionFont)
                    .foregroundColor(Theme.Colors.warmGray)
                    .textCase(.uppercase)

                Spacer()
            }

            Text(insight.title)
                .font(Theme.Typography.insightTitle)
                .foregroundColor(Theme.Colors.charcoal)

            Text(insight.body)
                .font(Theme.Typography.insightBody)
                .foregroundColor(Theme.Colors.warmGray)
                .lineLimit(3)

            if insight.supportingDataPointCount > 0 {
                HStack {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 12))
                    Text("\(insight.supportingDataPointCount) data points")
                        .font(Theme.Typography.captionFont)
                }
                .foregroundColor(Theme.Colors.warmGray.opacity(0.8))
            }
        }
        .padding(Theme.Spacing.cardPadding)
        .background(
            AnimatedGradientBackground(color: insightColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.card)
                .stroke(Theme.Colors.softBlush, lineWidth: 1)
        )
        .shadow(color: Theme.Colors.charcoal.opacity(0.08), radius: 16, y: 4)
        .opacity(appeared ? 1 : 0)
        .scaleEffect(appeared ? 1 : 0.95)
        .onAppear {
            withAnimation(Theme.Animations.cardAppear) {
                appeared = true
            }
        }
    }

    private var insightColor: Color {
        switch insight.category {
        case .achievement: return Theme.Colors.gentleGold
        case .pattern: return Theme.Colors.calmSage
        case .correlation: return Theme.Colors.mutedRose
        case .concern: return Theme.Colors.dustyRose
        case .general: return Theme.Colors.warmGray
        }
    }
}

struct AnimatedGradientBackground: View {
    let color: Color
    @State private var animate = false

    var body: some View {
        LinearGradient(
            colors: [color.opacity(0.2), Theme.Colors.cardBackground, color.opacity(0.1)],
            startPoint: animate ? .topLeading : .bottomTrailing,
            endPoint: animate ? .bottomTrailing : .topLeading
        )
        .onAppear {
            withAnimation(Animation.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                animate = true
            }
        }
    }
}

#Preview {
    VStack {
        InsightCardView(insight: Insight(
            title: "You feel best on Tuesdays",
            body: "Your emotional wellbeing peaks on Tuesdays. Consider scheduling important activities on this day to take advantage of your natural positivity.",
            category: .pattern,
            supportingDataPointCount: 12
        ))

        AnimatedInsightCard(insight: Insight(
            title: "Your energy is highest after exercise",
            body: "Regular physical activity correlates with significantly better emotional scores throughout the day.",
            category: .correlation,
            supportingDataPointCount: 8
        ))
    }
    .padding()
    .background(Theme.Colors.primaryBackground)
}
