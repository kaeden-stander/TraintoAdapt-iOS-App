import Foundation
import HealthKit

/// Reads activity and workout data from Apple Health so a client's Apple
/// Watch data (steps, heart rate, active energy, workouts) shows up in the
/// app automatically — the Watch already syncs into HealthKit on its own,
/// so no separate watchOS companion app is required for this. A watchOS
/// target can be added later (see README) if TrainToAdapt wants an on-wrist
/// experience such as starting a booked session directly from the wrist.
@MainActor
final class HealthKitManager: ObservableObject {
    static let shared = HealthKitManager()

    @Published private(set) var isAuthorized = false
    @Published private(set) var todaySummary: DailyHealthSummary = .empty
    @Published private(set) var recentWorkouts: [WorkoutSample] = []
    @Published private(set) var lastError: String?

    private let healthStore = HKHealthStore()

    private var readTypes: Set<HKObjectType> {
        var types: Set<HKObjectType> = [
            HKObjectType.workoutType()
        ]
        if let steps = HKObjectType.quantityType(forIdentifier: .stepCount) {
            types.insert(steps)
        }
        if let energy = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) {
            types.insert(energy)
        }
        if let heartRate = HKObjectType.quantityType(forIdentifier: .heartRate) {
            types.insert(heartRate)
        }
        if let restingHeartRate = HKObjectType.quantityType(forIdentifier: .restingHeartRate) {
            types.insert(restingHeartRate)
        }
        if let exerciseTime = HKObjectType.quantityType(forIdentifier: .appleExerciseTime) {
            types.insert(exerciseTime)
        }
        return types
    }

    var isHealthDataAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    func requestAuthorization() async {
        guard isHealthDataAvailable else {
            lastError = "Health data isn't available on this device."
            return
        }
        do {
            try await healthStore.requestAuthorization(toShare: [], read: readTypes)
            isAuthorized = true
            lastError = nil
            await refreshAll()
        } catch {
            lastError = error.localizedDescription
        }
    }

    func refreshAll() async {
        async let steps = fetchTodayStepCount()
        async let energy = fetchTodayActiveEnergy()
        async let heartRate = fetchTodayAverageHeartRate()
        async let resting = fetchLatestRestingHeartRate()
        async let exercise = fetchTodayExerciseMinutes()
        async let workouts = fetchRecentWorkouts(limit: 10)

        let summary = DailyHealthSummary(
            date: .now,
            steps: await steps,
            activeEnergyKcal: await energy,
            averageHeartRate: await heartRate,
            restingHeartRate: await resting,
            exerciseMinutes: await exercise
        )
        todaySummary = summary
        recentWorkouts = await workouts
    }

    // MARK: - Queries

    private func fetchTodayStepCount() async -> Int {
        guard let type = HKObjectType.quantityType(forIdentifier: .stepCount) else { return 0 }
        let sum = await sumQuantity(for: type, unit: .count(), predicate: .today())
        return Int(sum)
    }

    private func fetchTodayActiveEnergy() async -> Double {
        guard let type = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) else { return 0 }
        return await sumQuantity(for: type, unit: .kilocalorie(), predicate: .today())
    }

    private func fetchTodayExerciseMinutes() async -> Int {
        guard let type = HKObjectType.quantityType(forIdentifier: .appleExerciseTime) else { return 0 }
        let sum = await sumQuantity(for: type, unit: .minute(), predicate: .today())
        return Int(sum)
    }

    private func fetchTodayAverageHeartRate() async -> Double? {
        guard let type = HKObjectType.quantityType(forIdentifier: .heartRate) else { return nil }
        return await averageQuantity(for: type, unit: HKUnit.count().unitDivided(by: .minute()), predicate: .today())
    }

    private func fetchLatestRestingHeartRate() async -> Double? {
        guard let type = HKObjectType.quantityType(forIdentifier: .restingHeartRate) else { return nil }
        return await mostRecentQuantity(for: type, unit: HKUnit.count().unitDivided(by: .minute()))
    }

    private func fetchRecentWorkouts(limit: Int) async -> [WorkoutSample] {
        await withCheckedContinuation { continuation in
            let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
            let query = HKSampleQuery(sampleType: .workoutType(), predicate: nil, limit: limit, sortDescriptors: [sort]) { _, samples, _ in
                let energyType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)
                let workouts = (samples as? [HKWorkout] ?? []).map { workout -> WorkoutSample in
                    let energy = energyType.flatMap { workout.statistics(for: $0) }?
                        .sumQuantity()?.doubleValue(for: .kilocalorie())
                    return WorkoutSample(
                        activityName: workout.workoutActivityType.displayName,
                        start: workout.startDate,
                        end: workout.endDate,
                        totalEnergyKcal: energy,
                        averageHeartRate: nil,
                        source: workout.sourceRevision.source.name
                    )
                }
                continuation.resume(returning: workouts)
            }
            healthStore.execute(query)
        }
    }

    private func sumQuantity(for type: HKQuantityType, unit: HKUnit, predicate: NSPredicate) async -> Double {
        await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, statistics, _ in
                continuation.resume(returning: statistics?.sumQuantity()?.doubleValue(for: unit) ?? 0)
            }
            healthStore.execute(query)
        }
    }

    private func averageQuantity(for type: HKQuantityType, unit: HKUnit, predicate: NSPredicate) async -> Double? {
        await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .discreteAverage) { _, statistics, _ in
                continuation.resume(returning: statistics?.averageQuantity()?.doubleValue(for: unit))
            }
            healthStore.execute(query)
        }
    }

    private func mostRecentQuantity(for type: HKQuantityType, unit: HKUnit) async -> Double? {
        await withCheckedContinuation { continuation in
            let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
            let query = HKSampleQuery(sampleType: type, predicate: nil, limit: 1, sortDescriptors: [sort]) { _, samples, _ in
                let value = (samples?.first as? HKQuantitySample)?.quantity.doubleValue(for: unit)
                continuation.resume(returning: value)
            }
            healthStore.execute(query)
        }
    }
}

private extension NSPredicate {
    static func today() -> NSPredicate {
        let start = Calendar.current.startOfDay(for: .now)
        return HKQuery.predicateForSamples(withStart: start, end: .now, options: .strictStartDate)
    }
}

private extension HKWorkoutActivityType {
    var displayName: String {
        switch self {
        case .traditionalStrengthTraining, .functionalStrengthTraining: "Strength Training"
        case .running: "Running"
        case .walking: "Walking"
        case .cycling: "Cycling"
        case .rowing: "Rowing"
        case .wheelchairWalkPace, .wheelchairRunPace: "Wheelchair Training"
        case .yoga: "Yoga"
        case .highIntensityIntervalTraining: "HIIT"
        case .swimming: "Swimming"
        default: "Workout"
        }
    }
}
