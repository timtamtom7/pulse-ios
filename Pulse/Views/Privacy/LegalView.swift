import SwiftUI

/// R10: Legal documents — Privacy Policy and Terms of Service
struct LegalView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.primaryBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Theme.Spacing.xxl) {
                        // Privacy Policy
                        legalSection(
                            icon: "lock.shield.fill",
                            title: "Privacy Policy",
                            subtitle: "Last updated: March 2026",
                            content: privacyPolicyContent
                        )

                        Divider()

                        // Terms of Service
                        legalSection(
                            icon: "doc.text.fill",
                            title: "Terms of Service",
                            subtitle: "Last updated: March 2026",
                            content: termsOfServiceContent
                        )

                        Spacer(minLength: Theme.Spacing.xxl)
                    }
                    .padding(.top, Theme.Spacing.lg)
                }
            }
            .navigationTitle("Legal")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private func legalSection(icon: String, title: String, subtitle: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: icon)
                    .foregroundColor(Theme.Colors.primaryAccent)
                    .font(.system(size: 24))

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(Theme.Typography.headlineFont)
                        .foregroundColor(Theme.Colors.charcoal)

                    Text(subtitle)
                        .font(Theme.Typography.captionFont)
                        .foregroundColor(Theme.Colors.warmGray)
                }
            }

            Text(content)
                .font(Theme.Typography.bodyFont)
                .foregroundColor(Theme.Colors.charcoal)
                .lineSpacing(4)
        }
        .padding(.horizontal, Theme.Spacing.screenMargin)
    }

    // MARK: - Privacy Policy Content

    private var privacyPolicyContent: String {
        """

        Pulse is designed with privacy at its core. This policy explains what data we collect, how we use it, and your rights.

        **1. Data We Collect**

        • Moments you capture (photos, voice notes, journal entries)
        • Emotion analysis results
        • App usage patterns (to improve the experience)
        • Device information (for technical support)

        **2. How We Use Your Data**

        • To provide emotional insight and analysis
        • To generate personalized insights
        • To sync data across your devices (optional)
        • To improve Pulse's features

        **3. What We DON'T Do**

        • We don't sell your data to advertisers
        • We don't share your emotional data with third parties
        • We don't use your data to train AI models
        • We don't show ads

        **4. Data Storage**

        • All data is stored locally on your device by default
        • Optional iCloud sync uses end-to-end encryption
        • You can delete all your data at any time

        **5. Your Rights**

        • Access: Download all your data
        • Delete: Remove all data from Pulse
        • Correct: Fix inaccurate information
        • Export: Get your data in portable formats

        **6. Children's Privacy**

        Pulse is not intended for users under 13 years of age.

        **7. Changes to This Policy**

        We may update this policy periodically. We'll notify you of significant changes.

        **8. Contact**

        For privacy concerns, contact: privacy@pulse.app

        """
    }

    // MARK: - Terms of Service Content

    private var termsOfServiceContent: String {
        """

        Welcome to Pulse. By using Pulse, you agree to these terms.

        **1. About Pulse**

        Pulse is an emotional intelligence app that helps you understand your emotional patterns. It is not a medical device and is not intended to diagnose, treat, or prevent any mental health condition.

        **2. Not Medical Advice**

        Pulse provides general wellness insights and is not a substitute for professional mental health care. If you're experiencing mental health challenges, please consult a qualified healthcare provider.

        **3. Subscription Terms**

        • Subscriptions auto-renew unless cancelled
        • Cancel anytime through your device settings
        • Refunds are subject to App Store policies
        • Pricing may change with 30 days notice

        **4. Your Content**

        You retain ownership of all content you create in Pulse. By using Pulse, you grant us a limited license to process your content to provide the service.

        **5. Acceptable Use**

        Don't use Pulse to:
        • Impersonate others
        • Violate any laws
        • Interfere with the service
        • Attempt to access other users' data

        **6. Service Availability**

        We strive to keep Pulse available, but don't guarantee uninterrupted access. We may modify or discontinue features with reasonable notice.

        **7. Disclaimer**

        Pulse is provided "as is" without warranties. We don't guarantee specific results from using Pulse.

        **8. Limitation of Liability**

        To the extent permitted by law, Pulse is not liable for indirect, incidental, or consequential damages.

        **9. Changes to Terms**

        We may update these terms. Continued use after changes constitutes acceptance.

        **10. Contact**

        Questions? Contact: legal@pulse.app

        """
    }
}

#Preview {
    LegalView()
}
