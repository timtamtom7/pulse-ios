import SwiftUI

// MARK: - Theme

enum Theme {
    // MARK: - Colors
    enum Colors {
        static let cream = Color(hex: "FDF8F3")
        static let warmWhite = Color(hex: "FFFFFF")
        static let softBlush = Color(hex: "F5E6E0")
        static let mutedRose = Color(hex: "C4706A")
        static let dustyRose = Color(hex: "A35D54")
        static let deepEmber = Color(hex: "7A3E38")
        static let warmGray = Color(hex: "8B7B74")
        static let charcoal = Color(hex: "3D3531")
        static let calmSage = Color(hex: "9CAF88")
        static let gentleGold = Color(hex: "D4A853")

        static let primaryBackground = cream
        static let cardBackground = warmWhite
        static let primaryAccent = mutedRose
        static let secondaryAccent = dustyRose
        static let primaryText = charcoal
        static let secondaryText = warmGray

        static let veryPositive = calmSage
        static let positive = gentleGold
        static let neutral = warmGray
        static let negative = mutedRose
        static let veryNegative = deepEmber

        static func emotionColor(for value: Double) -> Color {
            switch value {
            case 0.8...1.0: return veryPositive
            case 0.4..<0.8: return positive
            case -0.4..<0.4: return neutral
            case -0.8..<(-0.4): return negative
            default: return veryNegative
            }
        }

        static let emotionGradient = LinearGradient(
            colors: [mutedRose, gentleGold, calmSage],
            startPoint: .bottomLeading,
            endPoint: .topTrailing
        )
    }

    // MARK: - Typography
    enum Typography {
        static let displayFont = Font.custom("NewYork-Regular", size: 28, relativeTo: .title)
        static let titleFont = Font.system(size: 24, weight: .semibold, design: .default)
        static let headlineFont = Font.system(size: 20, weight: .semibold, design: .serif)
        static let bodyFont = Font.system(size: 16, weight: .regular)
        static let calloutFont = Font.system(size: 14, weight: .medium)
        static let captionFont = Font.system(size: 12, weight: .regular)
        static let monoFont = Font.system(size: 12, weight: .regular, design: .monospaced)

        static let insightTitle = Font.system(size: 20, weight: .semibold, design: .serif)
        static let insightBody = Font.system(size: 14, weight: .regular)
        static let emotionTagFont = Font.system(size: 12, weight: .medium)
        static let timestampFont = Font.system(size: 12, weight: .regular, design: .monospaced)
    }

    // MARK: - Spacing
    enum Spacing {
        static let base: CGFloat = 8
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48

        static let cardPadding: CGFloat = 24
        static let sectionSpacing: CGFloat = 32
        static let screenMargin: CGFloat = 20
    }

    // MARK: - CornerRadius (iOS 26 Liquid Glass)
    enum CornerRadius {
        static let extraSmall: CGFloat = 4  // Progress bars, small badges
        static let small: CGFloat = 8       // Compact elements
        static let medium: CGFloat = 12     // Buttons, tags
        static let large: CGFloat = 16      // Cards, panels
        static let extraLarge: CGFloat = 20 // Modal sheets
        // Aliases for compatibility
        static let card: CGFloat = large
        static let button: CGFloat = medium
    }

    // MARK: - Animations
    enum Animations {
        static let slowEaseInOut = Animation.easeInOut(duration: 0.5)
        static let gentleEaseOut = Animation.easeOut(duration: 0.4)
        static let breathing = Animation.easeInOut(duration: 0.6).repeatForever(autoreverses: true)
        static let pulse = Animation.easeInOut(duration: 0.3).repeatForever(autoreverses: true)
        static let springBack = Animation.spring(response: 0.3, dampingFraction: 0.6)
        static let cardAppear = Animation.easeOut(duration: 0.5)
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
