import SwiftUI

struct EventPinView: View {
    let event: RallyEvent
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 2) {
            ZStack {
                Circle()
                    .fill(isSelected ? .primary : Color(.secondarySystemBackground))
                    .frame(width: isSelected ? 44 : 36, height: isSelected ? 44 : 36)
                    .shadow(color: .black.opacity(0.15), radius: 4, y: 2)

                Image(systemName: event.category.icon)
                    .font(.system(size: isSelected ? 18 : 14, weight: .semibold))
                    .foregroundStyle(isSelected ? Color(.systemBackground) : .primary)
            }

            // Pointer
            Triangle()
                .fill(isSelected ? .primary : Color(.secondarySystemBackground))
                .frame(width: 8, height: 5)
        }
        .animation(.spring(response: 0.25), value: isSelected)
    }
}

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        Path { p in
            p.move(to: CGPoint(x: rect.midX, y: rect.maxY))
            p.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            p.closeSubpath()
        }
    }
}
