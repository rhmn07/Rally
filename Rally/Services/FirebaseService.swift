import Foundation
import FirebaseFirestore
import FirebaseAuth

final class FirebaseService {
    static let shared = FirebaseService()

    private let db = Firestore.firestore(database: "default")

    // MARK: Events

    func eventsListener(completion: @escaping ([RallyEvent]) -> Void) -> ListenerRegistration {
        db.collection("events")
            .order(by: "date")
            .addSnapshotListener { snapshot, _ in
                guard let docs = snapshot?.documents else { return }
                let events = docs.compactMap { try? $0.data(as: RallyEvent.self) }
                completion(events)
            }
    }

    func createEvent(_ event: RallyEvent) async throws {
        try db.collection("events").document(event.id).setData(from: event)

        guard let uid = Auth.auth().currentUser?.uid else { return }
        try await db.collection("users").document(uid).setData([
            "eventsCreated": FieldValue.arrayUnion([event.id])
        ], merge: true)
    }

    func rsvp(eventID: String, userID: String) async throws {
        try await db.collection("events").document(eventID).updateData([
            "attendeeIDs": FieldValue.arrayUnion([userID])
        ])
        try await db.collection("users").document(userID).setData([
            "eventsAttending": FieldValue.arrayUnion([eventID])
        ], merge: true)
    }

    func cancelRSVP(eventID: String, userID: String) async throws {
        try await db.collection("events").document(eventID).updateData([
            "attendeeIDs": FieldValue.arrayRemove([userID])
        ])
        try await db.collection("users").document(userID).setData([
            "eventsAttending": FieldValue.arrayRemove([eventID])
        ], merge: true)
    }

    func deleteEvent(eventID: String, organizerID: String) async throws {
        try await db.collection("events").document(eventID).delete()
        try await db.collection("users").document(organizerID).setData([
            "eventsCreated": FieldValue.arrayRemove([eventID])
        ], merge: true)
    }

    // MARK: User

    func createUserDocIfNeeded(_ user: AppUser) async throws {
        let ref = db.collection("users").document(user.id)
        let snapshot = try await ref.getDocument()
        guard !snapshot.exists else { return }
        try ref.setData(from: user)
    }

    func fetchUser(uid: String) async throws -> AppUser {
        try await db.collection("users").document(uid).getDocument(as: AppUser.self)
    }

    func updateDisplayName(_ name: String, uid: String) async throws {
        try await db.collection("users").document(uid).updateData(["displayName": name])
    }

    // MARK: Comments

    func commentsListener(eventID: String, completion: @escaping ([Comment]) -> Void) -> ListenerRegistration {
        db.collection("events").document(eventID).collection("comments")
            .order(by: "createdAt")
            .addSnapshotListener { snapshot, _ in
                guard let docs = snapshot?.documents else { return }
                let comments = docs.compactMap { try? $0.data(as: Comment.self) }
                completion(comments)
            }
    }

    func postComment(_ comment: Comment, eventID: String) async throws {
        try db.collection("events").document(eventID)
            .collection("comments").document(comment.id).setData(from: comment)
    }

}
