import SwiftUI

@main
struct PulseMacApp: App {
    var body: some Scene {
        WindowGroup {
            MacContentView()
        }
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified)
    }
}

struct MacContentView: View {
    @State private var selectedSection: MacSection? = .pulse
    @State private var viewModel = PulseViewModel()

    enum MacSection: String, CaseIterable {
        case pulse = "Pulse"
        case timeline = "Timeline"
        case capture = "Capture"
        case privacy = "Privacy"
        case trustedCircle = "Trusted Circle"
        case compare = "Compare"

        var icon: String {
            switch self {
            case .pulse: return "heart.fill"
            case .timeline: return "calendar"
            case .capture: return "plus.circle.fill"
            case .privacy: return "lock.shield"
            case .trustedCircle: return "figure.2.and.child.holdinghands"
            case .compare: return "person.3.fill"
            }
        }
    }

    var body: some View {
        NavigationSplitView {
            // Sidebar
            List(selection: $selectedSection) {
                ForEach(MacSection.allCases, id: \.self) { section in
                    NavigationLink(value: section) {
                        Label(section.rawValue, systemImage: section.icon)
                    }
                }
            }
            .navigationSplitViewColumnWidth(min: 180, ideal: 220, max: 280)
            .navigationTitle("Pulse")
        } detail: {
            // Detail view
            if let section = selectedSection {
                detailView(for: section)
            } else {
                emptyDetailView
            }
        }
        .tint(Theme.Colors.mutedRose)
    }

    @ViewBuilder
    private func detailView(for section: MacSection) -> some View {
        switch section {
        case .pulse:
            PulseView()
        case .timeline:
            TimelineView()
        case .capture:
            CaptureView()
        case .privacy:
            PrivacyView()
        case .trustedCircle:
            TrustedCircleView()
        case .compare:
            SocialComparisonView()
        }
    }

    private var emptyDetailView: some View {
        ZStack {
            Theme.Colors.primaryBackground.ignoresSafeArea()
            VStack(spacing: Theme.Spacing.lg) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 72))
                    .foregroundColor(Theme.Colors.mutedRose.opacity(0.2))
                Text("Select a view from the sidebar")
                    .font(.title3)
                    .foregroundColor(Theme.Colors.secondaryText)
            }
        }
    }
}

#Preview {
    MacContentView()
}
