import SwiftUI
import MapKit

struct CreateEventView: View {
    @EnvironmentObject var eventsVM: EventsViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var description = ""
    @State private var category: EventCategory = .carMeet
    @State private var date = Date().addingTimeInterval(86400)
    @State private var address = ""
    @State private var coordinate = CLLocationCoordinate2D(latitude: 37.3318, longitude: -122.0312)
    @State private var showLocationPicker = false

    private var canSubmit: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty && !address.isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Event title", text: $title)

                    Picker("Category", selection: $category) {
                        ForEach(EventCategory.allCases) { cat in
                            Label(cat.rawValue, systemImage: cat.icon).tag(cat)
                        }
                    }

                    DatePicker("Date & Time", selection: $date, in: Date()..., displayedComponents: [.date, .hourAndMinute])
                }

                Section("Description") {
                    TextEditor(text: $description)
                        .frame(minHeight: 80)
                }

                Section("Location") {
                    if address.isEmpty {
                        Button {
                            showLocationPicker = true
                        } label: {
                            Label("Pick Location", systemImage: "location.circle")
                        }
                    } else {
                        HStack {
                            Image(systemName: "location.fill")
                                .foregroundStyle(.secondary)
                            Text(address)
                                .font(.system(size: 14))
                            Spacer()
                            Button("Change") { showLocationPicker = true }
                                .font(.system(size: 13))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("New Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Post") {
                        Task {
                            await eventsVM.createEvent(
                                title: title,
                                description: description,
                                category: category,
                                date: date,
                                coordinate: coordinate,
                                address: address
                            )
                            await MainActor.run { dismiss() }
                        }
                    }
                    .disabled(!canSubmit || eventsVM.isLoading)
                    .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showLocationPicker) {
                LocationPickerView(coordinate: $coordinate, address: $address)
            }
        }
    }
}
