import SwiftUI
import Firebase

@main
struct RallyApp: App {
    @StateObject private var authVM = AuthViewModel()

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if authVM.isAuthenticated {
                    ContentView()
                        .environmentObject(authVM)
                } else {
                    SignInView()
                        .environmentObject(authVM)
                }
            }
            .animation(.easeInOut(duration: 0.3), value: authVM.isAuthenticated)
        }
    }
}
