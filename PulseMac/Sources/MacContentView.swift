import SwiftUI

struct MacContentView: View {
    @State private var selectedTab: MacTab = .insights
    @State private var viewModel = PulseViewModel()
    @State private var timelineViewModel = TimelineViewModel()
    @State private var captureViewModel = CaptureViewModel()

    enum MacTab: String, CaseIterable {
        case insights = "Insights"
        case timeline = "Timeline"
        case capture = "Capture"
        case settings = "Settings"

        var icon: String {
            switch self {
            case .insights: return "heart.fill"
            case .timeline: return "calendar"
            case .capture: return "plus.circle.fill"
            case .settings: return "gearshape.fill"
            }
        }
    }

    var body: some View {
        NavigationSplitView {
            sidebarView
        } detail: {
            detailView
        }
        .frame(minWidth: 900, minHeight: 600)
        .background(MacTheme.Colors.cream)
    }

    private var sidebarView: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 32))
                    .foregroundColor(MacTheme.Colors.mutedRose)

                Text("Pulse")
                    .font(.system(size: 20, weight: .semibold, design: .serif))
                    .foregroundColor(MacTheme.Colors.charcoal)

                Text("Emotional Insight")
                    .font(.system(size: 11))
                    .foregroundColor(MacTheme.Colors.warmGray)
            }
            .padding(.vertical, 24)

            Divider()

            // Tab list
            VStack(spacing: 4) {
                ForEach(MacTab.allCases, id: \.self) { tab in
                    Button {
                        withAnimation(MacTheme.Animations.gentleEaseOut) {
                            selectedTab = tab
                        }
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 16))
                                .frame(width: 24)

                            Text(tab.rawValue)
                                .font(.system(size: 14, weight: .medium))

                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            selectedTab == tab
                            ? MacTheme.Colors.mutedRose.opacity(0.12)
                            : Color.clear
                        )
                        .foregroundColor(
                            selectedTab == tab
                            ? MacTheme.Colors.mutedRose
                            : MacTheme.Colors.warmGray
                        )
                        .cornerRadius(MacTheme.CornerRadius.medium)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(tab.rawValue) tab")
                    .accessibilityHint("Switch to \(tab.rawValue) view")
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 16)

            Spacer()

            // Footer
            VStack(spacing: 4) {
                Divider()
                HStack {
                    Circle()
                        .fill(MacTheme.Colors.calmSage)
                        .frame(width: 8, height: 8)
                    Text("Private & Local")
                        .font(.system(size: 11))
                        .foregroundColor(MacTheme.Colors.warmGray)
                }
                .padding(.vertical, 12)
            }
        }
        .frame(width: 220)
        .background(MacTheme.Colors.warmWhite)
    }

    @ViewBuilder
    private var detailView: some View {
        switch selectedTab {
        case .insights:
            MacInsightsView(viewModel: viewModel)
        case .timeline:
            MacTimelineView(viewModel: timelineViewModel)
        case .capture:
            MacCaptureView(viewModel: captureViewModel)
        case .settings:
            MacSettingsView()
        }
    }
}

#Preview {
    MacContentView()
}
