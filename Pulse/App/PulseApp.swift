import SwiftUI

@main
struct PulseApp: App {
    @UIApplicationDelegateAdaptor(PulseAppDelegate.self) var appDelegate
    @State private var databaseService = DatabaseService.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(databaseService)
        }
    }
}

class PulseAppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        guard let viewString = userActivity.userInfo?["view"] as? String else {
            return false
        }

        switch viewString {
        case "pulse":
            NotificationCenter.default.post(name: .openPulseTab, object: nil)
        case "timeline":
            NotificationCenter.default.post(name: .openTimelineTab, object: nil)
        case "capture":
            NotificationCenter.default.post(name: .openCaptureTab, object: nil)
        case "privacy":
            NotificationCenter.default.post(name: .openPrivacyTab, object: nil)
        default:
            return false
        }

        return true
    }
}

extension Notification.Name {
    static let openPulseTab = Notification.Name("openPulseTab")
    static let openTimelineTab = Notification.Name("openTimelineTab")
    static let openCaptureTab = Notification.Name("openCaptureTab")
    static let openPrivacyTab = Notification.Name("openPrivacyTab")
    static let openFamilyTab = Notification.Name("openFamilyTab")
}
