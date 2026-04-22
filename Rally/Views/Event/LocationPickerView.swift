import SwiftUI
import MapKit

struct LocationPickerView: View {
    @Binding var coordinate: CLLocationCoordinate2D
    @Binding var address: String
    @Environment(\.dismiss) private var dismiss

    @State private var position: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.3318, longitude: -122.0312),
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
    )
    @State private var searchText = ""
    @State private var searchResults: [MKMapItem] = []
    @State private var selectedCoordinate: CLLocationCoordinate2D?
    @State private var selectedName = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Map(position: $position) {
                    if let coord = selectedCoordinate {
                        Marker(selectedName, coordinate: coord)
                            .tint(.primary)
                    }
                }
                .ignoresSafeArea()

                VStack {
                    // Search bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)
                        TextField("Search location", text: $searchText)
                            .submitLabel(.search)
                            .onSubmit { search() }
                    }
                    .padding(12)
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding()

                    if !searchResults.isEmpty {
                        List(searchResults, id: \.self) { item in
                            Button {
                                select(item)
                            } label: {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.name ?? "Unknown")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundStyle(.primary)
                                    if let addr = item.placemark.title {
                                        Text(addr)
                                            .font(.system(size: 12))
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                        .listStyle(.insetGrouped)
                        .frame(maxHeight: 220)
                    }

                    Spacer()
                }
            }
            .navigationTitle("Pick Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                        .disabled(address.isEmpty)
                }
            }
        }
    }

    private func search() {
        guard let region = position.region else { return }
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText
        request.region = region
        MKLocalSearch(request: request).start { response, _ in
            searchResults = response?.mapItems ?? []
        }
    }

    private func select(_ item: MKMapItem) {
        let coord = item.placemark.coordinate
        selectedCoordinate = coord
        selectedName = item.name ?? ""
        coordinate = coord
        address = item.placemark.title ?? item.name ?? ""
        searchResults = []
        withAnimation {
            position = .region(MKCoordinateRegion(
                center: coord,
                span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
            ))
        }
    }
}
