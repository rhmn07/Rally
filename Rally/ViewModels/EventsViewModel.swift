import Foundation
import FirebaseFirestore
import FirebaseAuth
import CoreLocation

@MainActor
final class EventsViewModel: ObservableObject {
    @Published var events: [RallyEvent] = []
    @Published var selectedCategory: EventCategory?
    @Published var maxDistanceMiles: Double? = nil
    @Published var isLoading = false
    @Published var errorMessage: String?

    private var listener: ListenerRegistration?

    var trendingEvents: [RallyEvent] {
        let upcoming = events.filter { $0.date > Date() }
        let pool = upcoming.isEmpty ? events : upcoming
        return Array(pool.sorted { $0.attendeeCount > $1.attendeeCount }.prefix(5))
    }

    var filteredEvents: [RallyEvent] {
        var result = events
        if let cat = selectedCategory {
            result = result.filter { $0.category == cat }
        }
        if let max = maxDistanceMiles, let loc = LocationService.shared.userLocation {
            result = result.filter { event in
                let eventLoc = CLLocation(latitude: event.latitude, longitude: event.longitude)
                return loc.distance(from: eventLoc) / 1609.34 <= max
            }
        }
        return result
    }

    func startListening() {
        listener = FirebaseService.shared.eventsListener { [weak self] events in
            self?.events = events
        }
    }

    func stopListening() {
        listener?.remove()
    }

    func sortedByDistance(from location: CLLocation?) -> [RallyEvent] {
        guard let loc = location else { return filteredEvents }
        return filteredEvents.sorted { $0.distance(from: loc) < $1.distance(from: loc) }
    }

    func createEvent(
        title: String,
        description: String,
        category: EventCategory,
        date: Date,
        coordinate: CLLocationCoordinate2D,
        address: String
    ) async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        isLoading = true
        defer { isLoading = false }

        let id = UUID().uuidString
        let event = RallyEvent(
            id: id,
            title: title,
            description: description,
            category: category,
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            address: address,
            date: date,
            organizerID: uid,
            organizerName: Auth.auth().currentUser?.displayName ?? "Rally User",
            attendeeIDs: [uid],
            tags: []
        )

        do {
            try await FirebaseService.shared.createEvent(event)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func toggleRSVP(for event: RallyEvent) async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        do {
            if event.attendeeIDs.contains(uid) {
                try await FirebaseService.shared.cancelRSVP(eventID: event.id, userID: uid)
            } else {
                try await FirebaseService.shared.rsvp(eventID: event.id, userID: uid)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteEvent(_ event: RallyEvent) async {
        guard let uid = Auth.auth().currentUser?.uid, uid == event.organizerID else { return }
        do {
            try await FirebaseService.shared.deleteEvent(eventID: event.id, organizerID: uid)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func isAttending(_ event: RallyEvent) -> Bool {
        guard let uid = Auth.auth().currentUser?.uid else { return false }
        return event.attendeeIDs.contains(uid)
    }

    func isOrganizer(_ event: RallyEvent) -> Bool {
        Auth.auth().currentUser?.uid == event.organizerID
    }
}
