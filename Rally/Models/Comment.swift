import Foundation

struct Comment: Identifiable, Codable {
    var id: String
    var authorID: String
    var authorName: String
    var text: String
    var createdAt: Date
}
