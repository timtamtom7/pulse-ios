import SwiftUI

struct TimelineView: View {
    @State private var viewModel = TimelineViewModel()
    @State private var showingDayDetail = false
    @State private var selectedDaySummary: DayEmotionSummary?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
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
                    .padding(.bottom, Theme.Spacing.xxl)
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

#Preview {
    TimelineView()
}
