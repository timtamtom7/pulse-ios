import Foundation
import AVFoundation
import Accelerate

struct VoiceToneResult: Sendable {
    let averagePitch: Double?
    let pitchVariance: Double
    let speechRate: Double
    let dominantFrequency: Double?
    let stressLevel: Double
    let energy: Double

    var paceLabel: String {
        if speechRate > 5.0 { return "Fast" }
        if speechRate > 3.5 { return "Moderate" }
        if speechRate > 2.0 { return "Slow" }
        return "Very slow"
    }

    var stressLabel: String {
        if stressLevel > 0.7 { return "High stress" }
        if stressLevel > 0.4 { return "Moderate" }
        if stressLevel > 0.2 { return "Calm" }
        return "Very relaxed"
    }

    var emotionalTags: [EmotionTag] {
        var tags: [EmotionTag] = []

        if stressLevel > 0.6 {
            tags.append(EmotionTag(category: .fear, confidence: stressLevel, label: "Tension"))
        }

        if energy > 0.7 {
            tags.append(EmotionTag(category: .joy, confidence: energy, label: "High energy"))
        } else if energy < 0.3 {
            tags.append(EmotionTag(category: .sadness, confidence: 1 - energy, label: "Low energy"))
        }

        if pitchVariance < 0.2 && stressLevel < 0.3 {
            tags.append(EmotionTag(category: .neutral, confidence: 0.7, label: "Monotone"))
        }

        if speechRate > 5.0 {
            tags.append(EmotionTag(category: .anticipation, confidence: 0.6, label: "Excited pace"))
        }

        return tags
    }
}

actor VoiceToneAnalysisService {
    static let shared = VoiceToneAnalysisService()

    private init() {}

    func analyzeTone(audioURL: URL) async -> VoiceToneResult {
        guard let audioData = try? Data(contentsOf: audioURL) else {
            return defaultResult()
        }

        let samples = extractSamples(from: audioData)
        guard !samples.isEmpty else { return defaultResult() }

        let pitchData = extractPitchData(from: samples)
        let energy = computeEnergy(from: samples)
        let speechRate = estimateSpeechRate(from: audioURL)

        let stressLevel = computeStressLevel(pitchVariance: pitchData.variance, energy: energy)

        return VoiceToneResult(
            averagePitch: pitchData.average,
            pitchVariance: pitchData.variance,
            speechRate: speechRate,
            dominantFrequency: pitchData.dominant,
            stressLevel: stressLevel,
            energy: energy
        )
    }

    private func defaultResult() -> VoiceToneResult {
        VoiceToneResult(
            averagePitch: nil,
            pitchVariance: 0.3,
            speechRate: 3.5,
            dominantFrequency: nil,
            stressLevel: 0.3,
            energy: 0.5
        )
    }

    private func extractSamples(from audioData: Data) -> [Float] {
        var samples: [Float] = []

        // Simple PCM extraction from M4A/AAC
        // This is a simplified approach - in production we'd use AVAssetReader
        let floatCount = audioData.count / 2
        var floatSamples = [Float](repeating: 0, count: floatCount)

        audioData.withUnsafeBytes { buffer in
            guard let ptr = buffer.baseAddress else { return }
            let int16Ptr = ptr.assumingMemoryBound(to: Int16.self)
            for i in 0..<floatCount {
                floatSamples[i] = Float(int16Ptr[i]) / Float(Int16.max)
            }
        }

        // Downsample for analysis
        let targetLength = 8000
        if floatSamples.count > targetLength {
            let step = floatSamples.count / targetLength
            for i in stride(from: 0, to: floatSamples.count, by: step) {
                samples.append(floatSamples[i])
                if samples.count >= targetLength { break }
            }
        } else {
            samples = floatSamples
        }

        return samples
    }

    private struct PitchData {
        let average: Double?
        let variance: Double
        let dominant: Double?
    }

    private func extractPitchData(from samples: [Float]) -> PitchData {
        guard samples.count > 100 else {
            return PitchData(average: nil, variance: 0.3, dominant: nil)
        }

        // Autocorrelation-based pitch detection
        let frameSize = 1024
        var pitchValues: [Double] = []

        for frameStart in stride(from: 0, to: samples.count - frameSize, by: frameSize) {
            let frame = Array(samples[frameStart..<(frameStart + frameSize)])

            // Simple zero-crossing rate as proxy for pitch
            var zeroCrossings = 0
            for i in 1..<frame.count {
                if (frame[i] >= 0 && frame[i-1] < 0) || (frame[i] < 0 && frame[i-1] >= 0) {
                    zeroCrossings += 1
                }
            }

            let sampleRate: Double = 8000
            let duration = Double(frame.count) / sampleRate
            let zeroCrossingRate = Double(zeroCrossings) / (2.0 * duration)

            // Rough fundamental frequency estimate from zero-crossing rate
            if zeroCrossingRate > 50 && zeroCrossingRate < 500 {
                pitchValues.append(zeroCrossingRate)
            }
        }

        guard !pitchValues.isEmpty else {
            return PitchData(average: nil, variance: 0.3, dominant: nil)
        }

        let average = pitchValues.reduce(0, +) / Double(pitchValues.count)

        let variance = pitchValues.reduce(0.0) { sum, p in
            sum + (p - average) * (p - average)
        } / Double(pitchValues.count)

        // Sort to find dominant
        let sorted = pitchValues.sorted()
        let dominant = sorted[sorted.count / 2]

        // Normalize variance (lower variance = more regular/stressed)
        let normalizedVariance = min(variance / (average * average + 1), 1.0)

        return PitchData(average: average, variance: normalizedVariance, dominant: dominant)
    }

    private func computeEnergy(from samples: [Float]) -> Double {
        guard !samples.isEmpty else { return 0.5 }

        var sumSquares: Float = 0
        vDSP_measqv(samples, 1, &sumSquares, vDSP_Length(samples.count))

        let rms = sqrt(sumSquares / Float(samples.count))

        // Normalize to 0-1 (assuming typical voice RMS range)
        let normalizedEnergy = min(max(Double(rms) * 5, 0), 1)
        return normalizedEnergy
    }

    private func estimateSpeechRate(from audioURL: URL) -> Double {
        // This would ideally use speech recognition timing data
        // For now, estimate based on audio duration heuristics
        // Return syllables per second estimate
        return 3.5
    }

    private func computeStressLevel(pitchVariance: Double, energy: Double) -> Double {
        // Lower pitch variance + higher energy often indicates stress
        // Higher pitch variance + moderate energy indicates normal/positive
        let varianceComponent = 1.0 - pitchVariance
        let energyComponent = energy

        return (varianceComponent * 0.4 + energyComponent * 0.6)
    }
}
