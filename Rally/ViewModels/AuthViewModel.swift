import Foundation
import FirebaseAuth
import AuthenticationServices

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var currentUser: AppUser = .empty
    @Published var isAuthenticated = false
    @Published var errorMessage: String?

    private var authStateHandle: AuthStateDidChangeListenerHandle?
    private var pendingNonce: String?

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

    func prepareSignIn() -> String {
        let nonce = AuthService.shared.randomNonceString()
        pendingNonce = nonce
        return AuthService.shared.sha256(nonce)
    }

    func completeSignIn(with authorization: ASAuthorization) async {
        do {
            _ = try await AuthService.shared.handleSignInWithApple(
                authorization: authorization,
                nonce: pendingNonce
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func signOut() {
        try? AuthService.shared.signOut()
    }

    private func loadUser(uid: String) async throws {
        currentUser = try await FirebaseService.shared.fetchUser(uid: uid)
    }

    var userID: String { Auth.auth().currentUser?.uid ?? "" }
}
