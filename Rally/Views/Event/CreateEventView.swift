import SwiftUI
import MapKit
import PhotosUI

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
    @State private var photoItem: PhotosPickerItem?
    @State private var photoData: Data?
    @State private var photoImage: Image?

    private var canSubmit: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty && !address.isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                // Photo picker
                Section {
                    PhotosPicker(selection: $photoItem, matching: .images) {
                        ZStack {
                            if let img = photoImage {
                                img
                                    .resizable()
                                    .scaledToFill()
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 160)
                                    .clipped()
                            } else {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.secondarySystemBackground))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 120)
                                    .overlay {
                                        VStack(spacing: 6) {
                                            Image(systemName: "photo.badge.plus")
                                                .font(.system(size: 28))
                                                .foregroundStyle(.tertiary)
                                            Text("Add Cover Photo")
                                                .font(.system(size: 13))
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                            }
                        }
                    }
                    .onChange(of: photoItem) { _, item in
                        Task {
                            guard let item else { return }
                            if let data = try? await item.loadTransferable(type: Data.self) {
                                photoData = data
                                if let uiImage = UIImage(data: data) {
                                    photoImage = Image(uiImage: uiImage)
                                }
                            }
                        }
                    }
                }
                .listRowInsets(EdgeInsets())

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
                                address: address,
                                imageData: photoData
                            )
                            dismiss()
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
