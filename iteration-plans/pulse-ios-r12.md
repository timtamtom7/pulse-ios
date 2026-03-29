# Pulse iOS — R12: Private Sharing

## Goal
Allow users to share emotional moments and insights with trusted friends and family — anonymously, with end-to-end encryption, and full user control over what is shared.

---

## Scope

### Anonymous Mood Sharing
- Share a single moment (photo, voice, or journal) as an anonymous signal to opted-in friends
- Broadcasts: emotion tag + intensity + timestamp (no text content, no name)
- Opt-in only: both sender and recipient must mutually follow
- `MoodSharingService`: handles tokenization (pseudonymous user IDs), cryptographic key exchange for E2E

### Friends Feed
- `FriendsFeedView`: scrollable feed of anonymous mood signals from friends
- Each entry: emotion color ring, day, "feeling [emotion]" — no identifying info
- Tap to reveal: see the day/time pattern of that friend's mood (still no name)
- Pagination: newest first, load 20 at a time

### Mood Chain
- Share current mood → see how many others feel the same right now
- Mutual opt-in gate: reveal one anonymized match ("Someone in your Mood Chain is also feeling hopeful")
- Optional: connect anonymously via in-app text chat (no phone number, no real name)
- Minimum group size of 3 before any signal is broadcast (differential privacy)

### Data Source Permissions
- `PermissionService`: PhotoKit, EventKit, Speech permission flows
- Clear explainer screens before each permission request
- Disconnect option with data purge confirmation

### Privacy Dashboard
- `PrivacyView`: data summary ("Pulse knows X photos, Y voice notes, Z journal entries")
- Connected sources status badges
- Export data as JSON (share sheet)
- Delete all data (double confirmation)
- Privacy Score meter: encryption status, data minimization, sync status

---

## Out of Scope
- Real-time location sharing
- Social media cross-posting
- Public leaderboards
- Any data leaves device without E2E encryption

---

## Dependencies
- `Pulse/Services/MoodSharingService` (new)
- `Pulse/Views/Privacy/PrivacyView.swift` (existing shell)
- `Pulse/Views/Privacy/DataSourcesView.swift` (existing shell)
- `Pulse/ViewModels/PrivacyViewModel.swift` (existing shell)
- CloudKit container for sync (configured, not yet active)

## Verification
- Build passes
- Privacy view shows correct data counts from SQLite
- Permission request flows shown but do not require real permissions in CI
- Export produces valid JSON with all stored moments
