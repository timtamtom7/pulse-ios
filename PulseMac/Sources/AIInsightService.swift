import Foundation
import NaturalLanguage

// MARK: - AI Insight Service

final class AIInsightService: @unchecked Sendable {
    static let shared = AIInsightService()

    private init() {}

    // MARK: - Weekly Analysis

    func generateWeeklyAnalysis(entries: [Moment]) -> AIInsight {
        guard !entries.isEmpty else {
            return AIInsight(
                summary: "Start capturing moments to receive AI-powered emotional insights.",
                dominantEmotion: .neutral,
                emotionalArc: "Not enough data yet",
                patterns: [],
                advice: "Try logging how you feel each day — the more data, the sharper the insights."
            )
        }

        let dominantEmotion = detectDominantEmotion(from: entries)
        let emotionalArc = generateEmotionalArc(from: entries)
        let patterns = PatternDetectionService.shared.detectPatterns(in: entries)
        let advice = generateAdvice(patterns: patterns, dominantEmotion: dominantEmotion)

        let avgScore = entries.map(\.emotionScore).reduce(0, +) / Double(entries.count)
        let summary = generateSummary(entries: entries, avgScore: avgScore, dominantEmotion: dominantEmotion)

        return AIInsight(
            summary: summary,
            dominantEmotion: dominantEmotion,
            emotionalArc: emotionalArc,
            patterns: patterns,
            advice: advice
        )
    }

    // MARK: - Sentiment Analysis

    func analyzeSentiment(text: String) -> Double {
        let tagger = NLTagger(tagSchemes: [.sentimentScore])
        tagger.string = text

        var totalScore: Double = 0
        var count = 0

        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .paragraph, scheme: .sentimentScore, options: []) { tag, _ in
            if let tag = tag, let score = Double(tag.rawValue) {
                totalScore += score
                count += 1
            }
            return true
        }

        return count > 0 ? totalScore / Double(count) : 0
    }

    // MARK: - Dominant Emotion Detection

    private func detectDominantEmotion(from entries: [Moment]) -> EmotionCategory {
        var emotionFrequency: [EmotionCategory: (count: Int, totalConfidence: Double)] = [:]

        for entry in entries {
            for tag in entry.emotionTags {
                let existing = emotionFrequency[tag.category] ?? (0, 0)
                emotionFrequency[tag.category] = (existing.count + 1, existing.totalConfidence + tag.confidence)
            }
        }

        guard let dominant = emotionFrequency.max(by: {
            let lhs = Double($0.value.count) * $0.value.totalConfidence
            let rhs = Double($1.value.count) * $1.value.totalConfidence
            return lhs < rhs
        }) else {
            return .neutral
        }

        return dominant.key
    }

    // MARK: - Emotional Arc

    private func generateEmotionalArc(from entries: [Moment]) -> String {
        let calendar = Calendar.current
        let sortedEntries = entries.sorted { $0.timestamp < $1.timestamp }

        guard !sortedEntries.isEmpty else { return "Not enough data" }

        // Find the peak day
        var dayScores: [(date: Date, score: Double, count: Int)] = []
        let grouped = Dictionary(grouping: sortedEntries) { entry in
            calendar.startOfDay(for: entry.timestamp)
        }

        for (date, dayEntries) in grouped {
            let avgScore = dayEntries.map(\.emotionScore).reduce(0, +) / Double(dayEntries.count)
            dayScores.append((date, avgScore, dayEntries.count))
        }

        dayScores.sort { $0.date < $1.date }

        guard let peakDay = dayScores.max(by: { $0.score < $1.score }) else {
            return "Your emotional week shows a consistent pattern."
        }

        guard let troughDay = dayScores.min(by: { $0.score < $1.score }) else {
            return "Your emotional week shows a consistent pattern."
        }

        let peakDayName = dayName(for: peakDay.date)
        let troughDayName = dayName(for: troughDay.date)

        let scoreDiff = peakDay.score - troughDay.score

        if scoreDiff < 0.2 {
            return "Your week stayed emotionally steady — no major highs or lows."
        }

        if peakDay.date > troughDay.date {
            return "Your week climbed from \(troughDayName) (\(scoreLabel(troughDay.score))) to \(peakDayName) (\(scoreLabel(peakDay.score)))."
        } else {
            return "Your week peaked on \(peakDayName) (\(scoreLabel(peakDay.score))), with a dip on \(troughDayName)."
        }
    }

    // MARK: - Summary Generation

    private func generateSummary(entries: [Moment], avgScore: Double, dominantEmotion: EmotionCategory) -> String {
        let entryCount = entries.count
        let dayCount = Set(entries.map { Calendar.current.startOfDay(for: $0.timestamp) }).count

        let scoreDesc: String
        if avgScore > 0.5 {
            scoreDesc = "a notably positive"
        } else if avgScore > 0.1 {
            scoreDesc = "a moderately positive"
        } else if avgScore > -0.1 {
            scoreDesc = "a balanced"
        } else if avgScore > -0.5 {
            scoreDesc = "a challenging"
        } else {
            scoreDesc = "a difficult"
        }

        return "Across \(entryCount) moment\(entryCount == 1 ? "" : "s") spanning \(dayCount) day\(dayCount == 1 ? "" : "s"), your emotional landscape was \(scoreDesc) one, dominated by \(dominantEmotion.displayName.lowercased())."
    }

    // MARK: - Advice Generation

    private func generateAdvice(patterns: [String], dominantEmotion: EmotionCategory) -> String {
        var advice: [String] = []

        switch dominantEmotion {
        case .joy, .trust, .anticipation:
            advice.append("Your positive emotional baseline is strong. Consider what external factors are supporting this — and how to protect them.")
        case .sadness:
            advice.append("You've been carrying some heaviness. Small rituals — a walk, a call with someone you trust — can gently lift the weight.")
        case .anger:
            advice.append("Frustration may be building. Identifying the source can help transform it from a general background hum into something actionable.")
        case .fear:
            advice.append("Anxiety often points to something unresolved. Naming it — even just to yourself — reduces its power.")
        case .disgust:
            advice.append("Strong dislikes can be revealing. What in your environment or routine might be contributing?")
        case .surprise:
            advice.append("Unexpected moments keep life interesting. Lean into curiosity — it often leads somewhere meaningful.")
        case .neutral:
            advice.append("A neutral state is a canvas. Small intentional actions — gratitude, movement, connection — can tip it toward growth.")
        }

        if patterns.contains(where: { $0.lowercased().contains("morning") }) {
            advice.append("Your mornings set the tone. A calming morning routine could amplify your day.")
        }

        if patterns.contains(where: { $0.lowercased().contains("evening") }) {
            advice.append("Evenings seem significant for you. Consider a wind-down practice to process the day.")
        }

        if patterns.contains(where: { $0.lowercased().contains("streak") }) {
            advice.append("Your consistency is paying off — keep the streak alive.")
        }

        return advice.joined(separator: " ")
    }

    // MARK: - Helpers

    private func dayName(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }

    private func scoreLabel(_ score: Double) -> String {
        if score > 0.5 { return "high" }
        if score > 0.1 { return "moderate" }
        if score > -0.1 { return "neutral" }
        if score > -0.5 { return "low" }
        return "very low"
    }
}

// MARK: - AI Insight Model

struct AIInsight: Identifiable {
    let id = UUID()
    let summary: String
    let dominantEmotion: EmotionCategory
    let emotionalArc: String
    let patterns: [String]
    let advice: String

    var dominantEmotionColor: Color {
        dominantEmotion.color
    }

    var dominantEmotionLabel: String {
        dominantEmotion.displayName
    }
}

import SwiftUI
