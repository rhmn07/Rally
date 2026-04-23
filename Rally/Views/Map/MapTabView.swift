import SwiftUI
import MapKit

struct MapTabView: View {
    @EnvironmentObject var eventsVM: EventsViewModel
    @EnvironmentObject var mapVM: MapViewModel
    @Binding var showCreateEvent: Bool
    @State private var showEventDetail: RallyEvent?

    var body: some View {
        ZStack(alignment: .bottom) {
            Map(position: $mapVM.position) {
                UserAnnotation()
                ForEach(eventsVM.events) { event in
                    Annotation(event.title, coordinate: event.coordinate, anchor: .bottom) {
                        EventPinView(event: event, isSelected: mapVM.selectedEvent?.id == event.id)
                            .onTapGesture {
                                withAnimation(.spring(response: 0.3)) {
                                    mapVM.selectedEvent = event
                                }
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

            // Top-right controls: locate + create event
            VStack {
                HStack {
                    Spacer()
                    VStack(spacing: 10) {
                        Button {
                            withAnimation { mapVM.centerOnUser() }
                        } label: {
                            Image(systemName: "location.fill")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(.primary)
                                .frame(width: 44, height: 44)
                                .background(.regularMaterial)
                                .clipShape(Circle())
                                .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
                        }

                        Button {
                            showCreateEvent = true
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(.background)
                                .frame(width: 44, height: 44)
                                .background(.primary)
                                .clipShape(Circle())
                                .shadow(color: .black.opacity(0.18), radius: 6, y: 3)
                        }
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
