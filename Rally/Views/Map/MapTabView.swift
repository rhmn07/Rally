import SwiftUI
import MapKit

struct MapTabView: View {
    @EnvironmentObject var eventsVM: EventsViewModel
    @EnvironmentObject var mapVM: MapViewModel
    @Binding var showCreateEvent: Bool
    @State private var showEventDetail: RallyEvent?

    var body: some View {
        ZStack(alignment: .bottom) {
            Map(coordinateRegion: $mapVM.region, showsUserLocation: true, annotationItems: eventsVM.events) { event in
                MapAnnotation(coordinate: event.coordinate) {
                    EventPinView(event: event, isSelected: mapVM.selectedEvent?.id == event.id)
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3)) {
                                mapVM.selectedEvent = event
                            }
                        }
                }
            }
            .ignoresSafeArea()
            .onAppear {
                mapVM.requestLocationIfNeeded()
                mapVM.centerOnUser()
            }

            // Callout card
            if let event = mapVM.selectedEvent {
                VStack {
                    Spacer()
                    EventCalloutView(event: event) {
                        showEventDetail = event
                    } onDismiss: {
                        withAnimation(.spring(response: 0.3)) {
                            mapVM.selectedEvent = nil
                        }
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.bottom, 100)
                }
                .animation(.spring(response: 0.35), value: mapVM.selectedEvent?.id)
            }

            // FAB
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button {
                        showCreateEvent = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(.background)
                            .frame(width: 56, height: 56)
                            .background(.primary)
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.18), radius: 8, y: 4)
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 100)
                }
            }

            // Locate me button
            VStack {
                HStack {
                    Spacer()
                    Button {
                        withAnimation { mapVM.centerOnUser() }
                    } label: {
                        Image(systemName: "location.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.primary)
                            .frame(width: 40, height: 40)
                            .background(.regularMaterial)
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
                    }
                    .padding(.trailing, 16)
                    .padding(.top, 56)
                }
                Spacer()
            }
        }
        .sheet(item: $showEventDetail) { event in
            EventDetailView(event: event)
                .environmentObject(eventsVM)
        }
    }
}
