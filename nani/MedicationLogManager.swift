import Foundation

struct MedicationLog: Identifiable, Equatable {
    let id: UUID
    let date: Date
    let displayText: LocalizedText
    let detailText: LocalizedText?

    init(id: UUID = UUID(), date: Date = Date(), displayText: LocalizedText, detailText: LocalizedText? = nil) {
        self.id = id
        self.date = date
        self.displayText = displayText
        self.detailText = detailText
    }
    
    var localizedDisplayText: String {
        LocalizationManager.shared.localized(displayText)
    }
    
    var localizedDetailText: String? {
        guard let detailText else { return nil }
        return LocalizationManager.shared.localized(detailText)
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

    func logMedication(displayText: LocalizedText, detailText: LocalizedText? = nil, date: Date = Date()) {
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
                displayText: LocalizedText(english: "Took Lisinopril", hindi: "लिसिनोप्रिल ली"),
                detailText: LocalizedText(english: "8:00 AM • 10mg", hindi: "सुबह 8:00 बजे • 10 मिलीग्राम")
            ),
            MedicationLog(
                date: calendar.date(byAdding: .hour, value: -3, to: now) ?? now,
                displayText: LocalizedText(english: "Asked about side effects", hindi: "साइड इफेक्ट्स के बारे में पूछा"),
                detailText: LocalizedText(english: "AI assistant responded in Hindi", hindi: "एआई सहायक ने हिंदी में जवाब दिया")
            ),
            MedicationLog(
                date: calendar.date(byAdding: .day, value: -1, to: now) ?? now,
                displayText: LocalizedText(english: "Marked Metformin as taken", hindi: "मेटफॉर्मिन को लिया हुआ दर्ज किया"),
                detailText: LocalizedText(english: "8:00 PM • 500mg", hindi: "रात 8:00 बजे • 500 मिलीग्राम")
            ),
            MedicationLog(
                date: calendar.date(byAdding: .day, value: -1, to: now) ?? now,
                displayText: LocalizedText(english: "Son checked activity", hindi: "बेटे ने गतिविधि देखी"),
                detailText: LocalizedText(english: "Yash viewed today’s medication log", hindi: "यश ने आज की दवाई का लॉग देखा")
            )
        ]
    }
}
