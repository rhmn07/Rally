import SwiftUI
import Firebase
import GoogleSignIn

@main
struct RallyApp: App {
    @StateObject private var authVM = AuthViewModel()
    @AppStorage("appColorScheme") private var colorSchemeRaw = 0

    init() {
        FirebaseApp.configure()
    }

    private var preferredScheme: ColorScheme? {
        switch colorSchemeRaw {
        case 1: return .light
        case 2: return .dark
        default: return nil
        }
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
            .preferredColorScheme(preferredScheme)
            .animation(.easeInOut(duration: 0.3), value: authVM.isAuthenticated)
            .onOpenURL { url in
                GIDSignIn.sharedInstance.handle(url)
            }
        }
    }
}
