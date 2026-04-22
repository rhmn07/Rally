import SwiftUI

struct CategoryBadge: View {
    let category: EventCategory

    var body: some View {
        Label(category.rawValue, systemImage: category.icon)
            .font(.system(size: 12, weight: .medium))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color(.secondarySystemBackground))
            .clipShape(Capsule())
    }
}
