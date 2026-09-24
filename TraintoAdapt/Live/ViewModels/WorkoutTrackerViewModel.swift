import Foundation
import HealthKit

/// A simple in-app stopwatch for logging a workout without an Apple Watch —
/// start, optionally pause, and finish; the completed workout is written to
/// Apple Health via `HealthKitManager.saveWorkout`, so it shows up
/// alongside anything synced from a paired Watch.
@MainActor
final class WorkoutTrackerViewModel: ObservableObject {
    enum TrackerState: Hashable {
        case idle
        case running
        case paused
        case finished
    }

    static let trackableActivities: [HKWorkoutActivityType] = [
        .traditionalStrengthTraining,
        .functionalStrengthTraining,
        .highIntensityIntervalTraining,
        .running,
        .walking,
        .cycling,
        .rowing,
        .wheelchairWalkPace,
        .yoga,
        .other
    ]

    @Published private(set) var state: TrackerState = .idle
    @Published var activityType: HKWorkoutActivityType = .traditionalStrengthTraining
    @Published private(set) var elapsed: TimeInterval = 0
    @Published var errorMessage: String?
    @Published private(set) var isSaving = false

    private let healthManager: HealthKitManager
    private var startDate: Date?
    private var accumulatedBeforePause: TimeInterval = 0
    private var timer: Timer?

    init(healthManager: HealthKitManager? = nil) {
        self.healthManager = healthManager ?? .shared
    }

    func start() {
        startDate = .now
        accumulatedBeforePause = 0
        elapsed = 0
        errorMessage = nil
        state = .running
        startTimer()
    }

    func pause() {
        guard state == .running else { return }
        accumulatedBeforePause = elapsed
        timer?.invalidate()
        state = .paused
    }

    func resume() {
        guard state == .paused else { return }
        state = .running
        startTimer()
    }

    func discardAndReset() {
        timer?.invalidate()
        timer = nil
        state = .idle
        elapsed = 0
        startDate = nil
        accumulatedBeforePause = 0
        errorMessage = nil
    }

    @discardableResult
    func finish() async -> Bool {
        timer?.invalidate()
        timer = nil
        guard let startDate else { return false }
        let endDate = max(Date.now, startDate.addingTimeInterval(1))

        isSaving = true
        errorMessage = nil
        defer { isSaving = false }
        do {
            try await healthManager.saveWorkout(
                activityType: activityType,
                start: startDate,
                end: endDate,
                activeEnergyKcal: nil
            )
            state = .finished
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    private func startTimer() {
        timer?.invalidate()
        let segmentStart = Date.now
        let baseline = accumulatedBeforePause
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.elapsed = baseline + Date.now.timeIntervalSince(segmentStart)
            }
        }
    }
}
