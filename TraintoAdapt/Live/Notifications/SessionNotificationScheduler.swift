import Foundation
import UserNotifications

/// Schedules local reminders (1 hour and 30 minutes before) for a client's
/// upcoming sessions. Purely local — no push/APNs setup needed, since the
/// app already knows the booking times once it has fetched `/bookings`.
@MainActor
final class SessionNotificationScheduler {
    static let shared = SessionNotificationScheduler()

    private let center = UNUserNotificationCenter.current()
    private let reminderOffsets: [(seconds: TimeInterval, label: String)] = [
        (3600, "in 1 hour"),
        (1800, "in 30 minutes")
    ]

    func requestAuthorizationIfNeeded() async {
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .notDetermined else { return }
        _ = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
    }

    /// Clears every reminder this app previously scheduled and reschedules
    /// fresh ones from the current booking list, so a cancelled or moved
    /// session doesn't leave a stale reminder behind.
    func reschedule(for bookings: [RemoteBooking]) async {
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional else { return }

        let pending = await center.pendingNotificationRequests()
        let ourIdentifiers = pending.map(\.identifier).filter { $0.hasPrefix(identifierPrefix) }
        center.removePendingNotificationRequests(withIdentifiers: ourIdentifiers)

        let upcoming = bookings.filter { $0.status == .pending || $0.status == .confirmed }
        for booking in upcoming {
            await scheduleReminders(for: booking)
        }
    }

    private let identifierPrefix = "traintoadapt-session-reminder-"

    private func scheduleReminders(for booking: RemoteBooking) async {
        for offset in reminderOffsets {
            let fireDate = booking.startsAt.addingTimeInterval(-offset.seconds)
            guard fireDate > .now else { continue }

            let content = UNMutableNotificationContent()
            content.title = "Session \(offset.label)"
            content.body = "Your TrainToAdapt session starts at \(booking.startsAt.formatted(date: .omitted, time: .shortened))."
            content.sound = .default

            let components = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: fireDate
            )
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(
                identifier: "\(identifierPrefix)\(booking.id)-\(Int(offset.seconds))",
                content: content,
                trigger: trigger
            )
            try? await center.add(request)
        }
    }
}
