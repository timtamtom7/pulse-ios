import SwiftUI

struct MacTimelineView: View {
    @Bindable var viewModel: TimelineViewModel
    @State private var searchText = ""
    @State private var selectedEmotionFilter: EmotionCategory?
    @State private var selectedMoment: Moment?
    @State private var showingDetail = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView

            // Search and filter
            filterBar

            Divider()

            // Timeline content
            if filteredSummaries.isEmpty {
                emptyState
            } else {
                timelineList
            }
        }
        .background(MacTheme.Colors.cream)
        .sheet(isPresented: $showingDetail) {
            if let moment = selectedMoment {
                MacMomentDetailSheet(moment: moment) {
                    viewModel.deleteMoment(moment)
                    showingDetail = false
                }
            }
        }
    }

    // MARK: - Header

    private var headerView: some View {
        VStack(alignment: .leading, spacing: MacTheme.Spacing.sm) {
            HStack {
                Text("Timeline")
                    .font(MacTheme.Typography.displayFont)
                    .foregroundColor(MacTheme.Colors.charcoal)

                Spacer()

                // View mode picker
                Picker("View", selection: Binding(
                    get: { viewModel.viewMode },
                    set: { viewModel.changeViewMode($0) }
                )) {
                    ForEach(TimelineViewMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 240)
            }
        }
        .padding(MacTheme.Spacing.screenMargin)
    }

    // MARK: - Filter Bar

    private var filterBar: some View {
        VStack(spacing: MacTheme.Spacing.sm) {
            HStack(spacing: MacTheme.Spacing.md) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(MacTheme.Colors.warmGray)

                TextField("Search moments...", text: $searchText)
                    .font(MacTheme.Typography.bodyFont)

                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(MacTheme.Colors.warmGray)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, MacTheme.Spacing.md)
            .padding(.vertical, 10)
            .background(MacTheme.Colors.warmWhite)
            .cornerRadius(MacTheme.CornerRadius.medium)

            // Emotion filters
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: MacTheme.Spacing.sm) {
                    emotionFilterChip(nil, label: "All")

                    ForEach(EmotionCategory.allCases, id: \.self) { category in
                        emotionFilterChip(category, label: category.displayName)
                    }
                }
            }
        }
        .padding(.horizontal, MacTheme.Spacing.screenMargin)
        .padding(.bottom, MacTheme.Spacing.md)
    }

    private func emotionFilterChip(_ category: EmotionCategory?, label: String) -> some View {
        Button {
            withAnimation(MacTheme.Animations.gentleEaseOut) {
                selectedEmotionFilter = category
            }
        } label: {
            HStack(spacing: 6) {
                if let cat = category {
                    Circle()
                        .fill(cat.color)
                        .frame(width: 8, height: 8)
                }

                Text(label)
                    .font(MacTheme.Typography.captionFont)

                if selectedEmotionFilter == category {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                selectedEmotionFilter == category
                ? MacTheme.Colors.mutedRose.opacity(0.15)
                : MacTheme.Colors.warmWhite
            )
            .foregroundColor(
                selectedEmotionFilter == category
                ? MacTheme.Colors.mutedRose
                : MacTheme.Colors.warmGray
            )
            .cornerRadius(MacTheme.CornerRadius.large)
            .overlay(
                RoundedRectangle(cornerRadius: MacTheme.CornerRadius.large)
                    .stroke(
                        selectedEmotionFilter == category
                        ? MacTheme.Colors.mutedRose.opacity(0.3)
                        : MacTheme.Colors.softBlush,
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Filtered Data

    private var filteredSummaries: [DayEmotionSummary] {
        var summaries = viewModel.daySummaries

        if let filter = selectedEmotionFilter {
            summaries = summaries.filter { summary in
                summary.dominantEmotion?.category == filter
            }
        }

        if !searchText.isEmpty {
            summaries = summaries.filter { summary in
                summary.formattedDate.localizedCaseInsensitiveContains(searchText)
            }
        }

        return summaries
    }

    // MARK: - Timeline List

    private var timelineList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(filteredSummaries) { summary in
                    timelineRow(summary)
                }
            }
            .padding(MacTheme.Spacing.screenMargin)
        }
    }

    private func timelineRow(_ summary: DayEmotionSummary) -> some View {
        HStack(alignment: .top, spacing: MacTheme.Spacing.lg) {
            // Date column
            VStack(spacing: 2) {
                Text(summary.dayNumber)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(MacTheme.Colors.charcoal)

                Text(summary.monthAbbreviation)
                    .font(MacTheme.Typography.captionFont)
                    .foregroundColor(MacTheme.Colors.warmGray)
            }
            .frame(width: 50)

            // Timeline line and dot
            VStack(spacing: 0) {
                Circle()
                    .fill(summary.dominantEmotionColor)
                    .frame(width: 16, height: 16)
                    .shadow(color: summary.dominantEmotionColor.opacity(0.4), radius: 4, y: 2)

                Rectangle()
                    .fill(MacTheme.Colors.softBlush)
                    .frame(width: 2)
            }
            .frame(width: 16)

            // Day content card
            VStack(alignment: .leading, spacing: MacTheme.Spacing.sm) {
                // Day label
                Text(summary.formattedDate)
                    .font(MacTheme.Typography.calloutFont)
                    .foregroundColor(MacTheme.Colors.warmGray)

                // Summary bar
                HStack(spacing: MacTheme.Spacing.md) {
                    // Emotion bar
                    HStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(summary.dominantEmotionColor)
                            .frame(width: 4, height: 40)

                        VStack(alignment: .leading, spacing: 4) {
                            if let dominant = summary.dominantEmotion {
                                Text(dominant.label)
                                    .font(MacTheme.Typography.calloutFont)
                                    .foregroundColor(MacTheme.Colors.charcoal)

                                Text("\(Int(dominant.confidence * 100))% confidence")
                                    .font(MacTheme.Typography.captionFont)
                                    .foregroundColor(MacTheme.Colors.warmGray)
                            } else {
                                Text("No moments")
                                    .font(MacTheme.Typography.calloutFont)
                                    .foregroundColor(MacTheme.Colors.warmGray)
                            }
                        }
                    }

                    Spacer()

                    // Moment count
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(summary.momentCount)")
                            .font(.system(size: 24, weight: .semibold, design: .rounded))
                            .foregroundColor(MacTheme.Colors.charcoal)

                        Text("moments")
                            .font(MacTheme.Typography.captionFont)
                            .foregroundColor(MacTheme.Colors.warmGray)
                    }
                }

                // Emotion tags
                if let dominant = summary.dominantEmotion {
                    EmotionTagRow(tag: dominant)
                }

                // Moments for this day
                let dayMoments = filteredMoments(for: summary)
                if !dayMoments.isEmpty {
                    VStack(spacing: MacTheme.Spacing.xs) {
                        ForEach(dayMoments.prefix(3)) { moment in
                            momentRow(moment)
                        }

                        if dayMoments.count > 3 {
                            Text("+\(dayMoments.count - 3) more")
                                .font(MacTheme.Typography.captionFont)
                                .foregroundColor(MacTheme.Colors.warmGray)
                        }
                    }
                }
            }
            .padding(MacTheme.Spacing.md)
            .frame(maxWidth: .infinity)
            .background(MacTheme.Colors.warmWhite)
            .cornerRadius(MacTheme.CornerRadius.card)
            .shadow(color: MacTheme.Colors.cardShadow, radius: 8, y: 2)
            .onTapGesture {
                viewModel.selectDate(summary.date)
            }
        }
    }

    private func filteredMoments(for summary: DayEmotionSummary) -> [Moment] {
        let calendar = Calendar.current
        let moments = viewModel.selectedMoments.filter {
            calendar.isDate($0.timestamp, inSameDayAs: summary.date)
        }

        if let filter = selectedEmotionFilter {
            return moments.filter { moment in
                moment.emotionTags.contains { $0.category == filter }
            }
        }

        return moments
    }

    private func momentRow(_ moment: Moment) -> some View {
        HStack(spacing: MacTheme.Spacing.sm) {
            Circle()
                .fill(moment.emotionTags.first?.color ?? MacTheme.Colors.neutral)
                .frame(width: 8, height: 8)

            Image(systemName: moment.type.icon)
                .font(.system(size: 12))
                .foregroundColor(MacTheme.Colors.warmGray)

            Text(moment.content.prefix(40).description)
                .font(MacTheme.Typography.captionFont)
                .foregroundColor(MacTheme.Colors.charcoal)
                .lineLimit(1)

            Spacer()

            Text(moment.formattedTime)
                .font(MacTheme.Typography.monoFont)
                .foregroundColor(MacTheme.Colors.warmGray)

            Button {
                selectedMoment = moment
                showingDetail = true
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(MacTheme.Colors.warmGray)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, MacTheme.Spacing.sm)
        .background(MacTheme.Colors.softBlush.opacity(0.5))
        .cornerRadius(MacTheme.CornerRadius.small)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: MacTheme.Spacing.lg) {
            Spacer()

            Image(systemName: "calendar")
                .font(.system(size: 56))
                .foregroundColor(MacTheme.Colors.mutedRose.opacity(0.5))

            Text("No Moments Yet")
                .font(MacTheme.Typography.headlineFont)
                .foregroundColor(MacTheme.Colors.charcoal)

            Text("Start capturing moments to see your emotional patterns over time.")
                .font(MacTheme.Typography.bodyFont)
                .foregroundColor(MacTheme.Colors.warmGray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, MacTheme.Spacing.xl)

            Spacer()
        }
    }
}

// MARK: - Emotion Tag Row

struct EmotionTagRow: View {
    let tag: EmotionTag

    var body: some View {
        HStack(spacing: MacTheme.Spacing.xs) {
            Circle()
                .fill(tag.color)
                .frame(width: 6, height: 6)

            Text(tag.label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(tag.color)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(tag.color.opacity(0.12))
        .cornerRadius(MacTheme.CornerRadius.small)
    }
}

// MARK: - Moment Detail Sheet

struct MacMomentDetailSheet: View {
    let moment: Moment
    let onDelete: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: MacTheme.Spacing.lg) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(moment.type.displayName)
                        .font(MacTheme.Typography.headlineFont)
                        .foregroundColor(MacTheme.Colors.charcoal)

                    Text("\(moment.formattedDate) at \(moment.formattedTime)")
                        .font(MacTheme.Typography.captionFont)
                        .foregroundColor(MacTheme.Colors.warmGray)
                }

                Spacer()

                Button("Delete") {
                    onDelete()
                }
                .foregroundColor(MacTheme.Colors.destructiveText)
                .font(MacTheme.Typography.calloutFont)
            }

            Divider()

            // Content
            if moment.type == .journal || moment.type == .voice {
                Text(moment.content)
                    .font(MacTheme.Typography.bodyFont)
                    .foregroundColor(MacTheme.Colors.charcoal)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            // Emotion tags
            VStack(alignment: .leading, spacing: MacTheme.Spacing.sm) {
                Text("Detected Emotions")
                    .font(MacTheme.Typography.captionFont)
                    .foregroundColor(MacTheme.Colors.warmGray)
                    .textCase(.uppercase)

                FlowLayout(spacing: MacTheme.Spacing.sm) {
                    ForEach(moment.emotionTags) { tag in
                        EmotionTagView(tag: tag)
                    }
                }
            }

            // Note
            if let note = moment.note, !note.isEmpty {
                VStack(alignment: .leading, spacing: MacTheme.Spacing.sm) {
                    Text("Note")
                        .font(MacTheme.Typography.captionFont)
                        .foregroundColor(MacTheme.Colors.warmGray)
                        .textCase(.uppercase)

                    Text(note)
                        .font(MacTheme.Typography.bodyFont)
                        .foregroundColor(MacTheme.Colors.charcoal)
                        .padding(MacTheme.Spacing.md)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(MacTheme.Colors.softBlush)
                        .cornerRadius(MacTheme.CornerRadius.medium)
                }
            }

            Spacer()

            Button("Close") {
                dismiss()
            }
            .frame(maxWidth: .infinity)
            .padding(MacTheme.Spacing.md)
            .background(MacTheme.Colors.softBlush)
            .cornerRadius(MacTheme.CornerRadius.medium)
            .foregroundColor(MacTheme.Colors.charcoal)
        }
        .padding(MacTheme.Spacing.lg)
        .frame(width: 500, height: 400)
    }
}

// MARK: - Flow Layout for Tags

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, spacing: spacing, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, spacing: spacing, subviews: subviews)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                       y: bounds.minY + result.positions[index].y),
                          proposal: .unspecified)
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []

        init(in maxWidth: CGFloat, spacing: CGFloat, subviews: Subviews) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var lineHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += lineHeight + spacing
                    lineHeight = 0
                }

                positions.append(CGPoint(x: x, y: y))
                lineHeight = max(lineHeight, size.height)
                x += size.width + spacing
            }

            self.size = CGSize(width: maxWidth, height: y + lineHeight)
        }
    }
}

#Preview {
    MacTimelineView(viewModel: TimelineViewModel())
}
