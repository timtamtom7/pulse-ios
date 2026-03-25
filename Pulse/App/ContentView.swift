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

            CaptureView()
                .tabItem {
                    Label("Capture", systemImage: "plus.circle.fill")
                }
                .tag(2)

            PrivacyView()
                .tabItem {
                    Label("Privacy", systemImage: "lock.shield")
                }
                .tag(3)
        }
        .tint(Theme.Colors.mutedRose)
    }
}

#Preview {
    ContentView()
}
