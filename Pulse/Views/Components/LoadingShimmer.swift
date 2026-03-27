import SwiftUI

struct LoadingShimmer: View {
    @State private var isAnimating = false

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            // Icon row
            HStack {
                Circle()
                    .fill(Theme.Colors.softBlush)
                    .frame(width: 24, height: 24)

                RoundedRectangle(cornerRadius: Theme.CornerRadius.extraSmall)
                    .fill(Theme.Colors.softBlush)
                    .frame(width: 100, height: 12)
            }

            // Title
            RoundedRectangle(cornerRadius: Theme.CornerRadius.extraSmall)
                .fill(Theme.Colors.softBlush)
                .frame(height: 24)

            // Body lines
            RoundedRectangle(cornerRadius: Theme.CornerRadius.extraSmall)
                .fill(Theme.Colors.softBlush)
                .frame(height: 16)

            RoundedRectangle(cornerRadius: Theme.CornerRadius.extraSmall)
                .fill(Theme.Colors.softBlush)
                .frame(width: 200, height: 16)

            // Footer
            HStack {
                Circle()
                    .fill(Theme.Colors.softBlush)
                    .frame(width: 16, height: 16)

                RoundedRectangle(cornerRadius: Theme.CornerRadius.extraSmall)
                    .fill(Theme.Colors.softBlush)
                    .frame(width: 120, height: 12)
            }
        }
        .padding(Theme.Spacing.cardPadding)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(Theme.CornerRadius.card)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.card)
                .fill(
                    LinearGradient(
                        colors: [
                            Theme.Colors.cream.opacity(0),
                            Theme.Colors.cream.opacity(0.4),
                            Theme.Colors.cream.opacity(0)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .mask(
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.card)
                )
                .offset(x: isAnimating ? 400 : -400)
        )
        .onAppear {
            withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                isAnimating = true
            }
        }
    }
}

#Preview {
    VStack {
        LoadingShimmer()
            .frame(height: 180)
    }
    .padding()
    .background(Theme.Colors.primaryBackground)
}
