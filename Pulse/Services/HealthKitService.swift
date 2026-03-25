import Foundation
import HealthKit

struct SleepStages: Codable, Sendable {
    let remMinutes: Double      // REM sleep in minutes
    let deepMinutes: Double      // Deep (slow-wave) sleep in minutes
    let coreMinutes: Double      // Core (light) sleep in minutes

    var totalMinutes: Double {
        remMinutes + deepMinutes + coreMinutes
    }

    var totalHours: Double {
        totalMinutes / 60.0
    }

    var remPercentage: Double {
        guard totalMinutes > 0 else { return 0 }
        return remMinutes / totalMinutes
    }

    var deepPercentage: Double {
        guard totalMinutes > 0 else { return 0 }
        return deepMinutes / totalMinutes
    }
}

struct HealthData: Codable, Sendable {
    let hrvAverage: Double?
    let sleepDuration: Double?   // Total sleep (kept for backwards compat)
    let sleepStages: SleepStages? // R3: sleep stage breakdown
    let stepCount: Int
    let restingHeartRate: Double?
    let respiratoryRate: Double?  // R3: breaths per minute
    let date: Date

    var normalizedScore: Double {
        var score: Double = 0.5

        // HRV: higher is generally better (stress resilience)
        if let hrv = hrvAverage {
            // Normalize HRV to 0-1 (typical range 20-100ms)
            score += (hrv - 40) / 80.0 * 0.25
        }

        // Sleep: 7-9 hours is optimal
        if let sleep = sleepDuration {
            let optimalSleep = min(abs(sleep - 7), abs(sleep - 9))
            score += (1 - optimalSleep / 3.0) * 0.2
        }

        // Sleep stages quality bonus (R3)
        if let stages = sleepStages {
            // Deep sleep should be ~15-25% of total for optimal
            let deepRatio = stages.deepPercentage
            let remRatio = stages.remPercentage
            score += min(deepRatio / 0.25, 1.0) * 0.1  // up to 10% for good deep sleep
            score += min(remRatio / 0.25, 1.0) * 0.05  // up to 5% for good REM
        }

        // Steps: 10k is a good target
        score += min(Double(stepCount) / 10000.0, 1.0) * 0.15

        // RHR: lower can indicate better fitness (50-80 typical)
        if let rhr = restingHeartRate {
            score += (80 - rhr) / 40.0 * 0.15
        }

        // Respiratory rate: 12-20 is normal, 14-18 is ideal (R3)
        if let rr = respiratoryRate {
            let idealRR = 16.0
            let deviation = abs(rr - idealRR)
            score += max(0, (20 - deviation) / 20.0) * 0.1
        }

        return max(0, min(1, score))
    }
}

@Observable
final class HealthKitService: @unchecked Sendable {
    static let shared = HealthKitService()

    private let healthStore = HKHealthStore()
    private(set) var isAuthorized = false

    private let typesToRead: Set<HKObjectType> = {
        var types = Set<HKObjectType>()
        if let hrvType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN) {
            types.insert(hrvType)
        }
        if let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) {
            types.insert(sleepType)
        }
        if let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) {
            types.insert(stepType)
        }
        if let rhrType = HKQuantityType.quantityType(forIdentifier: .restingHeartRate) {
            types.insert(rhrType)
        }
        // R3: Respiratory rate
        if let rrType = HKQuantityType.quantityType(forIdentifier: .respiratoryRate) {
            types.insert(rrType)
        }
        return types
    }()

    private init() {}

    var isHealthKitAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    func requestAuthorization() async -> Bool {
        guard isHealthKitAvailable else { return false }

        do {
            try await healthStore.requestAuthorization(toShare: [], read: typesToRead)
            let status = healthStore.authorizationStatus(for: HKQuantityType.quantityType(forIdentifier: .stepCount)!)
            await MainActor.run {
                isAuthorized = status != .notDetermined
            }
            return true
        } catch {
            return false
        }
    }

    func fetchHealthData(for date: Date) async -> HealthData? {
        guard isAuthorized else { return nil }

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { return nil }

        async let hrv = fetchHRV(from: startOfDay, to: endOfDay)
        async let sleep = fetchSleepDuration(from: startOfDay, to: endOfDay)
        async let sleepStages = fetchSleepStages(from: startOfDay, to: endOfDay)
        async let steps = fetchStepCount(from: startOfDay, to: endOfDay)
        async let rhr = fetchRestingHeartRate(from: startOfDay, to: endOfDay)
        async let rr = fetchRespiratoryRate(from: startOfDay, to: endOfDay)

        let results = await (hrv, sleep, sleepStages, steps, rhr, rr)

        guard results.0 != nil || results.1 != nil || results.2 != nil || results.3 > 0 || results.4 != nil || results.5 != nil else {
            return nil
        }

        return HealthData(
            hrvAverage: results.0,
            sleepDuration: results.1,
            sleepStages: results.2,
            stepCount: results.3,
            restingHeartRate: results.4,
            respiratoryRate: results.5,
            date: date
        )
    }

    private func fetchHRV(from start: Date, to end: Date) async -> Double? {
        guard let type = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN) else { return nil }

        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: .discreteAverage
            ) { _, statistics, _ in
                let value = statistics?.averageQuantity()?.doubleValue(for: HKUnit.secondUnit(with: .milli))
                continuation.resume(returning: value)
            }
            healthStore.execute(query)
        }
    }

    private func fetchSleepDuration(from start: Date, to end: Date) async -> Double? {
        guard let type = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) else { return nil }

        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, _ in
                let sleepSamples = samples as? [HKCategorySample] ?? []
                var totalSleep: TimeInterval = 0

                for sample in sleepSamples where sample.value == HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue ||
                    sample.value == HKCategoryValueSleepAnalysis.asleepCore.rawValue ||
                    sample.value == HKCategoryValueSleepAnalysis.asleepDeep.rawValue ||
                    sample.value == HKCategoryValueSleepAnalysis.asleepREM.rawValue {
                    totalSleep += sample.endDate.timeIntervalSince(sample.startDate)
                }

                let hours = totalSleep / 3600.0
                continuation.resume(returning: hours > 0 ? hours : nil)
            }
            healthStore.execute(query)
        }
    }

    private func fetchStepCount(from start: Date, to end: Date) async -> Int {
        guard let type = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return 0 }

        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, statistics, _ in
                let count = statistics?.sumQuantity()?.doubleValue(for: HKUnit.count()) ?? 0
                continuation.resume(returning: Int(count))
            }
            healthStore.execute(query)
        }
    }

    private func fetchRestingHeartRate(from start: Date, to end: Date) async -> Double? {
        guard let type = HKQuantityType.quantityType(forIdentifier: .restingHeartRate) else { return nil }

        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: .discreteAverage
            ) { _, statistics, _ in
                let value = statistics?.averageQuantity()?.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
                continuation.resume(returning: value)
            }
            healthStore.execute(query)
        }
    }

    // R3: Fetch sleep stage breakdown
    private func fetchSleepStages(from start: Date, to end: Date) async -> SleepStages? {
        guard let type = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) else { return nil }

        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, _ in
                let sleepSamples = samples as? [HKCategorySample] ?? []
                var remSeconds: TimeInterval = 0
                var deepSeconds: TimeInterval = 0
                var coreSeconds: TimeInterval = 0

                for sample in sleepSamples {
                    let duration = sample.endDate.timeIntervalSince(sample.startDate)
                    switch sample.value {
                    case HKCategoryValueSleepAnalysis.asleepREM.rawValue:
                        remSeconds += duration
                    case HKCategoryValueSleepAnalysis.asleepDeep.rawValue:
                        deepSeconds += duration
                    case HKCategoryValueSleepAnalysis.asleepCore.rawValue,
                         HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue:
                        coreSeconds += duration
                    default:
                        break
                    }
                }

                let stages = SleepStages(
                    remMinutes: remSeconds / 60.0,
                    deepMinutes: deepSeconds / 60.0,
                    coreMinutes: coreSeconds / 60.0
                )

                // Only return if we actually have sleep data
                continuation.resume(returning: stages.totalMinutes > 0 ? stages : nil)
            }
            healthStore.execute(query)
        }
    }

    // R3: Fetch respiratory rate
    private func fetchRespiratoryRate(from start: Date, to end: Date) async -> Double? {
        guard let type = HKQuantityType.quantityType(forIdentifier: .respiratoryRate) else { return nil }

        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: .discreteAverage
            ) { _, statistics, _ in
                // Respiratory rate is measured in breaths/minute
                let value = statistics?.averageQuantity()?.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
                continuation.resume(returning: value)
            }
            healthStore.execute(query)
        }
    }
}
