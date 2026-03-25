import Foundation
import SwiftUI

/// Service to manage Handoff between Apple devices
@Observable
final class HandoffManager: @unchecked Sendable {
    static let shared = HandoffManager()

    /// The type of view to navigate to on the receiving device
    enum HandedOffView: String {
        case pulse
        case timeline
        case capture
        case privacy
        case trustedCircle
        case socialComparison

        var activityType: String {
            switch self {
            case .pulse: return "com.pulse.app.viewPulse"
            case .timeline: return "com.pulse.app.viewTimeline"
            case .capture: return "com.pulse.app.captureMoment"
            case .privacy: return "com.pulse.app.viewPrivacy"
            case .trustedCircle: return "com.pulse.app.viewTrustedCircle"
            case .socialComparison: return "com.pulse.app.viewSocialComparison"
            }
        }

        var title: String {
            switch self {
            case .pulse: return "Pulse Dashboard"
            case .timeline: return "Emotional Timeline"
            case .capture: return "Capture Moment"
            case .privacy: return "Privacy Settings"
            case .trustedCircle: return "Trusted Circle"
            case .socialComparison: return "Compare"
            }
        }
    }

    private init() {}

    /// Create a user activity for Handoff
    func createActivity(for view: HandedOffView) -> NSUserActivity {
        let activity = NSUserActivity(activityType: view.activityType)
        activity.title = view.title
        activity.isEligibleForHandoff = true
        activity.userInfo = ["view": view.rawValue]
        return activity
    }
}
