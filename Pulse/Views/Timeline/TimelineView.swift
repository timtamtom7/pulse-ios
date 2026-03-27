import SwiftUI

struct TimelineView: View {
    @State private var viewModel = TimelineViewModel()
    @State private var showingDayDetail = false
    @State private var selectedDaySummary: DayEmotionSummary?
    @State private var selectedEmotionIndex = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // R2: Horizontal emotion scrubber
                if !viewModel.daySummaries.isEmpty {
                    EmotionScrubberView(summaries: viewModel.daySummaries)
                        .padding(.vertical, Theme.Spacing.md)
                }

                // View mode picker
                Picker("View Mode", selection: Binding(
                    get: { viewModel.viewMode },
                    set: { viewModel.changeViewMode($0) }
                )) {
                    ForEach(TimelineViewMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, Theme.Spacing.screenMargin)
                .padding(.vertical, Theme.Spacing.md)

                ScrollView {
                    if viewModel.daySummaries.isEmpty && !viewModel.isLoading {
                        TimelineEmptyState()
                            .padding(.top, Theme.Spacing.xxl)
                    } else {
                        LazyVStack(spacing: Theme.Spacing.sm) {
                            ForEach(viewModel.daySummaries) { summary in
                                TimelineDayRow(summary: summary)
                                    .onTapGesture {
                                        selectedDaySummary = summary
                                        viewModel.selectDate(summary.date)
                                        showingDayDetail = true
                                    }
                            }
                        }
                        .padding(.horizontal, Theme.Spacing.screenMargin)
                    }
                    Spacer(minLength: Theme.Spacing.xxl)
                }
            }
            .background(Theme.Colors.primaryBackground)
            .navigationTitle("Timeline")
            .sheet(isPresented: $showingDayDetail) {
                if let summary = selectedDaySummary {
                    DayDetailView(date: summary.date, moments: viewModel.selectedMoments) { moment in
                        viewModel.deleteMoment(moment)
                    }
                }
            }
        }
    }
}

// R2: Horizontal emotion scrubber for emotional timeline
struct EmotionScrubberView: View {
    let summaries: [DayEmotionSummary]
    @State private var scrollOffset: CGFloat = 0
    @State private var selectedIndex: Int?

    var body: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Text("Your Week at a Glance")
                .font(Theme.Typography.captionFont)
                .foregroundColor(Theme.Colors.warmGray)
                .textCase(.uppercase)
                .tracking(1)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Theme.Spacing.sm) {
                    ForEach(Array(summaries.enumerated()), id: \.element.id) { index, summary in
                        EmotionBubbleView(summary: summary, isSelected: selectedIndex == index)
                            .onTapGesture {
                                withAnimation(Theme.Animations.gentleEaseOut) {
                                    selectedIndex = index
                                }
                            }
                    }
                }
                .padding(.horizontal, Theme.Spacing.screenMargin)
            }
            .gesture(
                DragGesture()
                    .onChanged { value in
                        // Smooth horizontal scrolling feedback
                    }
            )
        }
        .padding(.horizontal, Theme.Spacing.screenMargin)
    }
}

struct EmotionBubbleView: View {
    let summary: DayEmotionSummary
    let isSelected: Bool

    var dayLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: summary.date)
    }

    var body: some View {
        VStack(spacing: 4) {
            Circle()
                .fill(summary.dominantEmotionColor)
                .frame(width: isSelected ? 56 : 44, height: isSelected ? 56 : 44)
                .overlay {
                    if let dominant = summary.dominantEmotion {
                        Text(String(dominant.label.prefix(1)))
                            .font(.system(size: isSelected ? 24 : 18, weight: .bold))
                            .foregroundColor(.white)
                    } else {
                        Image(systemName: "minus")
                            .font(.system(size: isSelected ? 20 : 14, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .shadow(color: summary.dominantEmotionColor.opacity(0.4), radius: isSelected ? 8 : 4, y: 2)
                .animation(Theme.Animations.springBack, value: isSelected)

            Text(dayLabel)
                .font(Theme.Typography.captionFont)
                .foregroundColor(isSelected ? Theme.Colors.charcoal : Theme.Colors.warmGray)

            Text("\(summary.momentCount)")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(Theme.Colors.warmGray)
        }
        .scaleEffect(isSelected ? 1.1 : 1.0)
        .animation(Theme.Animations.springBack, value: isSelected)
    }
}

#Preview {
    TimelineView()
}

// MARK: - Empty State

struct TimelineEmptyState: View {
    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Image(systemName: "calendar")
                .font(.system(size: 56))
                .foregroundColor(Theme.Colors.mutedRose.opacity(0.5))

            Text("Your Timeline is Empty")
                .font(Theme.Typography.headlineFont)
                .foregroundColor(Theme.Colors.charcoal)

            Text("Capture moments to see your emotional patterns over time. Each moment adds a piece to your personal story.")
                .font(Theme.Typography.bodyFont)
                .foregroundColor(Theme.Colors.warmGray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Theme.Spacing.xl)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.Spacing.xl)
    }
}
