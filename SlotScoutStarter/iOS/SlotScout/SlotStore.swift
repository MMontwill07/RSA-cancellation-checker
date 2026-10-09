import Foundation
import SwiftUI
import UserNotifications
import UIKit

struct Slot: Identifiable, Codable, Hashable {
    let id: String
    let centre: String
    let start: Date
    let simulated: Bool
}

@MainActor
final class SlotStore: ObservableObject {
    @AppStorage("centre") var centre = "Tallaght"
    @AppStorage("beforeTimestamp") private var beforeTimestamp = Date.now.addingTimeInterval(60 * 60 * 24 * 45).timeIntervalSince1970
    @AppStorage("weekends") var weekends = true
    @AppStorage("onboarded") var onboarded = false
    @AppStorage("alertsEnabled") var alertsEnabled = true
    @AppStorage("installationID") private var installationID = UUID().uuidString
    @Published var slots: [Slot] = []
    @Published var statusMessage = "Demo mode: no live RSA availability"
    @Published var deviceToken: String?
    @Published var notificationPermission = "Not requested"

    var beforeDate: Date {
        get { Date(timeIntervalSince1970: beforeTimestamp) }
        set { beforeTimestamp = newValue.timeIntervalSince1970 }
    }

    let centres = ["Tallaght", "Finglas", "Naas", "Dun Laoghaire", "Cork", "Galway", "Limerick", "Waterford", "Dundalk", "Sligo"]
    // Simulator connects to localhost; a physical iPhone needs a reachable HTTPS server.
    // Override in your Xcode scheme via SLOTSCOUT_API_BASE_URL environment variable.
    private var apiBase: URL? {
        guard let text = ProcessInfo.processInfo.environment["SLOTSCOUT_API_BASE_URL"] else { return nil }
        return URL(string: text)
    }

    var matchingSlots: [Slot] {
        slots.filter { slot in
            slot.centre == centre && slot.start < beforeDate &&
            (weekends || !Calendar.current.isDateInWeekend(slot.start))
        }.sorted { $0.start < $1.start }
    }

    func generateDemoSlot() {
        let date = Calendar.current.date(byAdding: .day, value: 3, to: Date()) ?? Date()
        let start = Calendar.current.date(bySettingHour: 10, minute: 30, second: 0, of: date) ?? date
        let slot = Slot(id: UUID().uuidString, centre: centre, start: start, simulated: true)
        slots.insert(slot, at: 0)
        statusMessage = "Simulated appointment created"
        if alertsEnabled && slot.start < beforeDate { scheduleLocalAlert(for: slot) }
    }

    func scheduleLocalAlert(for slot: Slot) {
        let content = UNMutableNotificationContent()
        content.title = "Earlier test slot (DEMO)"
        content.body = "\(slot.centre) • \(slot.start.formatted(date: .abbreviated, time: .shortened)) — simulated appointment"
        content.sound = .default
        content.userInfo = ["slotID": slot.id]
        let request = UNNotificationRequest(identifier: slot.id, content: content, trigger: UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false))
        UNUserNotificationCenter.current().add(request)
    }

    func enableNotifications() async {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
            notificationPermission = granted ? "Allowed" : "Denied"
            if granted { UIApplication.shared.registerForRemoteNotifications() }
        } catch { statusMessage = "Notification permission error: \(error.localizedDescription)" }
    }

    func syncRegistration() async {
        guard let apiBase, let deviceToken else { return }
        let url = apiBase.appendingPathComponent("register")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        // This demo installation ID is not authentication. Add real identity and auth before release.
        let body: [String: Any] = ["installationId": installationID, "token": deviceToken,
            "centre": centre, "before": ISO8601DateFormatter().string(from: beforeDate),
            "weekends": weekends, "alertsEnabled": alertsEnabled]
        req.httpBody = try? JSONSerialization.data(withJSONObject: body)
        do {
            let (_, response) = try await URLSession.shared.data(for: req)
            statusMessage = (response as? HTTPURLResponse)?.statusCode == 200 ? "Demo server connected" : "Server registration unsuccessful"
        } catch { statusMessage = "Demo server unreachable; local alerts still work" }
    }
}
