import SwiftUI

struct PulseButton: View {
    let title: String
    let icon: String
    var isDisabled: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))

                Text(title)
                    .font(Theme.Typography.bodyFont)
                    .fontWeight(.medium)
            }
            .foregroundColor(.white)
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.vertical, Theme.Spacing.md)
            .background(
                LinearGradient(
                    colors: isDisabled
                        ? [Theme.Colors.warmGray, Theme.Colors.warmGray.opacity(0.8)]
                        : [Theme.Colors.mutedRose, Theme.Colors.dustyRose],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(Theme.CornerRadius.button)
            .shadow(
                color: isDisabled
                    ? .clear
                    : Theme.Colors.mutedRose.opacity(0.3),
                radius: 8,
                y: 4
            )
        }
        .disabled(isDisabled)
        .scaleEffect(isDisabled ? 1.0 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isDisabled)
    }
}

#Preview {
    VStack(spacing: 20) {
        PulseButton(title: "Capture", icon: "camera.fill") {}
        PulseButton(title: "Analyze", icon: "sparkles") {}
        PulseButton(title: "Disabled", icon: "lock.fill", isDisabled: true) {}
    }
    .padding()
    .background(Theme.Colors.primaryBackground)
}
