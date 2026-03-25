import Foundation
import HealthKit

struct HealthData: Codable, Sendable {
    let hrvAverage: Double?
    let sleepDuration: Double?
    let stepCount: Int
    let restingHeartRate: Double?
    let date: Date

    var normalizedScore: Double {
        var score: Double = 0.5

        // HRV: higher is generally better (stress resilience)
        if let hrv = hrvAverage {
            // Normalize HRV to 0-1 (typical range 20-100ms)
            score += (hrv - 40) / 80.0 * 0.3
        }

        // Sleep: 7-9 hours is optimal
        if let sleep = sleepDuration {
            let optimalSleep = min(abs(sleep - 7), abs(sleep - 9))
            score += (1 - optimalSleep / 3.0) * 0.3
        }

        // Steps: 10k is a good target
        score += min(Double(stepCount) / 10000.0, 1.0) * 0.2

        // RHR: lower can indicate better fitness (50-80 typical)
        if let rhr = restingHeartRate {
            score += (80 - rhr) / 40.0 * 0.2
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
        async let steps = fetchStepCount(from: startOfDay, to: endOfDay)
        async let rhr = fetchRestingHeartRate(from: startOfDay, to: endOfDay)

        let results = await (hrv, sleep, steps, rhr)

        guard results.0 != nil || results.1 != nil || results.2 > 0 || results.3 != nil else {
            return nil
        }

        return HealthData(
            hrvAverage: results.0,
            sleepDuration: results.1,
            stepCount: results.2,
            restingHeartRate: results.3,
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
}
