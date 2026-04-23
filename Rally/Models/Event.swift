import Foundation
import CoreLocation

enum EventCategory: String, Codable, CaseIterable, Identifiable {
    case carMeet = "Car Meet"
    case carShow = "Car Show"
    case trackDay = "Track Day"
    case expo = "Auto Expo"
    case scenicDrive = "Scenic Drive"
    case other = "Other"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .carMeet:    return "car.2.fill"
        case .carShow:    return "trophy.fill"
        case .trackDay:   return "flag.checkered"
        case .expo:       return "building.2.fill"
        case .scenicDrive: return "road.lanes"
        case .other:      return "calendar"
        }
    }
}

struct RallyEvent: Identifiable, Codable {
    var id: String
    var title: String
    var description: String
    var category: EventCategory
    var latitude: Double
    var longitude: Double
    var address: String
    var date: Date
    var organizerID: String
    var organizerName: String
    var attendeeIDs: [String]
    var tags: [String]

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var attendeeCount: Int { attendeeIDs.count }

    func distance(from location: CLLocation) -> CLLocationDistance {
        let eventLocation = CLLocation(latitude: latitude, longitude: longitude)
        return location.distance(from: eventLocation)
    }

    func formattedDistance(from location: CLLocation) -> String {
        let meters = distance(from: location)
        let miles = meters / 1609.34
        if miles < 0.1 { return "Nearby" }
        if miles < 10 { return String(format: "%.1f mi", miles) }
        return String(format: "%.0f mi", miles)
    }

    static var placeholder: RallyEvent {
        RallyEvent(
            id: "preview",
            title: "Sunday Car Meet",
            description: "Join us for a relaxed Sunday gathering. All makes and models welcome!",
            category: .carMeet,
            latitude: 37.3318,
            longitude: -122.0312,
            address: "Apple Park, Cupertino, CA",
            date: Date().addingTimeInterval(86400),
            organizerID: "user1",
            organizerName: "Alex Chen",
            attendeeIDs: ["u1", "u2", "u3", "u4", "u5"],
            tags: ["all-welcome", "sunday"]
        )
    }
}
