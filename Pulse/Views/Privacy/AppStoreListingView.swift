import SwiftUI

/// R10: App Store listing content and configuration
/// This view shows the App Store listing content and helps prepare for submission
struct AppStoreListingView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.primaryBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Theme.Spacing.xxl) {
                        // App Info
                        appInfoSection

                        // Description
                        descriptionSection

                        // Screenshots section
                        screenshotsSection

                        // Keywords
                        keywordsSection

                        // Marketing text
                        marketingSection

                        Spacer(minLength: Theme.Spacing.xxl)
                    }
                    .padding(.top, Theme.Spacing.lg)
                }
            }
            .navigationTitle("App Store")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: - App Info

    private var appInfoSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack(spacing: Theme.Spacing.lg) {
                // App Icon placeholder
                ZStack {
                    RoundedRectangle(cornerRadius: 18)
                        .fill(
                            LinearGradient(
                                colors: [Theme.Colors.mutedRose, Theme.Colors.dustyRose],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)

                    Image(systemName: "heart.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.white)
                }
                .shadow(color: Theme.Colors.mutedRose.opacity(0.3), radius: 12, y: 6)

                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    Text("Pulse")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(Theme.Colors.charcoal)

                    Text("Emotional Insight Engine")
                        .font(Theme.Typography.calloutFont)
                        .foregroundColor(Theme.Colors.warmGray)

                    HStack(spacing: Theme.Spacing.sm) {
                        CategoryBadge(text: "Health & Fitness")
                        CategoryBadge(text: "Lifestyle")
                    }
                }
            }

            Divider()

            // Meta info
            HStack(spacing: Theme.Spacing.xl) {
                metaItem(title: "Price", value: "Free / $9.99/mo")
                metaItem(title: "Age Rating", value: "4+")
                metaItem(title: "Category", value: "Health")
            }
        }
        .padding(Theme.Spacing.cardPadding)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(Theme.CornerRadius.card)
        .padding(.horizontal, Theme.Spacing.screenMargin)
    }

    private func metaItem(title: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(title)
                .font(Theme.Typography.captionFont)
                .foregroundColor(Theme.Colors.warmGray)
            Text(value)
                .font(Theme.Typography.calloutFont)
                .foregroundColor(Theme.Colors.charcoal)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Description

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            sectionHeader(title: "App Preview", icon: "text.alignleft")

            Text("Pulse is your private emotional intelligence companion. It reads the quiet signals in your daily life — photos, voice notes, journal entries — and surfaces patterns about your emotional world.")

            Text("Privacy is the product. No cloud, no data harvesting. Everything lives on your device, encrypted at rest.")

            Text("What Pulse helps you discover:")
                .fontWeight(.semibold)

            VStack(alignment: .leading, spacing: 4) {
                bulletPoint("When are you happiest?")
                bulletPoint("What triggers stress?")
                bulletPoint("How do your emotions change over time?")
                bulletPoint("What brings you energy vs. drains it?")
            }

            Text("Features:")
                .fontWeight(.semibold)

            VStack(alignment: .leading, spacing: 4) {
                bulletPoint("Capture emotions through photos, voice, or text")
                bulletPoint("AI-powered emotion analysis (on-device)")
                bulletPoint("Social comparison with anonymized insights")
                bulletPoint("Family circle — share wellness with loved ones")
                bulletPoint("Emotional forecast — predict your week ahead")
                bulletPoint("Legacy export — your complete emotional history")
            }

            Text("The experience feels like a personal diary that breathes — warm, unhurried, gentle. It's not another productivity tool. It's a space that understands you.")
        }
        .font(Theme.Typography.bodyFont)
        .foregroundColor(Theme.Colors.charcoal)
        .padding(Theme.Spacing.cardPadding)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(Theme.CornerRadius.card)
        .padding(.horizontal, Theme.Spacing.screenMargin)
    }

    private func bulletPoint(_ text: String) -> some View {
        HStack(alignment: .top, spacing: Theme.Spacing.sm) {
            Text("•")
            Text(text)
        }
    }

    // MARK: - Screenshots

    private var screenshotsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            sectionHeader(title: "Screenshots Required", icon: "iphone")

            Text("6 screenshots for each device size:")
                .font(Theme.Typography.calloutFont)
                .foregroundColor(Theme.Colors.charcoal)

            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                screenshotRequirement(
                    device: "iPhone 6.7\"",
                    description: "1290 x 2796 px (iPhone 14 Pro Max)"
                )
                screenshotRequirement(
                    device: "iPhone 6.5\"",
                    description: "1284 x 2778 px (iPhone 11 Pro Max)"
                )
                screenshotRequirement(
                    device: "iPhone 5.5\"",
                    description: "1242 x 2208 px (iPhone 8 Plus)"
                )
                screenshotRequirement(
                    device: "iPad Pro 12.9\"",
                    description: "2048 x 2732 px (iPad Pro)"
                )
                screenshotRequirement(
                    device: "iPad Pro 11\"",
                    description: "1668 x 2388 px (iPad Pro)"
                )
            }

            Divider()

            Text("Screenshot Guide:")
                .font(Theme.Typography.calloutFont)
                .fontWeight(.semibold)
                .foregroundColor(Theme.Colors.charcoal)

            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                screenshotTip("Pulse dashboard with insight card")
                screenshotTip("Emotional timeline view")
                screenshotTip("Moment capture (photo, voice, journal)")
                screenshotTip("Social comparison screen")
                screenshotTip("Family/trusted circle view")
                screenshotTip("Privacy settings (privacy-focused messaging)")
            }
        }
        .padding(Theme.Spacing.cardPadding)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(Theme.CornerRadius.card)
        .padding(.horizontal, Theme.Spacing.screenMargin)
    }

    private func screenshotRequirement(device: String, description: String) -> some View {
        HStack(spacing: Theme.Spacing.md) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(Theme.Colors.calmSage)

            VStack(alignment: .leading, spacing: 2) {
                Text(device)
                    .font(Theme.Typography.calloutFont)
                    .foregroundColor(Theme.Colors.charcoal)

                Text(description)
                    .font(Theme.Typography.captionFont)
                    .foregroundColor(Theme.Colors.warmGray)
            }
        }
    }

    private func screenshotTip(_ text: String) -> some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "arrow.right")
                .foregroundColor(Theme.Colors.primaryAccent)
                .font(.system(size: 11))

            Text(text)
                .font(Theme.Typography.captionFont)
                .foregroundColor(Theme.Colors.charcoal)
        }
    }

    // MARK: - Keywords

    private var keywordsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            sectionHeader(title: "App Store Keywords", icon: "tag.fill")

            Text("100 character limit per keyword group")
                .font(Theme.Typography.calloutFont)
                .foregroundColor(Theme.Colors.charcoal)

            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                keywordGroup(title: "Primary", keywords: "mood tracker, emotion journal, mental health, feelings diary, self care, wellness")
                keywordGroup(title: "Secondary", keywords: "emotional intelligence, stress management, mindfulness, gratitude, journaling, reflection")
                keywordGroup(title: "Competitor", keywords: "daylio, bearable, moodflow, eCBT, betterhelp")
            }
        }
        .padding(Theme.Spacing.cardPadding)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(Theme.CornerRadius.card)
        .padding(.horizontal, Theme.Spacing.screenMargin)
    }

    private func keywordGroup(title: String, keywords: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(Theme.Typography.captionFont)
                .foregroundColor(Theme.Colors.warmGray)

            Text(keywords)
                .font(Theme.Typography.captionFont)
                .foregroundColor(Theme.Colors.charcoal)
        }
    }

    // MARK: - Marketing

    private var marketingSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            sectionHeader(title: "Marketing URL", icon: "link")

            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                marketingURL(title: "Marketing URL", url: "https://pulse.app/landing")
                marketingURL(title: "Privacy Policy URL", url: "https://pulse.app/privacy")
                marketingURL(title: "Support URL", url: "https://pulse.app/support")
            }
        }
        .padding(Theme.Spacing.cardPadding)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(Theme.CornerRadius.card)
        .padding(.horizontal, Theme.Spacing.screenMargin)
    }

    private func marketingURL(title: String, url: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(Theme.Typography.captionFont)
                .foregroundColor(Theme.Colors.warmGray)

            Text(url)
                .font(Theme.Typography.calloutFont)
                .foregroundColor(Theme.Colors.primaryAccent)
        }
    }

    // MARK: - Helpers

    private func sectionHeader(title: String, icon: String) -> some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: icon)
                .foregroundColor(Theme.Colors.primaryAccent)

            Text(title)
                .font(Theme.Typography.headlineFont)
                .foregroundColor(Theme.Colors.charcoal)
        }
    }
}

struct CategoryBadge: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(Theme.Colors.mutedRose)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Theme.Colors.softBlush)
            .cornerRadius(Theme.CornerRadius.small)
    }
}

#Preview {
    AppStoreListingView()
}
