import Foundation
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage

final class FirebaseService {
    static let shared = FirebaseService()

    private let db = Firestore.firestore(database: "default")
    private let storage = Storage.storage()

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
        try await db.collection("users").document(uid).updateData([
            "eventsCreated": FieldValue.arrayUnion([event.id])
        ])
    }

    func rsvp(eventID: String, userID: String) async throws {
        try await db.collection("events").document(eventID).updateData([
            "attendeeIDs": FieldValue.arrayUnion([userID])
        ])
        try await db.collection("users").document(userID).updateData([
            "eventsAttending": FieldValue.arrayUnion([eventID])
        ])
    }

    func cancelRSVP(eventID: String, userID: String) async throws {
        try await db.collection("events").document(eventID).updateData([
            "attendeeIDs": FieldValue.arrayRemove([userID])
        ])
        try await db.collection("users").document(userID).updateData([
            "eventsAttending": FieldValue.arrayRemove([eventID])
        ])
    }

    func deleteEvent(eventID: String, organizerID: String) async throws {
        try await db.collection("events").document(eventID).delete()
        try await db.collection("users").document(organizerID).updateData([
            "eventsCreated": FieldValue.arrayRemove([eventID])
        ])
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

    // MARK: Storage

    func uploadEventImage(_ data: Data, eventID: String) async throws -> String {
        let ref = storage.reference().child("events/\(eventID).jpg")
        let meta = StorageMetadata()
        meta.contentType = "image/jpeg"
        _ = try await ref.putDataAsync(data, metadata: meta)
        let url = try await ref.downloadURL()
        return url.absoluteString
    }
}
