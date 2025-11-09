import Foundation

struct MedicationLog: Identifiable, Equatable {
    let id: UUID
    let date: Date
    let displayText: String
    let detailText: String?

    init(id: UUID = UUID(), date: Date = Date(), displayText: String, detailText: String? = nil) {
        self.id = id
        self.date = date
        self.displayText = displayText
        self.detailText = detailText
    }
}

final class MedicationLogManager {

    static let shared = MedicationLogManager()
    static let logsUpdatedNotification = Notification.Name("MedicationLogManagerLogsUpdated")

    private(set) var logs: [MedicationLog] = []
    private let queue = DispatchQueue(label: "com.nani.medicationLogManager.queue", attributes: .concurrent)

    private init() {
        seedMockLogsIfNeeded()
    }

    func logMedication(displayText: String, detailText: String? = nil, date: Date = Date()) {
        let newLog = MedicationLog(date: date, displayText: displayText, detailText: detailText)
        queue.async(flags: .barrier) { [weak self] in
            guard let self else { return }
            self.logs.insert(newLog, at: 0)
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: Self.logsUpdatedNotification, object: nil)
            }
        }
    }

    func replaceLogs(_ newLogs: [MedicationLog]) {
        queue.async(flags: .barrier) { [weak self] in
            guard let self else { return }
            self.logs = newLogs.sorted(by: { $0.date > $1.date })
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: Self.logsUpdatedNotification, object: nil)
            }
        }
    }

    private func seedMockLogsIfNeeded() {
        guard logs.isEmpty else { return }
        let calendar = Calendar.current
        let now = Date()

        logs = [
            MedicationLog(
                date: now,
                displayText: "Took Lisinopril",
                detailText: "8:00 AM • 10mg"
            ),
            MedicationLog(
                date: calendar.date(byAdding: .hour, value: -3, to: now) ?? now,
                displayText: "Asked about side effects",
                detailText: "AI assistant responded in Hindi"
            ),
            MedicationLog(
                date: calendar.date(byAdding: .day, value: -1, to: now) ?? now,
                displayText: "Marked Metformin as taken",
                detailText: "8:00 PM • 500mg"
            ),
            MedicationLog(
                date: calendar.date(byAdding: .day, value: -1, to: now) ?? now,
                displayText: "Son checked activity",
                detailText: "Yash viewed today’s medication log"
            )
        ]
    }
}
