import SwiftUI

/// View for browsing anonymous mood chains - "See who's feeling the same"
struct MoodChainsView: View {
    @State private var chains: [MoodChain] = []
    @State private var selectedChain: MoodChain?
    @State private var isLoading = true
    @State private var showingShareSheet = false
    @State private var selectedEmotion: EmotionCategory?

    private let moodService = MoodSharingService.shared

    var body: some View {
        ScrollView {
            VStack(spacing: MacTheme.Spacing.lg) {
                headerSection
                aggregateMoodCard
                chainsSection
            }
            .padding(MacTheme.Spacing.lg)
        }
        .background(MacTheme.Colors.cream)
        .navigationTitle("Mood Chains")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingShareSheet = true
                } label: {
                    Label("Add to Chain", systemImage: "plus.circle.fill")
                }
                .buttonStyle(.borderedProminent)
                .tint(MacTheme.Colors.mutedRose)
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareToChainSheet(selectedEmotion: $selectedEmotion)
        }
        .sheet(item: $selectedChain) { chain in
            MoodChainDetailView(chain: chain)
        }
        .task {
            await loadChains()
        }
        .refreshable {
            await loadChains()
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: MacTheme.Spacing.sm) {
            Text("See who's feeling the same")
                .font(MacTheme.Typography.headlineFont)
                .foregroundColor(MacTheme.Colors.charcoal)

            Text("Browse mood chains to connect with others experiencing similar emotions")
                .font(MacTheme.Typography.bodyFont)
                .foregroundColor(MacTheme.Colors.warmGray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Aggregate Mood Card

    private var aggregateMoodCard: some View {
        Group {
            if isLoading {
                ProgressView()
                    .frame(height: 120)
                    .frame(maxWidth: .infinity)
                    .background(MacTheme.Colors.warmWhite)
                    .cornerRadius(MacTheme.CornerRadius.card)
            } else if let aggregate = chains.first {
                VStack(spacing: MacTheme.Spacing.md) {
                    HStack {
                        Circle()
                            .fill(aggregate.emotionCategory.color)
                            .frame(width: 48, height: 48)
                            .overlay {
                                Text(emojiForCategory(aggregate.emotionCategory))
                                    .font(.title)
                            }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Right Now")
                                .font(MacTheme.Typography.captionFont)
                                .foregroundColor(MacTheme.Colors.warmGray)

                            Text(aggregate.chainName)
                                .font(MacTheme.Typography.titleFont)
                                .foregroundColor(MacTheme.Colors.charcoal)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 4) {
                            Text("\(aggregate.participantCount)")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(MacTheme.Colors.mutedRose)

                            Text("people")
                                .font(MacTheme.Typography.captionFont)
                                .foregroundColor(MacTheme.Colors.warmGray)
                        }
                    }

                    Divider()

                    Text("You could add your mood to the \(aggregate.emotionCategory.displayName.lowercased()) chain")
                        .font(MacTheme.Typography.calloutFont)
                        .foregroundColor(MacTheme.Colors.warmGray)
                        .multilineTextAlignment(.center)
                }
                .padding(MacTheme.Spacing.cardPadding)
                .background(MacTheme.Colors.warmWhite)
                .cornerRadius(MacTheme.CornerRadius.card)
                .shadow(color: MacTheme.Colors.cardShadow, radius: 8, x: 0, y: 4)
            } else {
                emptyAggregateView
            }
        }
    }

    private var emptyAggregateView: some View {
        VStack(spacing: MacTheme.Spacing.md) {
            Image(systemName: "heart.slash")
                .font(.system(size: 40))
                .foregroundColor(MacTheme.Colors.warmGray)

            Text("No active mood chains yet")
                .font(MacTheme.Typography.bodyFont)
                .foregroundColor(MacTheme.Colors.warmGray)

            Button("Be the first to share") {
                showingShareSheet = true
            }
            .buttonStyle(.borderedProminent)
            .tint(MacTheme.Colors.mutedRose)
        }
        .frame(height: 120)
        .frame(maxWidth: .infinity)
        .background(MacTheme.Colors.warmWhite)
        .cornerRadius(MacTheme.CornerRadius.card)
    }

    // MARK: - Chains List

    private var chainsSection: some View {
        VStack(alignment: .leading, spacing: MacTheme.Spacing.md) {
            Text("Active Chains")
                .font(MacTheme.Typography.headlineFont)
                .foregroundColor(MacTheme.Colors.charcoal)

            if chains.isEmpty && !isLoading {
                noChainsView
            } else {
                LazyVStack(spacing: MacTheme.Spacing.md) {
                    ForEach(chains) { chain in
                        MoodChainRow(chain: chain) {
                            selectedChain = chain
                        }
                    }
                }
            }
        }
    }

    private var noChainsView: some View {
        VStack(spacing: MacTheme.Spacing.md) {
            Image(systemName: "link")
                .font(.system(size: 32))
                .foregroundColor(MacTheme.Colors.warmGray.opacity(0.5))

            Text("No mood chains yet")
                .font(MacTheme.Typography.bodyFont)
                .foregroundColor(MacTheme.Colors.warmGray)

            Text("Start a chain by sharing how you're feeling")
                .font(MacTheme.Typography.captionFont)
                .foregroundColor(MacTheme.Colors.warmGray.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(MacTheme.Spacing.xl)
        .background(MacTheme.Colors.warmWhite)
        .cornerRadius(MacTheme.CornerRadius.card)
    }

    // MARK: - Helpers

    private func loadChains() async {
        isLoading = true
        do {
            chains = try await moodService.getMoodChains()
        } catch {
            print("Failed to load mood chains: \(error)")
        }
        isLoading = false
    }

    private func emojiForCategory(_ category: EmotionCategory) -> String {
        switch category {
        case .joy: return "😊"
        case .trust: return "🤝"
        case .anticipation: return "🤞"
        case .surprise: return "😮"
        case .neutral: return "😐"
        case .sadness: return "😢"
        case .fear: return "😨"
        case .anger: return "😠"
        case .disgust: return "🤢"
        }
    }
}

// MARK: - Mood Chain Row

struct MoodChainRow: View {
    let chain: MoodChain
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: MacTheme.Spacing.md) {
                // Emotion indicator
                Circle()
                    .fill(chain.emotionCategory.color)
                    .frame(width: 44, height: 44)
                    .overlay {
                        Text(emojiForCategory(chain.emotionCategory))
                            .font(.title3)
                    }

                // Chain info
                VStack(alignment: .leading, spacing: 4) {
                    Text(chain.chainName)
                        .font(MacTheme.Typography.bodyFont)
                        .fontWeight(.medium)
                        .foregroundColor(MacTheme.Colors.charcoal)

                    HStack(spacing: MacTheme.Spacing.sm) {
                        Label("\(chain.participantCount)", systemImage: "person.2.fill")
                            .font(MacTheme.Typography.captionFont)
                            .foregroundColor(MacTheme.Colors.warmGray)

                        Text("·")
                            .foregroundColor(MacTheme.Colors.warmGray)

                        Text(chain.isActive ? "Active now" : "Last \(formattedDuration)")
                            .font(MacTheme.Typography.captionFont)
                            .foregroundColor(chain.isActive ? MacTheme.Colors.calmSage : MacTheme.Colors.warmGray)
                    }
                }

                Spacer()

                // Activity indicator
                if chain.isActive {
                    Circle()
                        .fill(MacTheme.Colors.calmSage)
                        .frame(width: 8, height: 8)
                }

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(MacTheme.Colors.warmGray)
            }
            .padding(MacTheme.Spacing.md)
            .background(MacTheme.Colors.warmWhite)
            .cornerRadius(MacTheme.CornerRadius.medium)
        }
        .buttonStyle(.plain)
    }

    private var formattedDuration: String {
        let interval = Date().timeIntervalSince(chain.lastActivity)
        if interval < 3600 {
            return "\(Int(interval / 60))m ago"
        } else if interval < 86400 {
            return "\(Int(interval / 3600))h ago"
        } else {
            return "\(Int(interval / 86400))d ago"
        }
    }

    private func emojiForCategory(_ category: EmotionCategory) -> String {
        switch category {
        case .joy: return "😊"
        case .trust: return "🤝"
        case .anticipation: return "🤞"
        case .surprise: return "😮"
        case .neutral: return "😐"
        case .sadness: return "😢"
        case .fear: return "😨"
        case .anger: return "😠"
        case .disgust: return "🤢"
        }
    }
}

// MARK: - Mood Chain Detail View

struct MoodChainDetailView: View {
    let chain: MoodChain
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: MacTheme.Spacing.lg) {
                    // Header
                    chainHeader

                    // Participants count
                    participantsSection

                    // Timeline of entries
                    timelineSection
                }
                .padding(MacTheme.Spacing.lg)
            }
            .background(MacTheme.Colors.cream)
            .navigationTitle(chain.chainName)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }

                ToolbarItem(placement: .primaryAction) {
                    Button {
                        // Join chain action
                    } label: {
                        Label("Join", systemImage: "plus.circle")
                    }
                }
            }
        }
    }

    private var chainHeader: some View {
        VStack(spacing: MacTheme.Spacing.md) {
            Circle()
                .fill(chain.emotionCategory.color)
                .frame(width: 80, height: 80)
                .overlay {
                    Text(emojiForCategory(chain.emotionCategory))
                        .font(.system(size: 40))
                }

            Text("\(chain.participantCount) people in this chain")
                .font(MacTheme.Typography.calloutFont)
                .foregroundColor(MacTheme.Colors.warmGray)

            HStack(spacing: MacTheme.Spacing.lg) {
                VStack {
                    Text("Started")
                        .font(MacTheme.Typography.captionFont)
                        .foregroundColor(MacTheme.Colors.warmGray)
                    Text(formattedDate(chain.startedAt))
                        .font(MacTheme.Typography.captionFont)
                        .foregroundColor(MacTheme.Colors.charcoal)
                }

                VStack {
                    Text("Last Activity")
                        .font(MacTheme.Typography.captionFont)
                        .foregroundColor(MacTheme.Colors.warmGray)
                    Text(formattedDate(chain.lastActivity))
                        .font(MacTheme.Typography.captionFont)
                        .foregroundColor(MacTheme.Colors.charcoal)
                }
            }
        }
        .padding(MacTheme.Spacing.lg)
        .frame(maxWidth: .infinity)
        .background(MacTheme.Colors.warmWhite)
        .cornerRadius(MacTheme.CornerRadius.card)
    }

    private var participantsSection: some View {
        VStack(alignment: .leading, spacing: MacTheme.Spacing.sm) {
            Text("Recent Participants")
                .font(MacTheme.Typography.headlineFont)
                .foregroundColor(MacTheme.Colors.charcoal)

            Text("Anonymous users who shared this mood")
                .font(MacTheme.Typography.captionFont)
                .foregroundColor(MacTheme.Colors.warmGray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var timelineSection: some View {
        VStack(spacing: MacTheme.Spacing.sm) {
            ForEach(chain.entries.suffix(10).reversed()) { entry in
                HStack {
                    Circle()
                        .fill(chain.emotionCategory.color.opacity(0.2))
                        .frame(width: 36, height: 36)
                        .overlay {
                            Image(systemName: "person.fill")
                                .font(.caption)
                                .foregroundColor(chain.emotionCategory.color)
                        }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Anonymous")
                            .font(MacTheme.Typography.calloutFont)
                            .foregroundColor(MacTheme.Colors.charcoal)

                        Text(entry.formattedTime)
                            .font(MacTheme.Typography.captionFont)
                            .foregroundColor(MacTheme.Colors.warmGray)
                    }

                    Spacer()

                    Text("Feeling \(chain.emotionCategory.displayName.lowercased())")
                        .font(MacTheme.Typography.captionFont)
                        .foregroundColor(chain.emotionCategory.color)
                }
                .padding(MacTheme.Spacing.sm)
                .background(MacTheme.Colors.warmWhite)
                .cornerRadius(MacTheme.CornerRadius.small)
            }
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func emojiForCategory(_ category: EmotionCategory) -> String {
        switch category {
        case .joy: return "😊"
        case .trust: return "🤝"
        case .anticipation: return "🤞"
        case .surprise: return "😮"
        case .neutral: return "😐"
        case .sadness: return "😢"
        case .fear: return "😨"
        case .anger: return "😠"
        case .disgust: return "🤢"
        }
    }
}

// MARK: - Share to Chain Sheet

struct ShareToChainSheet: View {
    @Binding var selectedEmotion: EmotionCategory?
    @Environment(\.dismiss) private var dismiss
    @State private var selectedMood: QuickMood = .okay
    @State private var isSharing = false

    private let moodService = MoodSharingService.shared

    var body: some View {
        NavigationStack {
            VStack(spacing: MacTheme.Spacing.lg) {
                Text("How are you feeling?")
                    .font(MacTheme.Typography.headlineFont)
                    .foregroundColor(MacTheme.Colors.charcoal)
                    .padding(.top, MacTheme.Spacing.lg)

                // Mood selector
                HStack(spacing: MacTheme.Spacing.md) {
                    ForEach(QuickMood.allCases) { mood in
                        Button {
                            selectedMood = mood
                        } label: {
                            VStack(spacing: 4) {
                                Text(mood.emoji)
                                    .font(.system(size: 32))

                                Text(mood.label)
                                    .font(MacTheme.Typography.captionFont)
                                    .foregroundColor(
                                        selectedMood == mood
                                        ? MacTheme.Colors.mutedRose
                                        : MacTheme.Colors.warmGray
                                    )
                            }
                            .padding(MacTheme.Spacing.sm)
                            .background(
                                selectedMood == mood
                                ? MacTheme.Colors.softBlush
                                : Color.clear
                            )
                            .cornerRadius(MacTheme.CornerRadius.medium)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)

                Spacer()

                // Share button
                Button {
                    Task {
                        await shareMood()
                    }
                } label: {
                    if isSharing {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Share Anonymously")
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(MacTheme.Colors.mutedRose)
                .foregroundColor(.white)
                .cornerRadius(MacTheme.CornerRadius.button)
                .padding(.horizontal)
                .disabled(isSharing)

                Text("Your mood will be shared anonymously with others feeling the same way")
                    .font(MacTheme.Typography.captionFont)
                    .foregroundColor(MacTheme.Colors.warmGray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .padding(.bottom, MacTheme.Spacing.lg)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func shareMood() async {
        isSharing = true

        let entry = MoodEntry(
            emotionScore: selectedMood.emotionScore,
            emotionLabel: selectedMood.label
        )

        do {
            try await moodService.shareMood(entry)
            dismiss()
        } catch {
            print("Failed to share mood: \(error)")
        }

        isSharing = false
    }
}

#Preview {
    NavigationStack {
        MoodChainsView()
    }
}
