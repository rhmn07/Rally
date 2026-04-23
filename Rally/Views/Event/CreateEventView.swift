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

    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var isUploadingPhoto = false
    @State private var photoURL: String?

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

                Section("Photo") {
                    if let img = selectedImage {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 160)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .listRowInsets(EdgeInsets())

                        if isUploadingPhoto {
                            HStack(spacing: 8) {
                                ProgressView()
                                Text("Uploading…")
                                    .font(.system(size: 14))
                                    .foregroundStyle(.secondary)
                            }
                        } else {
                            Button(role: .destructive) {
                                selectedImage = nil
                                selectedPhotoItem = nil
                                photoURL = nil
                            } label: {
                                Label("Remove Photo", systemImage: "trash")
                                    .font(.system(size: 14))
                            }
                        }
                    } else {
                        PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                            Label("Add Photo", systemImage: "photo")
                        }
                    }
                }
                .onChange(of: selectedPhotoItem) { _, item in
                    Task {
                        guard let item,
                              let data = try? await item.loadTransferable(type: Data.self),
                              let img = UIImage(data: data) else { return }
                        selectedImage = img
                        isUploadingPhoto = true
                        photoURL = try? await CloudinaryService.upload(img)
                        isUploadingPhoto = false
                    }
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
                                photoURL: photoURL
                            )
                            await MainActor.run { dismiss() }
                        }
                    }
                    .disabled(!canSubmit || isUploadingPhoto || eventsVM.isLoading)
                    .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showLocationPicker) {
                LocationPickerView(coordinate: $coordinate, address: $address)
            }
        }
    }
}
