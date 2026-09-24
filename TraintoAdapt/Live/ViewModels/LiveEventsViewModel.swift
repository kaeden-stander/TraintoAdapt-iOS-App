import Foundation

@MainActor
final class LiveEventsViewModel: ObservableObject {
    @Published private(set) var events: [Event] = []

    init() {
        events = LocalEventStore.load().sorted { $0.date < $1.date }
    }

    func load() {
        events = LocalEventStore.load().sorted { $0.date < $1.date }
    }

    func create(
        title: String,
        description: String,
        date: Date,
        location: String,
        capacity: Int,
        category: EventCategory
    ) {
        let event = Event(
            title: title,
            eventDescription: description,
            date: date,
            location: location,
            capacity: capacity,
            category: category
        )
        events.append(event)
        persist()
    }

    func delete(_ event: Event) {
        events.removeAll { $0.id == event.id }
        persist()
    }

    func toggleRSVP(_ event: Event, userID: UUID) {
        guard let index = events.firstIndex(where: { $0.id == event.id }) else { return }
        if events[index].attendeeIDs.contains(userID) {
            events[index].attendeeIDs.removeAll { $0 == userID }
        } else if !events[index].isFull {
            events[index].attendeeIDs.append(userID)
        }
        persist()
    }

    private func persist() {
        events.sort { $0.date < $1.date }
        LocalEventStore.save(events)
    }
}
