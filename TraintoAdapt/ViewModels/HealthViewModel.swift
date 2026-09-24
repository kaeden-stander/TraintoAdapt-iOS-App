import Foundation

@MainActor
final class HealthViewModel: ObservableObject {
    let manager: HealthKitManager

    init(manager: HealthKitManager = .shared) {
        self.manager = manager
    }

    var isAuthorized: Bool { manager.isAuthorized }
    var summary: DailyHealthSummary { manager.todaySummary }
    var recentWorkouts: [WorkoutSample] { manager.recentWorkouts }
    var errorMessage: String? { manager.lastError }
    var isHealthDataAvailable: Bool { manager.isHealthDataAvailable }

    func connect() async {
        await manager.requestAuthorization()
    }

    func refresh() async {
        await manager.refreshAll()
    }
}
