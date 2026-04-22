import Foundation

struct AppUser: Identifiable, Codable {
    var id: String
    var displayName: String
    var profileImageURL: String?
    var eventsCreated: [String]
    var eventsAttending: [String]

    static var empty: AppUser {
        AppUser(id: "", displayName: "", eventsCreated: [], eventsAttending: [])
    }
}
