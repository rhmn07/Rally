import Foundation
import MapKit
import CoreLocation

@MainActor
final class MapViewModel: ObservableObject {
    @Published var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.3318, longitude: -122.0312),
        span: MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2)
    )
    @Published var selectedEvent: RallyEvent?
    @Published var radiusMiles: Double = 25

    private let locationService = LocationService.shared

    func centerOnUser() {
        guard let loc = locationService.userLocation else { return }
        withAnimation {
            region.center = loc.coordinate
        }
    }

    func centerOn(_ event: RallyEvent) {
        withAnimation {
            region = MKCoordinateRegion(
                center: event.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
        }
    }

    func requestLocationIfNeeded() {
        locationService.requestPermission()
    }
}
