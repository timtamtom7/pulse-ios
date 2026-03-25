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
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let dbPath = documentsPath.appendingPathComponent("pulse.sqlite3")
            db = try Connection(dbPath.path)

            try createTables()
            initializeDefaultDataSources()
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

    private func initializeDefaultDataSources() {
        guard let db = db else { return }

        do {
            let count = try db.scalar(dataSourcesTable.count)
            if count == 0 {
                for type in DataSourceType.allCases {
                    let ds = DataSource(type: type)
                    try insertDataSource(ds)
                }
            }
        } catch {
            print("Error initializing data sources: \(error)")
        }
    }

    // MARK: - Moments

    func insertMoment(_ moment: Moment) throws {
        guard let db = db else { return }

        let encoder = JSONEncoder()
        let tagsData = try encoder.encode(moment.emotionTags)
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

    func fetchAllMoments() -> [Moment] {
        guard let db = db else { return [] }

        var moments: [Moment] = []
        let decoder = JSONDecoder()

        do {
            for row in try db.prepare(momentsTable.order(momentTimestamp.desc)) {
                let tagsString = row[momentEmotionTags]
                let tagsData = tagsString.data(using: .utf8) ?? Data()
                let tags = (try? decoder.decode([EmotionTag].self, from: tagsData)) ?? []

                let moment = Moment(
                    id: UUID(uuidString: row[momentId]) ?? UUID(),
                    type: MomentType(rawValue: row[momentType]) ?? .journal,
                    timestamp: row[momentTimestamp],
                    content: row[momentContent],
                    emotionScore: row[momentEmotionScore],
                    emotionTags: tags,
                    note: row[momentNote],
                    sourceDataSourceId: row[momentSourceId].flatMap { UUID(uuidString: $0) }
                )
                moments.append(moment)
            }
        } catch {
            print("Error fetching moments: \(error)")
        }

        return moments
    }

    func fetchMoments(for date: Date) -> [Moment] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { return [] }

        return fetchAllMoments().filter { moment in
            moment.timestamp >= startOfDay && moment.timestamp < endOfDay
        }
    }

    func deleteMoment(id: UUID) throws {
        guard let db = db else { return }
        let moment = momentsTable.filter(momentId == id.uuidString)
        try db.run(moment.delete())
    }

    func deleteAllMoments() throws {
        guard let db = db else { return }
        try db.run(momentsTable.delete())
    }

    func momentsCount() -> Int {
        guard let db = db else { return 0 }
        return (try? db.scalar(momentsTable.count)) ?? 0
    }

    // MARK: - Data Sources

    func insertDataSource(_ ds: DataSource) throws {
        guard let db = db else { return }

        try db.run(dataSourcesTable.insert(or: .replace,
            dsId <- ds.id.uuidString,
            dsType <- ds.type.rawValue,
            dsIsConnected <- ds.isConnected,
            dsLastSynced <- ds.lastSyncedAt,
            dsDataPointCount <- ds.dataPointCount
        ))
    }

    func fetchAllDataSources() -> [DataSource] {
        guard let db = db else { return [] }

        var sources: [DataSource] = []
        do {
            for row in try db.prepare(dataSourcesTable) {
                let ds = DataSource(
                    id: UUID(uuidString: row[dsId]) ?? UUID(),
                    type: DataSourceType(rawValue: row[dsType]) ?? .journal,
                    isConnected: row[dsIsConnected],
                    lastSyncedAt: row[dsLastSynced],
                    dataPointCount: row[dsDataPointCount]
                )
                sources.append(ds)
            }
        } catch {
            print("Error fetching data sources: \(error)")
        }
        return sources
    }

    func updateDataSource(_ ds: DataSource) throws {
        guard let db = db else { return }
        let target = dataSourcesTable.filter(dsId == ds.id.uuidString)
        try db.run(target.update(
            dsIsConnected <- ds.isConnected,
            dsLastSynced <- ds.lastSyncedAt,
            dsDataPointCount <- ds.dataPointCount
        ))
    }

    func deleteAllDataSources() throws {
        guard let db = db else { return }
        try db.run(dataSourcesTable.delete())
    }

    // MARK: - Insights

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

    func fetchRecentInsights(limit: Int = 5) -> [Insight] {
        guard let db = db else { return [] }

        var insights: [Insight] = []
        do {
            for row in try db.prepare(insightsTable.order(insightCreatedAt.desc).limit(limit)) {
                let insight = Insight(
                    id: UUID(uuidString: row[insightId]) ?? UUID(),
                    title: row[insightTitle],
                    body: row[insightBody],
                    category: InsightCategory(rawValue: row[insightCategory]) ?? .general,
                    createdAt: row[insightCreatedAt],
                    supportingDataPointCount: row[insightDataPointCount],
                    emotionScore: row[insightEmotionScore]
                )
                insights.append(insight)
            }
        } catch {
            print("Error fetching insights: \(error)")
        }
        return insights
    }

    func deleteAllInsights() throws {
        guard let db = db else { return }
        try db.run(insightsTable.delete())
    }

    // MARK: - Statistics

    func dataSummary() -> (photos: Int, voiceNotes: Int, journalEntries: Int) {
        let moments = fetchAllMoments()
        let photos = moments.filter { $0.type == .photo }.count
        let voiceNotes = moments.filter { $0.type == .voice }.count
        let journalEntries = moments.filter { $0.type == .journal }.count
        return (photos, voiceNotes, journalEntries)
    }

    func averageEmotionScore(forDays days: Int) -> Double {
        let calendar = Calendar.current
        guard let startDate = calendar.date(byAdding: .day, value: -days, to: Date()) else { return 0 }
        let moments = fetchAllMoments().filter { $0.timestamp >= startDate }
        guard !moments.isEmpty else { return 0 }
        return moments.map(\.emotionScore).reduce(0, +) / Double(moments.count)
    }

    func exportAllData() -> Data? {
        let moments = fetchAllMoments()
        let dataSources = fetchAllDataSources()
        let insights = fetchRecentInsights(limit: 100)

        let exportData: [String: Any] = [
            "exportDate": ISO8601DateFormatter().string(from: Date()),
            "moments": moments.map { m -> [String: Any] in
                [
                    "id": m.id.uuidString,
                    "type": m.type.rawValue,
                    "timestamp": ISO8601DateFormatter().string(from: m.timestamp),
                    "emotionScore": m.emotionScore,
                    "emotionTags": m.emotionTags.map { ["category": $0.category.rawValue, "confidence": $0.confidence] },
                    "note": m.note ?? ""
                ]
            },
            "dataSources": dataSources.map { ds -> [String: Any] in
                [
                    "type": ds.type.rawValue,
                    "isConnected": ds.isConnected,
                    "dataPointCount": ds.dataPointCount
                ]
            },
            "insights": insights.map { i -> [String: Any] in
                [
                    "title": i.title,
                    "body": i.body,
                    "category": i.category.rawValue,
                    "createdAt": ISO8601DateFormatter().string(from: i.createdAt)
                ]
            }
        ]

        return try? JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted)
    }
}
