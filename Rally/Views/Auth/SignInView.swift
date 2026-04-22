import SwiftUI

struct SignInView: View {
    @EnvironmentObject var authVM: AuthViewModel

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

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
                            .font(.system(size: 16))
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                VStack(spacing: 16) {
                    if let error = authVM.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                    }

                    Button {
                        Task { await authVM.signInAnonymously() }
                    } label: {
                        HStack {
                            if authVM.isLoading {
                                ProgressView().tint(.background)
                            } else {
                                Image(systemName: "arrow.right.circle.fill")
                                Text("Continue as Guest")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(.primary)
                        .foregroundStyle(.background)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(authVM.isLoading)

                    Text("Sign in with Apple coming soon.")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 48)
            }
        }
    }
}
