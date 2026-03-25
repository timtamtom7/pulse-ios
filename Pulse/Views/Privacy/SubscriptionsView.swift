import SwiftUI

/// R10: Subscriptions page — value-driven, not fear-based
struct SubscriptionsView: View {
    @State private var subscriptionService = SubscriptionService.shared
    @State private var selectedTier: SubscriptionService.Tier = .basic
    @State private var isPurchasing = false
    @State private var showingSuccessAlert = false
    @State private var showingRestoreAlert = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.primaryBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Theme.Spacing.lg) {
                        // Status banner
                        statusBanner

                        // Value proposition
                        valueProposition

                        // Tier cards
                        tierCards

                        // Feature comparison
                        featureComparison

                        // FAQ
                        faqSection

                        // Privacy note
                        privacyNote

                        Spacer(minLength: Theme.Spacing.xxl)
                    }
                    .padding(.top, Theme.Spacing.md)
                }
            }
            .navigationTitle("Pulse+")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task {
                            let success = await subscriptionService.restorePurchases()
                            showingRestoreAlert = true
                        }
                    } label: {
                        Text("Restore")
                            .font(Theme.Typography.captionFont)
                            .foregroundColor(Theme.Colors.primaryAccent)
                    }
                }
            }
            .alert("Restore Purchases", isPresented: $showingRestoreAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Your purchases have been restored successfully.")
            }
            .alert("Welcome to Pulse+!", isPresented: $showingSuccessAlert) {
                Button("Start Exploring") {}
            } message: {
                Text("You now have access to all Pulse+ features. Enjoy your enhanced emotional insight journey.")
            }
        }
    }

    // MARK: - Status Banner

    @ViewBuilder
    private var statusBanner: some View {
        switch subscriptionService.currentStatus {
        case .trial(let days):
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "sparkles")
                    .foregroundColor(Theme.Colors.gentleGold)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Free Trial Active")
                        .font(Theme.Typography.calloutFont)
                        .fontWeight(.semibold)
                        .foregroundColor(Theme.Colors.charcoal)

                    Text("\(days) day\(days == 1 ? "" : "s") remaining — no credit card required")
                        .font(Theme.Typography.captionFont)
                        .foregroundColor(Theme.Colors.warmGray)
                }

                Spacer()
            }
            .padding(Theme.Spacing.md)
            .background(Theme.Colors.gentleGold.opacity(0.1))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                    .stroke(Theme.Colors.gentleGold.opacity(0.3), lineWidth: 1)
            )
            .cornerRadius(Theme.CornerRadius.medium)
            .padding(.horizontal, Theme.Spacing.screenMargin)

        case .active(let tier):
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundColor(Theme.Colors.calmSage)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Pulse+ \(tier.rawValue)")
                        .font(Theme.Typography.calloutFont)
                        .fontWeight(.semibold)
                        .foregroundColor(Theme.Colors.charcoal)

                    Text("Your subscription is active")
                        .font(Theme.Typography.captionFont)
                        .foregroundColor(Theme.Colors.warmGray)
                }

                Spacer()
            }
            .padding(Theme.Spacing.md)
            .background(Theme.Colors.calmSage.opacity(0.1))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                    .stroke(Theme.Colors.calmSage.opacity(0.3), lineWidth: 1)
            )
            .cornerRadius(Theme.CornerRadius.medium)
            .padding(.horizontal, Theme.Spacing.screenMargin)

        case .lifetime:
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "crown.fill")
                    .foregroundColor(Theme.Colors.gentleGold)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Lifetime Access")
                        .font(Theme.Typography.calloutFont)
                        .fontWeight(.semibold)
                        .foregroundColor(Theme.Colors.charcoal)

                    Text("You have permanent Pulse+ Pro access")
                        .font(Theme.Typography.captionFont)
                        .foregroundColor(Theme.Colors.warmGray)
                }

                Spacer()
            }
            .padding(Theme.Spacing.md)
            .background(Theme.Colors.gentleGold.opacity(0.1))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                    .stroke(Theme.Colors.gentleGold.opacity(0.3), lineWidth: 1)
            )
            .cornerRadius(Theme.CornerRadius.medium)
            .padding(.horizontal, Theme.Spacing.screenMargin)

        case .expired:
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "clock.badge.exclamationmark")
                    .foregroundColor(Theme.Colors.mutedRose)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Trial Expired")
                        .font(Theme.Typography.calloutFont)
                        .fontWeight(.semibold)
                        .foregroundColor(Theme.Colors.charcoal)

                    Text("Upgrade to continue using all features")
                        .font(Theme.Typography.captionFont)
                        .foregroundColor(Theme.Colors.warmGray)
                }

                Spacer()
            }
            .padding(Theme.Spacing.md)
            .background(Theme.Colors.mutedRose.opacity(0.1))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                    .stroke(Theme.Colors.mutedRose.opacity(0.3), lineWidth: 1)
            )
            .cornerRadius(Theme.CornerRadius.medium)
            .padding(.horizontal, Theme.Spacing.screenMargin)
        }
    }

    // MARK: - Value Proposition

    private var valueProposition: some View {
        VStack(spacing: Theme.Spacing.md) {
            Text("Understand your emotional world")
                .font(Theme.Typography.headlineFont)
                .foregroundColor(Theme.Colors.charcoal)
                .multilineTextAlignment(.center)

            Text("Pulse+ helps you go deeper — with your family, over time, and across every emotion. No ads. No data harvesting. Just you.")
                .font(Theme.Typography.bodyFont)
                .foregroundColor(Theme.Colors.warmGray)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, Theme.Spacing.screenMargin)
    }

    // MARK: - Tier Cards

    private var tierCards: some View {
        VStack(spacing: Theme.Spacing.md) {
            ForEach(SubscriptionService.Tier.allCases) { tier in
                TierCard(
                    tier: tier,
                    isSelected: selectedTier == tier,
                    isCurrentTier: subscriptionService.currentTier == tier,
                    onSelect: { selectedTier = tier }
                )
            }
        }
        .padding(.horizontal, Theme.Spacing.screenMargin)
    }

    // MARK: - Feature Comparison

    private var featureComparison: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("What's included")
                .font(Theme.Typography.headlineFont)
                .foregroundColor(Theme.Colors.charcoal)
                .padding(.horizontal, Theme.Spacing.screenMargin)

            VStack(spacing: Theme.Spacing.sm) {
                featureRow(feature: "Daily captures", free: "3", basic: "Unlimited", pro: "Unlimited")
                featureRow(feature: "Emotion analysis", free: "Basic", basic: "Advanced AI", pro: "Advanced AI +")
                featureRow(feature: "Timeline history", free: "7 days", basic: "Unlimited", pro: "Unlimited")
                featureRow(feature: "Trusted Circle", free: "1 member", basic: "5 members", pro: "Unlimited")
                featureRow(feature: "Family Circle", free: "3 members", basic: "10 members", pro: "Unlimited")
                featureRow(feature: "Social comparison", free: "—", basic: "✓", pro: "✓")
                featureRow(feature: "Legacy export", free: "—", basic: "JSON only", pro: "PDF, JSON, MD")
                featureRow(feature: "Memorial mode", free: "—", basic: "—", pro: "✓")
            }
            .padding(.horizontal, Theme.Spacing.screenMargin)
        }
    }

    private func featureRow(feature: String, free: String, basic: String, pro: String) -> some View {
        HStack(spacing: 0) {
            Text(feature)
                .font(Theme.Typography.captionFont)
                .foregroundColor(Theme.Colors.charcoal)
                .frame(width: 100, alignment: .leading)

            Spacer()

            Text(free)
                .font(Theme.Typography.captionFont)
                .foregroundColor(free == "—" ? Theme.Colors.warmGray.opacity(0.5) : Theme.Colors.warmGray)
                .frame(width: 60)

            Text(basic)
                .font(Theme.Typography.captionFont)
                .foregroundColor(basic == "—" ? Theme.Colors.warmGray.opacity(0.5) : Theme.Colors.charcoal)
                .fontWeight(basic == "✓" ? .bold : .regular)
                .frame(width: 60)

            Text(pro)
                .font(Theme.Typography.captionFont)
                .foregroundColor(pro == "—" ? Theme.Colors.warmGray.opacity(0.5) : Theme.Colors.charcoal)
                .fontWeight(pro == "✓" ? .bold : .regular)
                .frame(width: 60)
        }
        .padding(.vertical, Theme.Spacing.xs)
    }

    // MARK: - FAQ

    private var faqSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Common questions")
                .font(Theme.Typography.headlineFont)
                .foregroundColor(Theme.Colors.charcoal)
                .padding(.horizontal, Theme.Spacing.screenMargin)

            VStack(spacing: Theme.Spacing.sm) {
                faqItem(
                    question: "Can I cancel anytime?",
                    answer: "Yes. Cancel anytime from Settings. You'll keep access until the end of your billing period."
                )

                faqItem(
                    question: "What happens to my data if I downgrade?",
                    answer: "Your moments are always yours. If you downgrade, you may lose access to some features, but your data stays safe."
                )

                faqItem(
                    question: "Is there a family plan?",
                    answer: "Pulse+ Pro includes unlimited trusted circle and family circle members. Share with as many loved ones as you want."
                )

                faqItem(
                    question: "Do you sell my data?",
                    answer: "Never. Pulse is built on privacy. We don't sell, share, or monetize your emotional data. Ever."
                )
            }
            .padding(.horizontal, Theme.Spacing.screenMargin)
        }
    }

    private func faqItem(question: String, answer: String) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text(question)
                .font(Theme.Typography.calloutFont)
                .fontWeight(.semibold)
                .foregroundColor(Theme.Colors.charcoal)

            Text(answer)
                .font(Theme.Typography.captionFont)
                .foregroundColor(Theme.Colors.warmGray)
        }
        .padding(Theme.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(Theme.CornerRadius.medium)
    }

    // MARK: - Privacy Note

    private var privacyNote: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "lock.fill")
                .foregroundColor(Theme.Colors.calmSage)
                .font(.system(size: 14))

            Text("Subscriptions are processed securely. Pulse never stores your payment details.")
                .font(Theme.Typography.captionFont)
                .foregroundColor(Theme.Colors.warmGray)
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.calmSage.opacity(0.1))
        .cornerRadius(Theme.CornerRadius.small)
        .padding(.horizontal, Theme.Spacing.screenMargin)
    }
}

// MARK: - Tier Card

struct TierCard: View {
    let tier: SubscriptionService.Tier
    let isSelected: Bool
    let isCurrentTier: Bool
    let onSelect: () -> Void

    @State private var isPurchasing = false

    private var tierColor: Color {
        switch tier {
        case .free: return Theme.Colors.warmGray
        case .basic: return Theme.Colors.gentleGold
        case .pro: return Theme.Colors.mutedRose
        }
    }

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                // Header
                HStack {
                    HStack(spacing: Theme.Spacing.sm) {
                        Image(systemName: tier.icon)
                            .foregroundColor(tierColor)

                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: Theme.Spacing.xs) {
                                Text(tier.rawValue)
                                    .font(Theme.Typography.headlineFont)
                                    .foregroundColor(Theme.Colors.charcoal)

                                if isCurrentTier {
                                    Text("Current")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(Theme.Colors.cardBackground)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(tierColor)
                                        .cornerRadius(4)
                                }
                            }

                            Text(tier.description)
                                .font(Theme.Typography.captionFont)
                                .foregroundColor(Theme.Colors.warmGray)
                        }
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text(tier.price)
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(tierColor)

                        Text(tier.period)
                            .font(Theme.Typography.captionFont)
                            .foregroundColor(Theme.Colors.warmGray)
                    }
                }

                Divider()

                // Features
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    ForEach(tier.features.prefix(4), id: \.self) { feature in
                        HStack(spacing: Theme.Spacing.sm) {
                            Image(systemName: "checkmark")
                                .foregroundColor(tierColor)
                                .font(.system(size: 10))

                            Text(feature)
                                .font(Theme.Typography.captionFont)
                                .foregroundColor(Theme.Colors.charcoal)
                        }
                    }

                    if tier.features.count > 4 {
                        Text("+\(tier.features.count - 4) more")
                            .font(Theme.Typography.captionFont)
                            .foregroundColor(Theme.Colors.warmGray)
                            .padding(.leading, Theme.Spacing.lg)
                    }
                }

                // CTA Button
                if !isCurrentTier {
                    Button {
                        purchaseTier()
                    } label: {
                        Text(isPurchasing ? "Processing..." : "Get \(tier.rawValue)")
                            .font(Theme.Typography.calloutFont)
                            .fontWeight(.semibold)
                            .foregroundColor(Theme.Colors.cardBackground)
                            .frame(maxWidth: .infinity)
                            .padding(Theme.Spacing.sm)
                            .background(tierColor)
                            .cornerRadius(Theme.CornerRadius.button)
                    }
                    .disabled(isPurchasing)
                }
            }
            .padding(Theme.Spacing.cardPadding)
            .background(Theme.Colors.cardBackground)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.card)
                    .stroke(isSelected ? tierColor : Theme.Colors.softBlush, lineWidth: isSelected ? 2 : 1)
            )
            .cornerRadius(Theme.CornerRadius.card)
        }
        .buttonStyle(.plain)
    }

    private func purchaseTier() {
        isPurchasing = true

        // Simulate purchase - in production this would call StoreKit
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            SubscriptionService.shared.activateSubscription(tier: tier)
            isPurchasing = false
        }
    }
}

#Preview {
    SubscriptionsView()
}
