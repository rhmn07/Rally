import SwiftUI

struct FeedView: View {
    @EnvironmentObject var eventsVM: EventsViewModel
    @Binding var showCreateEvent: Bool
    @State private var showEventDetail: RallyEvent?
    @State private var searchText = ""
    private let locationService = LocationService.shared

    private var filteredResults: [RallyEvent] {
        let sorted = eventsVM.sortedByDistance(from: locationService.userLocation)
        guard !searchText.isEmpty else { return sorted }
        let q = searchText.lowercased()
        return sorted.filter {
            $0.title.lowercased().contains(q) ||
            $0.description.lowercased().contains(q) ||
            $0.tags.contains { $0.lowercased().contains(q) }
        }
    }

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
                        // Trending carousel — hidden while searching
                        if searchText.isEmpty && !eventsVM.trendingEvents.isEmpty {
                            Section {
                                TrendingCarousel(events: eventsVM.trendingEvents) { event in
                                    showEventDetail = event
                                }
                                .listRowInsets(EdgeInsets())
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                            } header: {
                                Text("Trending")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundStyle(.primary)
                                    .textCase(nil)
                                    .padding(.leading, 16)
                                    .padding(.bottom, 4)
                            }
                        }

                        Section {
                            ForEach(filteredResults) { event in
                                EventRowView(event: event)
                                    .listRowSeparator(.hidden)
                                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                                    .onTapGesture { showEventDetail = event }
                            }
                        } header: {
                            if searchText.isEmpty {
                                Text("All Events")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundStyle(.primary)
                                    .textCase(nil)
                                    .padding(.leading, 16)
                                    .padding(.bottom, 4)
                            }
                        }
                    }
                    .listStyle(.plain)
                    .refreshable { eventsVM.startListening() }
                }
            }
            .searchable(text: $searchText, prompt: "Search events")
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
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Button("Any distance") { eventsVM.maxDistanceMiles = nil }
                        Button("Within 10 miles") { eventsVM.maxDistanceMiles = 10 }
                        Button("Within 25 miles") { eventsVM.maxDistanceMiles = 25 }
                        Button("Within 50 miles") { eventsVM.maxDistanceMiles = 50 }
                    } label: {
                        Image(systemName: eventsVM.maxDistanceMiles == nil ? "location" : "location.fill")
                            .font(.system(size: 18))
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

private struct TrendingCarousel: View {
    let events: [RallyEvent]
    let onSelect: (RallyEvent) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(events) { event in
                    TrendingCard(event: event)
                        .onTapGesture { onSelect(event) }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }
}

private struct TrendingCard: View {
    let event: RallyEvent

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Background: photo if available, otherwise gradient
            if let urlStr = event.photoURL, let url = URL(string: urlStr) {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    LinearGradient(
                        colors: [cardColor.opacity(0.85), cardColor.opacity(0.5)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
                .frame(width: 200, height: 130)
                .clipped()
            } else {
                LinearGradient(
                    colors: [cardColor.opacity(0.85), cardColor.opacity(0.5)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }

            // Dark scrim so text is always readable over photos
            LinearGradient(
                colors: [.clear, .black.opacity(0.65)],
                startPoint: .center,
                endPoint: .bottom
            )

            // Category icon watermark (only shown without a photo)
            if event.photoURL == nil {
                Image(systemName: event.category.icon)
                    .font(.system(size: 56, weight: .thin))
                    .foregroundStyle(.white.opacity(0.2))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    .padding(16)
            }

            // Content
            VStack(alignment: .leading, spacing: 6) {
                Text(event.title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(2)

                HStack(spacing: 10) {
                    Label("\(event.attendeeCount)", systemImage: "person.2.fill")
                    Text(event.date.formatted(date: .abbreviated, time: .omitted))
                }
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(0.85))
            }
            .padding(14)
        }
        .frame(width: 200, height: 130)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: cardColor.opacity(0.35), radius: 8, y: 4)
    }

    private var cardColor: Color {
        switch event.category {
        case .carMeet:    return .blue
        case .carShow:    return .orange
        case .trackDay:   return .red
        case .expo:       return .purple
        case .scenicDrive: return .green
        case .other:      return .gray
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
