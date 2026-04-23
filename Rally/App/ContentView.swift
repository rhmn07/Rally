import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var eventsVM = EventsViewModel()
    @StateObject private var mapVM = MapViewModel()
    @State private var selectedTab = 0
    @State private var showCreateEvent = false

    var body: some View {
        TabView(selection: $selectedTab) {
            MapTabView(showCreateEvent: $showCreateEvent)
                .tabItem {
                    Label("Map", systemImage: "map.fill")
                }
                .tag(0)

            FeedView(showCreateEvent: $showCreateEvent)
                .tabItem {
                    Label("Events", systemImage: "list.bullet")
                }
                .tag(1)

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(2)
        }
        .tint(Color.orange)
        .environmentObject(eventsVM)
        .environmentObject(mapVM)
        .sheet(isPresented: $showCreateEvent) {
            CreateEventView()
                .environmentObject(eventsVM)
        }
        .onAppear {
            eventsVM.startListening()
            Task { await NotificationService.requestPermission() }
        }
    }
}
