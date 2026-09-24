import Foundation

enum EventError: LocalizedError {
    case full
    var errorDescription: String? {
        switch self {
        case .full: "This event is fully booked."
        }
    }
}

protocol EventServiceProtocol {
    func upcomingEvents() async -> [Event]
    func rsvp(eventID: UUID, userID: UUID) async throws
    func cancelRsvp(eventID: UUID, userID: UUID) async
    @discardableResult
    func createEvent(_ event: Event) async throws -> Event
    func deleteEvent(_ eventID: UUID) async throws
}

@MainActor
final class MockEventService: EventServiceProtocol {
    private let store: MockDataStore

    init(store: MockDataStore = .shared) {
        self.store = store
    }

    func upcomingEvents() async -> [Event] {
        store.events
            .filter { $0.date >= Calendar.current.startOfDay(for: .now) }
            .sorted { $0.date < $1.date }
    }

    func rsvp(eventID: UUID, userID: UUID) async throws {
        guard let index = store.events.firstIndex(where: { $0.id == eventID }) else { return }
        guard !store.events[index].isFull else { throw EventError.full }
        guard !store.events[index].attendeeIDs.contains(userID) else { return }
        store.events[index].attendeeIDs.append(userID)
    }

    func cancelRsvp(eventID: UUID, userID: UUID) async {
        guard let index = store.events.firstIndex(where: { $0.id == eventID }) else { return }
        store.events[index].attendeeIDs.removeAll { $0 == userID }
    }

    @discardableResult
    func createEvent(_ event: Event) async throws -> Event {
        store.events.append(event)
        return event
    }

    func deleteEvent(_ eventID: UUID) async throws {
        store.events.removeAll { $0.id == eventID }
    }
}
