import SwiftUI

struct FeedView: View {
    @EnvironmentObject var eventsVM: EventsViewModel
    @Binding var showCreateEvent: Bool
    @State private var showEventDetail: RallyEvent?
    private let locationService = LocationService.shared

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filter chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FilterChip(label: "All", isSelected: eventsVM.selectedCategory == nil) {
                            eventsVM.selectedCategory = nil
                        }
                        ForEach(EventCategory.allCases) { cat in
                            FilterChip(label: cat.rawValue, isSelected: eventsVM.selectedCategory == cat) {
                                eventsVM.selectedCategory = eventsVM.selectedCategory == cat ? nil : cat
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                }

                Divider()

                if eventsVM.events.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "car.2")
                            .font(.system(size: 44))
                            .foregroundStyle(.tertiary)
                        Text("No events yet")
                            .font(.headline)
                        Text("Be the first to post one!")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Button("Create Event") { showCreateEvent = true }
                            .buttonStyle(.borderedProminent)
                            .tint(.primary)
                            .foregroundStyle(.background)
                    }
                    Spacer()
                } else {
                    List {
                        ForEach(eventsVM.sortedByDistance(from: locationService.userLocation)) { event in
                            EventRowView(event: event)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                                .onTapGesture { showEventDetail = event }
                        }
                    }
                    .listStyle(.plain)
                    .refreshable { eventsVM.startListening() }
                }
            }
            .navigationTitle("Events")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showCreateEvent = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                    }
                    .tint(.primary)
                }
            }
        }
        .sheet(item: $showEventDetail) { event in
            EventDetailView(event: event)
                .environmentObject(eventsVM)
        }
    }
}

private struct FilterChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(isSelected ? .primary : Color(.secondarySystemBackground))
                .foregroundStyle(isSelected ? Color(.systemBackground) : .primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}
