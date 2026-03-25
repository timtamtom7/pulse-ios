import SwiftUI

@main
struct PulseApp: App {
    @State private var databaseService = DatabaseService.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(databaseService)
        }
    }
}
