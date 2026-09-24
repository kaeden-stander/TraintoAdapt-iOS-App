import Foundation

/// A day's worth of health and activity data, sourced from HealthKit
/// (and, via HealthKit, from a paired Apple Watch when one is present).
struct DailyHealthSummary: Identifiable, Hashable {
    var id: Date { date }
    var date: Date
    var steps: Int
    var activeEnergyKcal: Double
    var averageHeartRate: Double?
    var restingHeartRate: Double?
    var exerciseMinutes: Int

    static let empty = DailyHealthSummary(
        date: .now,
        steps: 0,
        activeEnergyKcal: 0,
        averageHeartRate: nil,
        restingHeartRate: nil,
        exerciseMinutes: 0
    )
}

/// A completed workout, as reported by HealthKit (Apple Watch, iPhone, or a
/// third-party app that writes to Health).
struct WorkoutSample: Identifiable, Hashable {
    let id: UUID
    var activityName: String
    var start: Date
    var end: Date
    var totalEnergyKcal: Double?
    var averageHeartRate: Double?
    var source: String

    init(
        id: UUID = UUID(),
        activityName: String,
        start: Date,
        end: Date,
        totalEnergyKcal: Double?,
        averageHeartRate: Double?,
        source: String
    ) {
        self.id = id
        self.activityName = activityName
        self.start = start
        self.end = end
        self.totalEnergyKcal = totalEnergyKcal
        self.averageHeartRate = averageHeartRate
        self.source = source
    }

    var durationMinutes: Int {
        Int(end.timeIntervalSince(start) / 60)
    }
}
