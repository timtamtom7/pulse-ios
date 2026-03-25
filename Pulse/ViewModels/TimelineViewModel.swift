import Foundation

enum TimelineViewMode: String, CaseIterable {
    case day = "Day"
    case week = "Week"
    case month = "Month"
}

@Observable
final class TimelineViewModel: @unchecked Sendable {
    var daySummaries: [DayEmotionSummary] = []
    var selectedDate: Date = Date()
    var viewMode: TimelineViewMode = .week
    var selectedMoments: [Moment] = []
    var isLoading = false

    private let database = DatabaseService.shared

    init() {
        loadTimeline()
    }

    func loadTimeline() {
        isLoading = true

        let allMoments = database.fetchAllMoments()
        let calendar = Calendar.current

        let daysToLoad: Int
        switch viewMode {
        case .day: daysToLoad = 1
        case .week: daysToLoad = 7
        case .month: daysToLoad = 30
        }

        guard let startDate = calendar.date(byAdding: .day, value: -daysToLoad, to: Date()) else {
            isLoading = false
            return
        }

        daySummaries = stride(from: startDate, to: Date(), by: 86400).map { date in
            let dayMoments = allMoments.filter { moment in
                calendar.isDate(moment.timestamp, inSameDayAs: date)
            }
            return DayEmotionSummary(date: date, moments: dayMoments)
        }.sorted { $0.date > $1.date }

        isLoading = false
    }

    func selectDate(_ date: Date) {
        selectedDate = date
        selectedMoments = database.fetchMoments(for: date)
    }

    func changeViewMode(_ mode: TimelineViewMode) {
        viewMode = mode
        loadTimeline()
    }

    func deleteMoment(_ moment: Moment) {
        try? database.deleteMoment(id: moment.id)
        loadTimeline()
        selectedMoments.removeAll { $0.id == moment.id }
    }

    var groupedByWeek: [[DayEmotionSummary]] {
        let calendar = Calendar.current
        var groups: [[DayEmotionSummary]] = []
        var currentGroup: [DayEmotionSummary] = []

        for summary in daySummaries {
            if currentGroup.isEmpty {
                currentGroup.append(summary)
            } else if calendar.component(.weekOfYear, from: currentGroup.last!.date) ==
                        calendar.component(.weekOfYear, from: summary.date) {
                currentGroup.append(summary)
            } else {
                groups.append(currentGroup)
                currentGroup = [summary]
            }
        }

        if !currentGroup.isEmpty {
            groups.append(currentGroup)
        }

        return groups
    }

    var weekLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: selectedDate)
    }
}
