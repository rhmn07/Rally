import UserNotifications

enum NotificationService {
    static func requestPermission() async {
        try? await UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge])
    }

    static func scheduleReminder(for event: RallyEvent) {
        let reminderDate = event.date.addingTimeInterval(-86400)
        guard reminderDate > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = "Event Tomorrow 🚗"
        content.body = "\(event.title) starts tomorrow at \(event.date.formatted(date: .omitted, time: .shortened))"
        content.sound = .default

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute], from: reminderDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(
            identifier: "rally-event-\(event.id)", content: content, trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
    }

    static func cancelReminder(for event: RallyEvent) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: ["rally-event-\(event.id)"])
    }
}
