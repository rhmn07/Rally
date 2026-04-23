import Foundation
import FirebaseAuth
import FirebaseCore
import GoogleSignIn

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
                // Anonymous users must sign in with Google
                if let user, user.isAnonymous {
                    try? Auth.auth().signOut()
                    self?.isAuthenticated = false
                    return
                }
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

    func signInWithGoogle() async {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            errorMessage = "Google Sign-In is not configured yet."
            return
        }

        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)

        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootVC)
            guard let idToken = result.user.idToken?.tokenString else { return }
            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: result.user.accessToken.tokenString
            )
            let photoURL = result.user.profile?.imageURL(withDimension: 200)?.absoluteString
            let authResult = try await Auth.auth().signIn(with: credential)
            let uid = authResult.user.uid
            let displayName = authResult.user.displayName ?? "Rally User"
            try await createUserDocIfNeeded(uid: uid, displayName: displayName, photoURL: photoURL)
            try await loadUser(uid: uid)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func signOut() {
        GIDSignIn.sharedInstance.signOut()
        try? Auth.auth().signOut()
    }

    private func createUserDocIfNeeded(uid: String, displayName: String, photoURL: String?) async throws {
        let appUser = AppUser(id: uid, displayName: displayName, profileImageURL: photoURL, eventsCreated: [], eventsAttending: [])
        try await FirebaseService.shared.createUserDocIfNeeded(appUser)
    }

    private func loadUser(uid: String) async throws {
        currentUser = try await FirebaseService.shared.fetchUser(uid: uid)
    }

    var userID: String { Auth.auth().currentUser?.uid ?? "" }
}
