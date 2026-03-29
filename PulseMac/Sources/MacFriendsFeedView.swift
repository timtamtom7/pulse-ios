import SwiftUI

/// View for friends' mood updates - shows what friends in Pulse are feeling
struct MacFriendsFeedView: View {
    @State private var friendUpdates: [FriendMoodUpdate] = []
    @State private var isLoading = true
    @State private var hasFriends = false
    @State private var showingAddFriends = false

    private let moodService = MoodSharingService.shared

    var body: some View {
        ScrollView {
            VStack(spacing: MacTheme.Spacing.lg) {
                headerSection

                if isLoading {
                    loadingView
                } else if !hasFriends {
                    noFriendsView
                } else if friendUpdates.isEmpty {
                    emptyFeedView
                } else {
                    friendsListSection
                }
            }
            .padding(MacTheme.Spacing.lg)
        }
        .background(MacTheme.Colors.cream)
        .navigationTitle("Friends Feed")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddFriends = true
                } label: {
                    Label("Add Friends", systemImage: "person.badge.plus")
                }
                .buttonStyle(.bordered)
            }
        }
        .sheet(isPresented: $showingAddFriends) {
            AddFriendsSheet(hasFriends: $hasFriends)
        }
        .task {
            await loadFriendsFeed()
        }
        .refreshable {
            await loadFriendsFeed()
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: MacTheme.Spacing.sm) {
            Text("How your friends are feeling")
                .font(MacTheme.Typography.headlineFont)
                .foregroundColor(MacTheme.Colors.charcoal)

            Text("Updates from friends who've opted into sharing their mood")
                .font(MacTheme.Typography.bodyFont)
                .foregroundColor(MacTheme.Colors.warmGray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Loading

    private var loadingView: some View {
        VStack(spacing: MacTheme.Spacing.md) {
            ProgressView()
            Text("Loading friends...")
                .font(MacTheme.Typography.captionFont)
                .foregroundColor(MacTheme.Colors.warmGray)
        }
        .frame(height: 200)
        .frame(maxWidth: .infinity)
    }

    // MARK: - No Friends

    private var noFriendsView: some View {
        VStack(spacing: MacTheme.Spacing.lg) {
            Image(systemName: "person.2.slash")
                .font(.system(size: 48))
                .foregroundColor(MacTheme.Colors.warmGray.opacity(0.5))

            VStack(spacing: MacTheme.Spacing.sm) {
                Text("No friends yet")
                    .font(MacTheme.Typography.headlineFont)
                    .foregroundColor(MacTheme.Colors.charcoal)

                Text("Add friends to your trusted circle to see their mood updates")
                    .font(MacTheme.Typography.bodyFont)
                    .foregroundColor(MacTheme.Colors.warmGray)
                    .multilineTextAlignment(.center)
            }

            Button {
                showingAddFriends = true
            } label: {
                Label("Add Friends", systemImage: "person.badge.plus")
            }
            .buttonStyle(.borderedProminent)
            .tint(MacTheme.Colors.mutedRose)
        }
        .padding(MacTheme.Spacing.xl)
        .frame(maxWidth: .infinity)
        .background(MacTheme.Colors.warmWhite)
        .cornerRadius(MacTheme.CornerRadius.card)
    }

    // MARK: - Empty Feed

    private var emptyFeedView: some View {
        VStack(spacing: MacTheme.Spacing.lg) {
            Image(systemName: "tray")
                .font(.system(size: 48))
                .foregroundColor(MacTheme.Colors.warmGray.opacity(0.5))

            VStack(spacing: MacTheme.Spacing.sm) {
                Text("No updates yet")
                    .font(MacTheme.Typography.headlineFont)
                    .foregroundColor(MacTheme.Colors.charcoal)

                Text("Your friends haven't shared their mood recently. Check back soon!")
                    .font(MacTheme.Typography.bodyFont)
                    .foregroundColor(MacTheme.Colors.warmGray)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(MacTheme.Spacing.xl)
        .frame(maxWidth: .infinity)
        .background(MacTheme.Colors.warmWhite)
        .cornerRadius(MacTheme.CornerRadius.card)
    }

    // MARK: - Friends List

    private var friendsListSection: some View {
        VStack(spacing: MacTheme.Spacing.md) {
            ForEach(friendUpdates) { update in
                FriendMoodRow(update: update)
            }
        }
    }

    // MARK: - Helpers

    private func loadFriendsFeed() async {
        isLoading = true

        // Check if user has any friends in trusted circle
        let trustedCircle = TrustedCircle.local
        hasFriends = !trustedCircle.members.isEmpty

        do {
            friendUpdates = try await moodService.getFriendsFeed()
        } catch {
            print("Failed to load friends feed: \(error)")
        }

        isLoading = false
    }
}

// MARK: - Trusted Circle Extension

extension TrustedCircle {
    /// Load trusted circle from local storage (macOS compatible)
    static var local: TrustedCircle {
        let userDefaults = UserDefaults.standard
        let key = "trusted_circle_data"
        guard let data = userDefaults.data(forKey: key),
              let loaded = try? JSONDecoder().decode(TrustedCircle.self, from: data) else {
            return TrustedCircle()
        }
        return loaded
    }

    /// Save trusted circle to local storage
    func save() {
        let userDefaults = UserDefaults.standard
        let key = "trusted_circle_data"
        if let data = try? JSONEncoder().encode(self) {
            userDefaults.set(data, forKey: key)
        }
    }
}

// MARK: - Friend Mood Row

struct FriendMoodRow: View {
    let update: FriendMoodUpdate

    var body: some View {
        HStack(spacing: MacTheme.Spacing.md) {
            // Avatar
            Circle()
                .fill(avatarColor)
                .frame(width: 48, height: 48)
                .overlay {
                    Text(initials)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(update.friendName)
                    .font(MacTheme.Typography.bodyFont)
                    .fontWeight(.medium)
                    .foregroundColor(MacTheme.Colors.charcoal)

                Text(moodText)
                    .font(MacTheme.Typography.calloutFont)
                    .foregroundColor(MacTheme.Colors.warmGray)
            }

            Spacer()

            // Mood indicator
            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: update.trendIcon)
                        .font(.caption)
                        .foregroundColor(update.trendColor)

                    Text(formattedTime)
                        .font(MacTheme.Typography.captionFont)
                        .foregroundColor(MacTheme.Colors.warmGray)
                }

                Text(relationshipText)
                    .font(MacTheme.Typography.captionFont)
                    .foregroundColor(MacTheme.Colors.warmGray.opacity(0.7))
            }
        }
        .padding(MacTheme.Spacing.md)
        .background(MacTheme.Colors.warmWhite)
        .cornerRadius(MacTheme.CornerRadius.medium)
        .shadow(color: MacTheme.Colors.cardShadow, radius: 4, x: 0, y: 2)
    }

    private var initials: String {
        let parts = update.friendName.split(separator: " ")
        if parts.count >= 2 {
            return "\(parts[0].prefix(1))\(parts[1].prefix(1))".uppercased()
        } else if let first = parts.first {
            return String(first.prefix(2)).uppercased()
        }
        return "?"
    }

    private var avatarColor: Color {
        switch update.moodScore {
        case 0.5...1.0: return MacTheme.Colors.calmSage
        case 0.2..<0.5: return MacTheme.Colors.gentleGold
        case -0.2..<0.2: return MacTheme.Colors.warmGray
        case -0.5..<(-0.2): return MacTheme.Colors.mutedRose
        default: return MacTheme.Colors.deepEmber
        }
    }

    private var moodText: String {
        "Feeling \(update.moodLabel.lowercased())"
    }

    private var relationshipText: String {
        update.relationship.displayName
    }

    private var formattedTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: update.lastUpdated, relativeTo: Date())
    }
}

// MARK: - Add Friends Sheet

struct AddFriendsSheet: View {
    @Binding var hasFriends: Bool
    @Environment(\.dismiss) private var dismiss
    @State private var friendName = ""
    @State private var selectedRelationship: TrustedMember.Relationship = .friend
    @State private var friends: [(name: String, relationship: TrustedMember.Relationship)] = []

    var body: some View {
        NavigationStack {
            VStack(spacing: MacTheme.Spacing.lg) {
                // Header
                Text("Add friends to your trusted circle")
                    .font(MacTheme.Typography.bodyFont)
                    .foregroundColor(MacTheme.Colors.warmGray)
                    .multilineTextAlignment(.center)
                    .padding(.top, MacTheme.Spacing.lg)

                // Add friend form
                VStack(spacing: MacTheme.Spacing.md) {
                    TextField("Friend's name", text: $friendName)
                        .textFieldStyle(.roundedBorder)

                    Picker("Relationship", selection: $selectedRelationship) {
                        ForEach(TrustedMember.Relationship.allCases, id: \.self) { rel in
                            Text(rel.displayName).tag(rel)
                        }
                    }
                    .pickerStyle(.menu)

                    Button {
                        if !friendName.isEmpty {
                            friends.append((friendName, selectedRelationship))
                            friendName = ""
                        }
                    } label: {
                        Label("Add", systemImage: "plus.circle.fill")
                    }
                    .buttonStyle(.bordered)
                    .disabled(friendName.isEmpty)
                }
                .padding(.horizontal)

                // Friends list
                if !friends.isEmpty {
                    VStack(alignment: .leading, spacing: MacTheme.Spacing.sm) {
                        Text("Friends to add")
                            .font(MacTheme.Typography.headlineFont)
                            .foregroundColor(MacTheme.Colors.charcoal)

                        ForEach(friends.indices, id: \.self) { index in
                            HStack {
                                Text(friends[index].name)
                                    .font(MacTheme.Typography.bodyFont)
                                Spacer()
                                Text(friends[index].relationship.displayName)
                                    .font(MacTheme.Typography.captionFont)
                                    .foregroundColor(MacTheme.Colors.warmGray)
                            }
                            .padding(MacTheme.Spacing.sm)
                            .background(MacTheme.Colors.softBlush)
                            .cornerRadius(MacTheme.CornerRadius.small)
                        }
                    }
                    .padding(.horizontal)
                }

                Spacer()

                // Privacy note
                VStack(spacing: MacTheme.Spacing.sm) {
                    Image(systemName: "lock.shield")
                        .font(.title2)
                        .foregroundColor(MacTheme.Colors.calmSage)

                    Text("Your friends will only see your mood if you both opt in")
                        .font(MacTheme.Typography.captionFont)
                        .foregroundColor(MacTheme.Colors.warmGray)
                        .multilineTextAlignment(.center)
                }
                .padding()

                // Save button
                Button {
                    saveFriends()
                } label: {
                    Text("Save Friends")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(MacTheme.Colors.mutedRose)
                .padding(.horizontal)
                .padding(.bottom, MacTheme.Spacing.lg)
                .disabled(friends.isEmpty)
            }
            .navigationTitle("Add Friends")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func saveFriends() {
        var circle = TrustedCircle.local
        for friend in friends {
            let member = TrustedMember(name: friend.name, relationship: friend.relationship)
            circle.members.append(member)
        }
        circle.save()
        hasFriends = true
        dismiss()
    }
}

#Preview {
    NavigationStack {
        MacFriendsFeedView()
    }
}
