import Foundation
import SQLite

@Observable
final class DatabaseService: @unchecked Sendable {
    static let shared = DatabaseService()

    private var db: Connection?
    private let momentsTable = Table("moments")
    private let dataSourcesTable = Table("data_sources")
    private let insightsTable = Table("insights")

    // Moments columns
    private let momentId = SQLite.Expression<String>("id")
    private let momentType = SQLite.Expression<String>("type")
    private let momentTimestamp = SQLite.Expression<Date>("timestamp")
    private let momentContent = SQLite.Expression<String>("content")
    private let momentEmotionScore = SQLite.Expression<Double>("emotion_score")
    private let momentEmotionTags = SQLite.Expression<String>("emotion_tags")
    private let momentNote = SQLite.Expression<String?>("note")
    private let momentSourceId = SQLite.Expression<String?>("source_id")

    // DataSource columns
    private let dsId = SQLite.Expression<String>("id")
    private let dsType = SQLite.Expression<String>("type")
    private let dsIsConnected = SQLite.Expression<Bool>("is_connected")
    private let dsLastSynced = SQLite.Expression<Date?>("last_synced")
    private let dsDataPointCount = SQLite.Expression<Int>("data_point_count")

    // Insight columns
    private let insightId = SQLite.Expression<String>("id")
    private let insightTitle = SQLite.Expression<String>("title")
    private let insightBody = SQLite.Expression<String>("body")
    private let insightCategory = SQLite.Expression<String>("category")
    private let insightCreatedAt = SQLite.Expression<Date>("created_at")
    private let insightDataPointCount = SQLite.Expression<Int>("data_point_count")
    private let insightEmotionScore = SQLite.Expression<Double>("emotion_score")

    private init() {
        setupDatabase()
    }

    private func setupDatabase() {
        do {
            let documentsPath = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            try FileManager.default.createDirectory(at: documentsPath, withIntermediateDirectories: true)
            let dbPath = documentsPath.appendingPathComponent("pulse.sqlite3")
            db = try Connection(dbPath.path)
            try createTables()
        } catch {
            print("Database setup error: \(error)")
        }
    }

    private func createTables() throws {
        guard let db = db else { return }

        try db.run(momentsTable.create(ifNotExists: true) { t in
            t.column(momentId, primaryKey: true)
            t.column(momentType)
            t.column(momentTimestamp)
            t.column(momentContent)
            t.column(momentEmotionScore)
            t.column(momentEmotionTags)
            t.column(momentNote)
            t.column(momentSourceId)
        })

        try db.run(dataSourcesTable.create(ifNotExists: true) { t in
            t.column(dsId, primaryKey: true)
            t.column(dsType)
            t.column(dsIsConnected)
            t.column(dsLastSynced)
            t.column(dsDataPointCount)
        })

        try db.run(insightsTable.create(ifNotExists: true) { t in
            t.column(insightId, primaryKey: true)
            t.column(insightTitle)
            t.column(insightBody)
            t.column(insightCategory)
            t.column(insightCreatedAt)
            t.column(insightDataPointCount)
            t.column(insightEmotionScore)
        })
    }

    // MARK: - Moments CRUD

    func fetchAllMoments() -> [Moment] {
        guard let db = db else { return [] }

        do {
            var moments: [Moment] = []
            for row in try db.prepare(momentsTable.order(momentTimestamp.desc)) {
                if let moment = momentFromRow(row) {
                    moments.append(moment)
                }
            }
            return moments
        } catch {
            print("Fetch moments error: \(error)")
            return []
        }
    }

    func fetchMoments(for date: Date) -> [Moment] {
        guard let db = db else { return [] }

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { return [] }

        do {
            var moments: [Moment] = []
            let query = momentsTable
                .filter(momentTimestamp >= startOfDay && momentTimestamp < endOfDay)
                .order(momentTimestamp.desc)

            for row in try db.prepare(query) {
                if let moment = momentFromRow(row) {
                    moments.append(moment)
                }
            }
            return moments
        } catch {
            print("Fetch moments for date error: \(error)")
            return []
        }
    }

    func insertMoment(_ moment: Moment) throws {
        guard let db = db else { return }

        let tagsData = try JSONEncoder().encode(moment.emotionTags)
        let tagsString = String(data: tagsData, encoding: .utf8) ?? "[]"

        try db.run(momentsTable.insert(
            momentId <- moment.id.uuidString,
            momentType <- moment.type.rawValue,
            momentTimestamp <- moment.timestamp,
            momentContent <- moment.content,
            momentEmotionScore <- moment.emotionScore,
            momentEmotionTags <- tagsString,
            momentNote <- moment.note,
            momentSourceId <- moment.sourceDataSourceId?.uuidString
        ))
    }

    func deleteMoment(id: UUID) throws {
        guard let db = db else { return }
        let query = momentsTable.filter(momentId == id.uuidString)
        try db.run(query.delete())
    }

    private func momentFromRow(_ row: Row) -> Moment? {
        let tagsString = row[momentEmotionTags]
        let tags: [EmotionTag] = (try? JSONDecoder().decode([EmotionTag].self, from: Data(tagsString.utf8))) ?? []

        return Moment(
            id: UUID(uuidString: row[momentId]) ?? UUID(),
            type: MomentType(rawValue: row[momentType]) ?? .journal,
            timestamp: row[momentTimestamp],
            content: row[momentContent],
            emotionScore: row[momentEmotionScore],
            emotionTags: tags,
            note: row[momentNote],
            sourceDataSourceId: row[momentSourceId].flatMap { UUID(uuidString: $0) }
        )
    }

    // MARK: - Insights CRUD

    func insertInsight(_ insight: Insight) throws {
        guard let db = db else { return }

        try db.run(insightsTable.insert(
            insightId <- insight.id.uuidString,
            insightTitle <- insight.title,
            insightBody <- insight.body,
            insightCategory <- insight.category.rawValue,
            insightCreatedAt <- insight.createdAt,
            insightDataPointCount <- insight.supportingDataPointCount,
            insightEmotionScore <- insight.emotionScore
        ))
    }

    func fetchLatestInsight() -> Insight? {
        guard let db = db else { return nil }

        do {
            let query = insightsTable.order(insightCreatedAt.desc).limit(1)
            for row in try db.prepare(query) {
                return Insight(
                    id: UUID(uuidString: row[insightId]) ?? UUID(),
                    title: row[insightTitle],
                    body: row[insightBody],
                    category: InsightCategory(rawValue: row[insightCategory]) ?? .general,
                    createdAt: row[insightCreatedAt],
                    supportingDataPointCount: row[insightDataPointCount],
                    emotionScore: row[insightEmotionScore]
                )
            }
        } catch {
            print("Fetch insight error: \(error)")
        }
        return nil
    }

    // MARK: - Stats

    func momentCount() -> Int {
        guard let db = db else { return 0 }
        do {
            return try db.scalar(momentsTable.count)
        } catch {
            return 0
        }
    }
}
