import SwiftUI
import AuthenticationServices

struct SignInView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @State private var nonce: String = ""

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Logo + wordmark
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(.primary)
                            .frame(width: 80, height: 80)
                        Image(systemName: "car.2.fill")
                            .font(.system(size: 32, weight: .semibold))
                            .foregroundStyle(.background)
                    }

                    VStack(spacing: 6) {
                        Text("Rally")
                            .font(.system(size: 42, weight: .bold, design: .rounded))

                        Text("Find events near you.")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                // Auth section
                VStack(spacing: 16) {
                    if let error = authVM.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    SignInWithAppleButton(.signIn) { request in
                        nonce = authVM.prepareSignIn()
                        request.requestedScopes = [.fullName, .email]
                        request.nonce = nonce
                    } onCompletion: { result in
                        switch result {
                        case .success(let auth):
                            Task { await authVM.completeSignIn(with: auth) }
                        case .failure(let error):
                            authVM.errorMessage = error.localizedDescription
                        }
                    }
                    .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
                    .frame(height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                    Text("By continuing you agree to our Terms & Privacy Policy.")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 48)
            }
        }
    }

    @Environment(\.colorScheme) private var colorScheme
}
