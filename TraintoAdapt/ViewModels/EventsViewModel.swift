import Foundation

@MainActor
final class EventsViewModel: ObservableObject {
    @Published var events: [Event] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let service: EventServiceProtocol
    let currentUserID: UUID

    init(currentUserID: UUID, service: EventServiceProtocol? = nil) {
        self.currentUserID = currentUserID
        self.service = service ?? MockEventService()
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        events = await service.upcomingEvents()
    }

    func toggleRSVP(_ event: Event) async {
        errorMessage = nil
        do {
            if event.isAttending(currentUserID) {
                await service.cancelRsvp(eventID: event.id, userID: currentUserID)
            } else {
                try await service.rsvp(eventID: event.id, userID: currentUserID)
            }
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
