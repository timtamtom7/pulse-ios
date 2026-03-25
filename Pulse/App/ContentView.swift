import SwiftUI
import UIKit

struct ContentView: View {
    @State private var selectedTab = 0
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    var body: some View {
        Group {
            if UIDevice.current.userInterfaceIdiom == .pad {
                iPadContentView
            } else {
                iPhoneContentView
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .openPulseTab)) { _ in
            selectedTab = 0
        }
        .onReceive(NotificationCenter.default.publisher(for: .openTimelineTab)) { _ in
            selectedTab = 1
        }
        .onReceive(NotificationCenter.default.publisher(for: .openCaptureTab)) { _ in
            selectedTab = 3
        }
    }

    private var iPhoneContentView: some View {
        TabView(selection: $selectedTab) {
            PulseView()
                .tabItem {
                    Label("Pulse", systemImage: "heart.fill")
                }
                .tag(0)

            TimelineView()
                .tabItem {
                    Label("Timeline", systemImage: "calendar")
                }
                .tag(1)

            // R4: Social Comparison tab
            SocialComparisonView()
                .tabItem {
                    Label("Compare", systemImage: "person.3.fill")
                }
                .tag(2)

            CaptureView()
                .tabItem {
                    Label("Capture", systemImage: "plus.circle.fill")
                }
                .tag(3)

            PrivacyView()
                .tabItem {
                    Label("Privacy", systemImage: "lock.shield")
                }
                .tag(4)
        }
        .tint(Theme.Colors.mutedRose)
    }

    private var iPadContentView: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            // Sidebar
            List {
                NavigationLink(destination: PulseView()) {
                    Label("Pulse", systemImage: "heart.fill")
                }

                NavigationLink(destination: TimelineView()) {
                    Label("Timeline", systemImage: "calendar")
                }

                NavigationLink(destination: SocialComparisonView()) {
                    Label("Compare", systemImage: "person.3.fill")
                }

                NavigationLink(destination: CaptureView()) {
                    Label("Capture", systemImage: "plus.circle.fill")
                }

                NavigationLink(destination: PrivacyView()) {
                    Label("Privacy", systemImage: "lock.shield")
                }

                NavigationLink(destination: TrustedCircleView()) {
                    Label("Trusted Circle", systemImage: "figure.2.and.child.holdinghands")
                }
            }
            .navigationTitle("Pulse")
            .navigationSplitViewColumnWidth(min: 220, ideal: 260, max: 300)
        } detail: {
            // Detail column
            NavigationStack {
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
                .navigationTitle("Pulse")
                .navigationBarTitleDisplayMode(.large)
            }
        }
        .tint(Theme.Colors.mutedRose)
    }
}

#Preview {
    ContentView()
}
