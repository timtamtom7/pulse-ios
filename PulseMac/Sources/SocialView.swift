import SwiftUI

/// Wrapper view for the Social tab containing Mood Chains and Friends Feed
struct SocialView: View {
    @Binding var selectedSubTab: MacContentView.SocialSubTab

    var body: some View {
        VStack(spacing: 0) {
            // Sub-tab picker
            Picker("Social", selection: $selectedSubTab) {
                ForEach(MacContentView.SocialSubTab.allCases, id: \.self) { tab in
                    Label(tab.rawValue, systemImage: tab.icon)
                        .tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, MacTheme.Spacing.lg)
            .padding(.vertical, MacTheme.Spacing.md)
            .background(MacTheme.Colors.warmWhite)

            Divider()

            // Content
            Group {
                switch selectedSubTab {
                case .moodChains:
                    MoodChainsView()
                case .friendsFeed:
                    MacFriendsFeedView()
                }
            }
        }
    }
}

#Preview {
    SocialView(selectedSubTab: .constant(.moodChains))
}
