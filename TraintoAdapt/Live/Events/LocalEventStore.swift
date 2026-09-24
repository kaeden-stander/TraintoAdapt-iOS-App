import Foundation

/// Persists events on-device as JSON. There's no backend events endpoint
/// yet (per the developer guide, only bookings/plans/billing are exposed),
/// so this is a real, working feature scoped to a single device for now —
/// events created here won't sync to other clients' phones until the
/// backend adds a proper endpoint. See README for the upgrade path.
enum LocalEventStore {
    private static var fileURL: URL {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("traintoadapt_local_events.json")
    }

    static func load() -> [Event] {
        guard let data = try? Data(contentsOf: fileURL) else { return [] }
        return (try? JSONDecoder().decode([Event].self, from: data)) ?? []
    }

    static func save(_ events: [Event]) {
        guard let data = try? JSONEncoder().encode(events) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
