import Foundation
import AuthenticationServices
import CryptoKit
import FirebaseAuth
import FirebaseFirestore

@MainActor
final class AuthService: NSObject, ObservableObject {
    static let shared = AuthService()

    private var currentNonce: String?

    func handleSignInWithApple(
        authorization: ASAuthorization,
        nonce: String?
    ) async throws -> FirebaseAuth.User {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let appleIDToken = appleIDCredential.identityToken,
              let idTokenString = String(data: appleIDToken, encoding: .utf8),
              let nonce else {
            throw AuthError.invalidCredential
        }

        let credential = OAuthProvider.appleCredential(
            withIDToken: idTokenString,
            rawNonce: nonce,
            fullName: appleIDCredential.fullName
        )

        let result = try await Auth.auth().signIn(with: credential)
        let user = result.user

        let displayName = [
            appleIDCredential.fullName?.givenName,
            appleIDCredential.fullName?.familyName
        ].compactMap { $0 }.joined(separator: " ")

        try await createUserDocIfNeeded(
            uid: user.uid,
            displayName: displayName.isEmpty ? (user.displayName ?? "Rally User") : displayName
        )

        return user
    }

    private func createUserDocIfNeeded(uid: String, displayName: String) async throws {
        let ref = Firestore.firestore().collection("users").document(uid)
        let snapshot = try await ref.getDocument()
        guard !snapshot.exists else { return }

        let appUser = AppUser(
            id: uid,
            displayName: displayName,
            eventsCreated: [],
            eventsAttending: []
        )
        try ref.setData(from: appUser)
    }

    func signOut() throws {
        try Auth.auth().signOut()
    }

    func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        precondition(errorCode == errSecSuccess)
        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        return String(randomBytes.map { charset[Int($0) % charset.count] })
    }

    func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }
}

enum AuthError: LocalizedError {
    case invalidCredential

    var errorDescription: String? {
        switch self {
        case .invalidCredential: return "Invalid Apple ID credential."
        }
    }
}
