import Foundation
import PDFKit
import UIKit

/// Service for exporting your full emotional life as a document (Legacy Export)
/// R9: Legacy Export feature
final class LegacyExportService: @unchecked Sendable {
    static let shared = LegacyExportService()

    private let databaseService = DatabaseService.shared

    private init() {}

    // MARK: - Export Types

    enum ExportFormat {
        case pdf
        case json
        case markdown

        var fileExtension: String {
            switch self {
            case .pdf: return "pdf"
            case .json: return "json"
            case .markdown: return "md"
            }
        }

        var mimeType: String {
            switch self {
            case .pdf: return "application/pdf"
            case .json: return "application/json"
            case .markdown: return "text/markdown"
            }
        }
    }

    struct ExportMetadata: Codable {
        let exportDate: Date
        let dateRangeStart: Date
        let dateRangeEnd: Date
        let totalMoments: Int
        let photoCount: Int
        let voiceCount: Int
        let journalCount: Int
        let averageEmotionScore: Double
        let dominantEmotion: String
        let totalDays: Int
        let streakDays: Int
        let insightsCount: Int
    }

    struct LegacyDocument {
        let metadata: ExportMetadata
        let moments: [Moment]
        let insights: [Insight]
        let familySummaries: [FamilyCircleService.FamilyWeeklySummary]
        let url: URL
    }

    // MARK: - Export

    @MainActor
    func export(format: ExportFormat) async throws -> URL {
        let moments = databaseService.fetchAllMoments()
        let insights = databaseService.fetchRecentInsights(limit: 100)

        let (startDate, endDate) = dateRange(for: moments)

        let metadata = ExportMetadata(
            exportDate: Date(),
            dateRangeStart: startDate,
            dateRangeEnd: endDate,
            totalMoments: moments.count,
            photoCount: moments.filter { $0.type == .photo }.count,
            voiceCount: moments.filter { $0.type == .voice }.count,
            journalCount: moments.filter { $0.type == .journal }.count,
            averageEmotionScore: moments.isEmpty ? 0 : moments.map(\.emotionScore).reduce(0, +) / Double(moments.count),
            dominantEmotion: calculateDominantEmotion(moments: moments),
            totalDays: Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 0,
            streakDays: calculateLongestStreak(moments: moments),
            insightsCount: insights.count
        )

        switch format {
        case .pdf:
            return try await generatePDF(metadata: metadata, moments: moments, insights: insights)
        case .json:
            return try generateJSON(metadata: metadata, moments: moments, insights: insights)
        case .markdown:
            return try generateMarkdown(metadata: metadata, moments: moments, insights: insights)
        }
    }

    // MARK: - PDF Generation

    private func generatePDF(metadata: ExportMetadata, moments: [Moment], insights: [Insight]) async throws -> URL {
        let pdfMetaData = [
            kCGPDFContextCreator: "Pulse",
            kCGPDFContextAuthor: "Pulse App",
            kCGPDFContextTitle: "My Emotional Life — Pulse Export"
        ]

        let pdfFormat = UIGraphicsPDFRendererFormat()
        pdfFormat.documentInfo = pdfMetaData as [String: Any]

        let pageWidth: CGFloat = 612 // US Letter
        let pageHeight: CGFloat = 792
        let margin: CGFloat = 72 // 1 inch margins
        let contentWidth = pageWidth - margin * 2

        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight), format: pdfFormat)

        let data = renderer.pdfData { context in
            var yPosition: CGFloat = margin

            // MARK: Page 1: Cover
            context.beginPage()
            yPosition = margin

            // Title
            let titleFont = UIFont.systemFont(ofSize: 36, weight: .bold)
            let title = "My Emotional Life"
            let titleRect = CGRect(x: margin, y: yPosition, width: contentWidth, height: 60)
            title.draw(in: titleRect, withAttributes: [
                .font: titleFont,
                .foregroundColor: UIColor(red: 0.24, green: 0.21, blue: 0.19, alpha: 1)
            ])
            yPosition += 70

            let subtitleFont = UIFont.systemFont(ofSize: 18, weight: .regular)
            let subtitle = "A Pulse Emotional Journey"
            let subtitleRect = CGRect(x: margin, y: yPosition, width: contentWidth, height: 30)
            subtitle.draw(in: subtitleRect, withAttributes: [
                .font: subtitleFont,
                .foregroundColor: UIColor(red: 0.55, green: 0.48, blue: 0.46, alpha: 1)
            ])
            yPosition += 60

            // Date range
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMMM d, yyyy"

            let dateRangeText = "\(dateFormatter.string(from: metadata.dateRangeStart)) — \(dateFormatter.string(from: metadata.dateRangeEnd))"
            let dateRect = CGRect(x: margin, y: yPosition, width: contentWidth, height: 20)
            dateRangeText.draw(in: dateRect, withAttributes: [
                .font: UIFont.systemFont(ofSize: 14),
                .foregroundColor: UIColor(red: 0.55, green: 0.48, blue: 0.46, alpha: 1)
            ])
            yPosition += 80

            // Stats grid
            let stats = [
                ("\(metadata.totalMoments)", "Moments"),
                ("\(metadata.photoCount)", "Photos"),
                ("\(metadata.voiceCount)", "Voice Notes"),
                ("\(metadata.journalCount)", "Journal Entries"),
                ("\(Int(metadata.averageEmotionScore * 100))%", "Avg Score"),
                ("\(metadata.streakDays)", "Best Streak")
            ]

            let statWidth = contentWidth / 3
            for (index, stat) in stats.enumerated() {
                let col = index % 3
                let row = index / 3
                let x = margin + CGFloat(col) * statWidth
                let statY = yPosition + CGFloat(row) * 60

                let valueRect = CGRect(x: x, y: statY, width: statWidth - 10, height: 30)
                let valueText = stat.0
                valueText.draw(in: valueRect, withAttributes: [
                    .font: UIFont.systemFont(ofSize: 24, weight: .bold),
                    .foregroundColor: UIColor(red: 0.24, green: 0.21, blue: 0.19, alpha: 1)
                ])

                let labelRect = CGRect(x: x, y: statY + 28, width: statWidth - 10, height: 20)
                stat.1.draw(in: labelRect, withAttributes: [
                    .font: UIFont.systemFont(ofSize: 12),
                    .foregroundColor: UIColor(red: 0.55, green: 0.48, blue: 0.46, alpha: 1)
                ])
            }

            yPosition += 160

            // Dominant emotion
            let emotionText = "Your dominant emotion: \(metadata.dominantEmotion)"
            let emotionRect = CGRect(x: margin, y: yPosition, width: contentWidth, height: 20)
            emotionText.draw(in: emotionRect, withAttributes: [
                .font: UIFont.systemFont(ofSize: 14, weight: .medium),
                .foregroundColor: UIColor(red: 0.61, green: 0.68, blue: 0.53, alpha: 1)
            ])

            // MARK: Page 2: Timeline
            context.beginPage()
            yPosition = margin

            let sectionTitle = "Your Emotional Timeline"
            sectionTitle.draw(at: CGPoint(x: margin, y: yPosition), withAttributes: [
                .font: UIFont.systemFont(ofSize: 24, weight: .bold),
                .foregroundColor: UIColor(red: 0.24, green: 0.21, blue: 0.19, alpha: 1)
            ])
            yPosition += 50

            let groupedByDate = Dictionary(grouping: moments) { moment in
                Calendar.current.startOfDay(for: moment.timestamp)
            }

            let sortedDates = groupedByDate.keys.sorted(by: >).prefix(30)

            for date in sortedDates {
                guard yPosition < pageHeight - 100 else { break }
                guard let dayMoments = groupedByDate[date] else { continue }

                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "EEEE, MMMM d, yyyy"
                let dateString = dateFormatter.string(from: date)

                dateString.draw(at: CGPoint(x: margin, y: yPosition), withAttributes: [
                    .font: UIFont.systemFont(ofSize: 12, weight: .bold),
                    .foregroundColor: UIColor(red: 0.55, green: 0.48, blue: 0.46, alpha: 1)
                ])
                yPosition += 20

                for moment in dayMoments.prefix(3) {
                    guard yPosition < pageHeight - 80 else { break }

                    let emotionLabel = moment.emotionTags.first?.label ?? "Neutral"
                    let timeFormatter = DateFormatter()
                    timeFormatter.timeStyle = .short
                    let timeString = timeFormatter.string(from: moment.timestamp)
                    let momentText = "  \(timeString) — \(moment.type.displayName) — \(emotionLabel)"

                    momentText.draw(at: CGPoint(x: margin, y: yPosition), withAttributes: [
                        .font: UIFont.systemFont(ofSize: 10),
                        .foregroundColor: UIColor(red: 0.24, green: 0.21, blue: 0.19, alpha: 1)
                    ])
                    yPosition += 14
                }

                yPosition += 10
            }

            // MARK: Page 3: Insights
            context.beginPage()
            yPosition = margin

            let insightsTitle = "Your Insights"
            insightsTitle.draw(at: CGPoint(x: margin, y: yPosition), withAttributes: [
                .font: UIFont.systemFont(ofSize: 24, weight: .bold),
                .foregroundColor: UIColor(red: 0.24, green: 0.21, blue: 0.19, alpha: 1)
            ])
            yPosition += 50

            for insight in insights.prefix(15) {
                guard yPosition < pageHeight - 80 else { break }

                insight.title.draw(at: CGPoint(x: margin, y: yPosition), withAttributes: [
                    .font: UIFont.systemFont(ofSize: 12, weight: .semibold),
                    .foregroundColor: UIColor(red: 0.24, green: 0.21, blue: 0.19, alpha: 1)
                ])
                yPosition += 18

                // Word wrap body
                let bodyFont = UIFont.systemFont(ofSize: 10)
                let bodyRect = CGRect(x: margin, y: yPosition, width: contentWidth, height: 40)
                insight.body.draw(in: bodyRect, withAttributes: [
                    .font: bodyFont,
                    .foregroundColor: UIColor(red: 0.55, green: 0.48, blue: 0.46, alpha: 1)
                ])
                yPosition += 45
            }

            // Footer
            let footerY = pageHeight - 50
            let footerText = "Exported from Pulse on \(DateFormatter.localizedString(from: Date(), dateStyle: .long, timeStyle: .short))"
            footerText.draw(at: CGPoint(x: margin, y: footerY), withAttributes: [
                .font: UIFont.systemFont(ofSize: 8),
                .foregroundColor: UIColor(red: 0.55, green: 0.48, blue: 0.46, alpha: 1)
            ])
        }

        let fileName = "Pulse_EmotionalLife_\(formattedDate()).pdf"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        try data.write(to: url)
        return url
    }

    // MARK: - JSON Generation

    private func generateJSON(metadata: ExportMetadata, moments: [Moment], insights: [Insight]) throws -> URL {
        let exportData: [String: Any] = [
            "app": "Pulse",
            "version": "1.0",
            "exportDate": ISO8601DateFormatter().string(from: metadata.exportDate),
            "dateRange": [
                "start": ISO8601DateFormatter().string(from: metadata.dateRangeStart),
                "end": ISO8601DateFormatter().string(from: metadata.dateRangeEnd)
            ],
            "summary": [
                "totalMoments": metadata.totalMoments,
                "photoCount": metadata.photoCount,
                "voiceCount": metadata.voiceCount,
                "journalCount": metadata.journalCount,
                "averageEmotionScore": metadata.averageEmotionScore,
                "dominantEmotion": metadata.dominantEmotion,
                "totalDays": metadata.totalDays,
                "streakDays": metadata.streakDays
            ],
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
            "insights": insights.map { i -> [String: Any] in
                [
                    "title": i.title,
                    "body": i.body,
                    "category": i.category.rawValue,
                    "createdAt": ISO8601DateFormatter().string(from: i.createdAt)
                ]
            }
        ]

        let data = try JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted)
        let fileName = "Pulse_Export_\(formattedDate()).json"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        try data.write(to: url)
        return url
    }

    // MARK: - Markdown Generation

    private func generateMarkdown(metadata: ExportMetadata, moments: [Moment], insights: [Insight]) throws -> URL {
        var markdown = """
        # My Emotional Life
        ## A Pulse Export

        **Exported:** \(DateFormatter.localizedString(from: metadata.exportDate, dateStyle: .long, timeStyle: .short))
        **Journey:** \(DateFormatter.localizedString(from: metadata.dateRangeStart, dateStyle: .medium, timeStyle: .none)) — \(DateFormatter.localizedString(from: metadata.dateRangeEnd, dateStyle: .medium, timeStyle: .none))

        ---

        ## Your Journey at a Glance

        | Metric | Value |
        |--------|-------|
        | Total Moments | \(metadata.totalMoments) |
        | Photos | \(metadata.photoCount) |
        | Voice Notes | \(metadata.voiceCount) |
        | Journal Entries | \(metadata.journalCount) |
        | Average Score | \(Int(metadata.averageEmotionScore * 100))% |
        | Dominant Emotion | \(metadata.dominantEmotion) |
        | Best Streak | \(metadata.streakDays) days |

        ---

        ## Your Emotional Timeline

        """

        let groupedByDate = Dictionary(grouping: moments) { moment in
            Calendar.current.startOfDay(for: moment.timestamp)
        }

        let sortedDates = groupedByDate.keys.sorted(by: >)

        for date in sortedDates.prefix(60) {
            guard let dayMoments = groupedByDate[date] else { continue }

            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "EEEE, MMMM d, yyyy"
            let dateString = dateFormatter.string(from: date)

            markdown += "### \(dateString)\n\n"

            for moment in dayMoments {
                let timeFormatter = DateFormatter()
                timeFormatter.timeStyle = .short
                let timeString = timeFormatter.string(from: moment.timestamp)
                let emotionLabel = moment.emotionTags.first?.label ?? "Neutral"
                let score = Int(moment.emotionScore * 100)

                markdown += "- **\(timeString)** — \(moment.type.displayName): \(emotionLabel) (\(score)%)\n"
                if let note = moment.note, !note.isEmpty {
                    markdown += "  > \(note)\n"
                }
            }

            markdown += "\n"
        }

        markdown += """

        ---

        ## Your Insights

        """

        for insight in insights {
            markdown += "### \(insight.title)\n\n\(insight.body)\n\n"
        }

        markdown += """

        ---

        *Exported with ♥ from Pulse*

        """

        let fileName = "Pulse_EmotionalLife_\(formattedDate()).md"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        try markdown.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    // MARK: - Helpers

    private func dateRange(for moments: [Moment]) -> (Date, Date) {
        guard let first = moments.last, let last = moments.first else {
            return (Date(), Date())
        }
        return (first.timestamp, last.timestamp)
    }

    private func calculateDominantEmotion(moments: [Moment]) -> String {
        var counts: [EmotionCategory: Int] = [:]
        for moment in moments {
            for tag in moment.emotionTags {
                counts[tag.category, default: 0] += 1
            }
        }
        return counts.max(by: { $0.value < $1.value })?.key.displayName ?? "Neutral"
    }

    private func calculateLongestStreak(moments: [Moment]) -> Int {
        let calendar = Calendar.current
        let uniqueDays = Set(moments.map { calendar.startOfDay(for: $0.timestamp) })
        let sortedDays = uniqueDays.sorted(by: >)

        var longestStreak = 0
        var currentStreak = 0
        var previousDay: Date?

        for day in sortedDays {
            if let prev = previousDay {
                let diff = calendar.dateComponents([.day], from: day, to: prev).day ?? 0
                if diff == 1 {
                    currentStreak += 1
                } else {
                    longestStreak = max(longestStreak, currentStreak)
                    currentStreak = 1
                }
            } else {
                currentStreak = 1
            }
            previousDay = day
        }

        return max(longestStreak, currentStreak)
    }

    private func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
}
