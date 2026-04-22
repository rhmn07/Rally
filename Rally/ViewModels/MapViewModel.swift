import Foundation
import SwiftUI
import MapKit
import CoreLocation

@MainActor
final class MapViewModel: ObservableObject {
    @Published var position: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.3318, longitude: -122.0312),
            span: MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2)
        )
    )
    @Published var selectedEvent: RallyEvent?

    private let locationService = LocationService.shared

    func centerOnUser() {
        guard let loc = locationService.userLocation else { return }
        withAnimation {
            position = .region(MKCoordinateRegion(
                center: loc.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2)
            ))
        }
    }

    func centerOn(_ event: RallyEvent) {
        withAnimation {
            position = .region(MKCoordinateRegion(
                center: event.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            ))
        }
    }

    func requestLocationIfNeeded() {
        locationService.requestPermission()
    }
}
