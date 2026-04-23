import SwiftUI
import GoogleSignInSwift

struct SignInView: View {
    @EnvironmentObject var authVM: AuthViewModel

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Logo
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Color.black)
                            .frame(width: 80, height: 80)
                        Image(systemName: "car.2.fill")
                            .font(.system(size: 32, weight: .semibold))
                            .foregroundColor(.white)
                    }

                    VStack(spacing: 6) {
                        Text("Rally")
                            .font(.system(size: 42, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        Text("Find events near you.")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                // Auth section
                VStack(spacing: 16) {
                    if let error = authVM.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                    }

                    GoogleSignInButton(scheme: .dark, style: .wide, state: authVM.isLoading ? .disabled : .normal) {
                        Task { await authVM.signInWithGoogle() }
                    }
                    .frame(height: 50)
                    .disabled(authVM.isLoading)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 48)
            }
        }
    }
}
