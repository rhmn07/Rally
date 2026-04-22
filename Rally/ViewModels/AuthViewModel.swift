import Foundation
import FirebaseAuth

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var currentUser: AppUser = .empty
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?

    private var authStateHandle: AuthStateDidChangeListenerHandle?

    init() {
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.isAuthenticated = user != nil
                if let uid = user?.uid {
                    try? await self?.loadUser(uid: uid)
                }
            }
        }
    }

    deinit {
        if let handle = authStateHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }

    func signInAnonymously() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let result = try await Auth.auth().signInAnonymously()
            let uid = result.user.uid
            try await createUserDocIfNeeded(uid: uid, displayName: "Rally User")
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func signOut() {
        try? Auth.auth().signOut()
    }

    private func createUserDocIfNeeded(uid: String, displayName: String) async throws {
        let appUser = AppUser(id: uid, displayName: displayName, eventsCreated: [], eventsAttending: [])
        try await FirebaseService.shared.createUserDocIfNeeded(appUser)
    }

    private func loadUser(uid: String) async throws {
        currentUser = try await FirebaseService.shared.fetchUser(uid: uid)
    }

    var userID: String { Auth.auth().currentUser?.uid ?? "" }
}
