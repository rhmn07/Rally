import SwiftUI
import MapKit

struct EventDetailView: View {
    let event: RallyEvent
    @EnvironmentObject var eventsVM: EventsViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var isRSVPing = false
    @State private var showDeleteConfirm = false
    @State private var comments: [Comment] = []
    @State private var commentText = ""
    @State private var isPostingComment = false

    private var isAttending: Bool { eventsVM.isAttending(event) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Hero
                    heroSection

                    VStack(alignment: .leading, spacing: 24) {
                        // Title + organizer
                        VStack(alignment: .leading, spacing: 6) {
                            CategoryBadge(category: event.category)

                            Text(event.title)
                                .font(.system(size: 26, weight: .bold))

                            Text("by \(event.organizerName)")
                                .font(.system(size: 14))
                                .foregroundStyle(.secondary)
                        }

                        Divider()

                        // Date & Location
                        infoRow(icon: "calendar", text: event.date.formatted(date: .complete, time: .shortened))
                        infoRow(icon: "location.fill", text: event.address, link: mapsURL)

                        Divider()

                        // Attendees
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 8) {
                                Image(systemName: "person.2.fill")
                                    .font(.system(size: 14))
                                    .foregroundStyle(.secondary)
                                if let cap = event.capacity {
                                    Text("\(event.attendeeCount) / \(cap) going")
                                        .font(.system(size: 14, weight: .medium))
                                    if event.isFull {
                                        Text("· Full")
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundStyle(.red)
                                    } else {
                                        Text("· \(cap - event.attendeeCount) spots left")
                                            .font(.system(size: 13))
                                            .foregroundStyle(.secondary)
                                    }
                                } else {
                                    Text("\(event.attendeeCount) going")
                                        .font(.system(size: 14, weight: .medium))
                                }
                            }
                        }

                        Divider()

                        // Description
                        if !event.description.isEmpty {
                            Text(event.description)
                                .font(.system(size: 15))
                                .foregroundStyle(.secondary)
                                .lineSpacing(4)
                        }

                        Divider()

                        // Comments
                        commentsSection

                        Spacer(minLength: 100)
                    }
                    .padding(20)
                }
            }
            .ignoresSafeArea(edges: .top)
            .task {
                for await batch in commentsStream() {
                    comments = batch
                }
            }
            .safeAreaInset(edge: .bottom) {
                rsvpButton
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(.regularMaterial)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.secondary)
                            .font(.system(size: 24))
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    ShareLink(
                        item: "\(event.title)\n\(event.date.formatted(date: .long, time: .shortened))\n\(event.address)\n\(event.description)"
                    ) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
                if eventsVM.isOrganizer(event) {
                    ToolbarItem(placement: .destructiveAction) {
                        Button(role: .destructive) {
                            showDeleteConfirm = true
                        } label: {
                            Image(systemName: "trash")
                        }
                    }
                }
            }
            .confirmationDialog("Delete this event?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
                Button("Delete", role: .destructive) {
                    Task {
                        await eventsVM.deleteEvent(event)
                        await MainActor.run { dismiss() }
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This cannot be undone.")
            }
            .toolbarBackground(.hidden, for: .navigationBar)
        }
    }

    private var heroSection: some View {
        ZStack(alignment: .bottomLeading) {
            if let urlStr = event.photoURL, let url = URL(string: urlStr) {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    categoryGradient
                }
                .frame(height: 260)
                .clipped()
            } else {
                categoryGradient.frame(height: 260)
            }
        }
    }

    private var categoryGradient: some View {
        LinearGradient(
            colors: [.gray.opacity(0.3), .gray.opacity(0.1)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay {
            Image(systemName: event.category.icon)
                .font(.system(size: 64, weight: .thin))
                .foregroundStyle(.white.opacity(0.4))
        }
    }

    private var rsvpButton: some View {
        Button {
            isRSVPing = true
            Task {
                await eventsVM.toggleRSVP(for: event)
                isRSVPing = false
            }
        } label: {
            HStack {
                if isRSVPing {
                    ProgressView()
                        .tint(isAttending ? .primary : Color(.systemBackground))
                } else {
                    Image(systemName: isAttending ? "checkmark.circle.fill" : "plus.circle.fill")
                    Text(isAttending ? "You're Going" : "I'm Going")
                        .font(.system(size: 16, weight: .semibold))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(isAttending ? Color(.secondarySystemBackground) : .primary)
            .foregroundStyle(isAttending ? .primary : Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .disabled(isRSVPing || eventsVM.isOrganizer(event) || (!isAttending && event.isFull))
        .animation(.easeInOut(duration: 0.2), value: isAttending)
    }

    @ViewBuilder
    private func infoRow(icon: String, text: String, link: URL? = nil) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
                .frame(width: 20)
            if let url = link {
                Link(text, destination: url)
                    .font(.system(size: 14))
                    .tint(.primary)
            } else {
                Text(text)
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var commentsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Comments")
                .font(.system(size: 17, weight: .semibold))

            if comments.isEmpty {
                Text("No comments yet. Be the first!")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            } else {
                ForEach(comments) { comment in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(comment.authorName)
                                .font(.system(size: 13, weight: .semibold))
                            Spacer()
                            Text(comment.createdAt.formatted(date: .abbreviated, time: .shortened))
                                .font(.system(size: 11))
                                .foregroundStyle(.tertiary)
                        }
                        Text(comment.text)
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                    }
                    .padding(12)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }

            HStack(spacing: 10) {
                TextField("Add a comment…", text: $commentText, axis: .vertical)
                    .font(.system(size: 14))
                    .padding(10)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .lineLimit(1...4)

                Button {
                    postComment()
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 30))
                }
                .disabled(commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isPostingComment)
            }
        }
    }

    private func postComment() {
        let text = commentText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        guard let uid = eventsVM.currentUserID else { return }
        let name = eventsVM.currentUserName
        let comment = Comment(id: UUID().uuidString, authorID: uid, authorName: name, text: text, createdAt: Date())
        commentText = ""
        isPostingComment = true
        Task {
            try? await FirebaseService.shared.postComment(comment, eventID: event.id)
            isPostingComment = false
        }
    }

    private func commentsStream() -> AsyncStream<[Comment]> {
        AsyncStream { continuation in
            let listener = FirebaseService.shared.commentsListener(eventID: event.id) { comments in
                continuation.yield(comments)
            }
            continuation.onTermination = { _ in listener.remove() }
        }
    }

    private var mapsURL: URL? {
        let encoded = event.address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        return URL(string: "http://maps.apple.com/?q=\(encoded)")
    }
}
