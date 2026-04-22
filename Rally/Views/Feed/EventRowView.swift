import SwiftUI

struct EventRowView: View {
    let event: RallyEvent
    private let locationService = LocationService.shared

    var body: some View {
        HStack(spacing: 14) {
            // Thumbnail: photo or category icon
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemBackground))
                    .frame(width: 56, height: 56)

                if let urlString = event.imageURL, let url = URL(string: urlString) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let img):
                            img.resizable()
                                .scaledToFill()
                                .frame(width: 56, height: 56)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        default:
                            Image(systemName: event.category.icon)
                                .font(.system(size: 22, weight: .semibold))
                        }
                    }
                } else {
                    Image(systemName: event.category.icon)
                        .font(.system(size: 22, weight: .semibold))
                }
            }
            .frame(width: 56, height: 56)

            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.system(size: 15, weight: .semibold))
                    .lineLimit(1)

                Text(event.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)

                HStack(spacing: 10) {
                    Label(event.category.rawValue, systemImage: "tag")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)

                    if let loc = locationService.userLocation {
                        Text(event.formattedDistance(from: loc))
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 3) {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 11))
                    Text("\(event.attendeeCount)")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundStyle(.secondary)

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
    }
}
