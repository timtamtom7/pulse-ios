import Foundation
import EventKit

final class EventKitService: @unchecked Sendable {
    static let shared = EventKitService()

    let eventStore = EKEventStore()

    private init() {}

    func fetchEvents(from startDate: Date, to endDate: Date) -> [EKEvent] {
        let calendars = eventStore.calendars(for: .event)
        let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: calendars)
        return eventStore.events(matching: predicate)
    }

    func fetchTodaysEvents() -> [EKEvent] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { return [] }
        return fetchEvents(from: startOfDay, to: endOfDay)
    }

    func fetchEventsForPastDays(_ days: Int) -> [EKEvent] {
        let calendar = Calendar.current
        let endDate = Date()
        guard let startDate = calendar.date(byAdding: .day, value: -days, to: endDate) else { return [] }
        return fetchEvents(from: startDate, to: endDate)
    }

    func eventTypesSummary(events: [EKEvent]) -> [String: Int] {
        var summary: [String: Int] = [:]
        for event in events {
            let title = event.title ?? "Unknown"
            summary[title, default: 0] += 1
        }
        return summary
    }
}
