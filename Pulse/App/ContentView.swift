import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
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
}

#Preview {
    ContentView()
}
