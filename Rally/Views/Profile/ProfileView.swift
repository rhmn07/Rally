import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var eventsVM: EventsViewModel
    @AppStorage("appColorScheme") private var colorSchemeRaw = 0
    @State private var isEditingName = false
    @State private var draftName = ""
    @State private var showEventDetail: RallyEvent?
    @State private var showSignOutConfirm = false

    private var myEvents: [RallyEvent] {
        eventsVM.events.filter { eventsVM.isOrganizer($0) }
    }

    private var attendingEvents: [RallyEvent] {
        eventsVM.events.filter { eventsVM.isAttending($0) && !eventsVM.isOrganizer($0) }
    }

    var body: some View {
        NavigationStack {
            List {
                // Profile header
                Section {
                    HStack(spacing: 16) {
                        Group {
                            if let urlStr = authVM.currentUser.profileImageURL,
                               let url = URL(string: urlStr) {
                                AsyncImage(url: url) { image in
                                    image.resizable().scaledToFill()
                                } placeholder: {
                                    ProgressView()
                                }
                                .frame(width: 60, height: 60)
                                .clipShape(Circle())
                            } else {
                                ZStack {
                                    Circle()
                                        .fill(Color(.secondarySystemBackground))
                                        .frame(width: 60, height: 60)
                                    Text(authVM.currentUser.displayName.prefix(1).uppercased())
                                        .font(.system(size: 24, weight: .semibold))
                                }
                            }
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            if isEditingName {
                                TextField("Your name", text: $draftName)
                                    .font(.system(size: 17, weight: .semibold))
                                    .onSubmit { saveName() }
                            } else {
                                Text(authVM.currentUser.displayName)
                                    .font(.system(size: 17, weight: .semibold))
                            }
                            Text("Rally member")
                                .font(.system(size: 13))
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Button {
                            if isEditingName {
                                saveName()
                            } else {
                                draftName = authVM.currentUser.displayName
                                isEditingName = true
                            }
                        } label: {
                            Text(isEditingName ? "Save" : "Edit")
                                .font(.system(size: 14))
                        }
                    }
                    .padding(.vertical, 4)
                }

                // Events attending
                if !attendingEvents.isEmpty {
                    Section("Going to") {
                        ForEach(attendingEvents) { event in
                            EventRowView(event: event)
                                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                                .listRowSeparator(.hidden)
                                .onTapGesture { showEventDetail = event }
                        }
                    }
                }

                // My events
                if !myEvents.isEmpty {
                    Section("My Events") {
                        ForEach(myEvents) { event in
                            EventRowView(event: event)
                                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                                .listRowSeparator(.hidden)
                                .onTapGesture { showEventDetail = event }
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        Task { await eventsVM.deleteEvent(event) }
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                }

                if myEvents.isEmpty && attendingEvents.isEmpty {
                    Section {
                        VStack(spacing: 8) {
                            Image(systemName: "calendar.badge.plus")
                                .font(.system(size: 36))
                                .foregroundStyle(.tertiary)
                            Text("No events yet")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                    }
                }

                Section("Appearance") {
                    Picker("Theme", selection: $colorSchemeRaw) {
                        Text("System").tag(0)
                        Text("Light").tag(1)
                        Text("Dark").tag(2)
                    }
                    .pickerStyle(.segmented)
                }

                Section {
                    Button(role: .destructive) {
                        showSignOutConfirm = true
                    } label: {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Profile")
            .sheet(item: $showEventDetail) { event in
                EventDetailView(event: event)
                    .environmentObject(eventsVM)
            }
            .confirmationDialog("Sign out of Rally?", isPresented: $showSignOutConfirm, titleVisibility: .visible) {
                Button("Sign Out", role: .destructive) { authVM.signOut() }
                Button("Cancel", role: .cancel) {}
            }
        }
    }

    private func saveName() {
        let name = draftName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { isEditingName = false; return }
        Task {
            try? await FirebaseService.shared.updateDisplayName(name, uid: authVM.userID)
            await MainActor.run {
                authVM.currentUser.displayName = name
                isEditingName = false
            }
        }
    }
}
