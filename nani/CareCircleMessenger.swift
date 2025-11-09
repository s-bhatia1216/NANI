import Foundation

extension Notification.Name {
    static let careCircleMessageSent = Notification.Name("CareCircleMessageSent")
}

final class CareCircleMessenger {
    static let shared = CareCircleMessenger()
    
    private init() {}
    
    func broadcastToCareCircle(message: LocalizedText, detail: LocalizedText? = nil) {
        MedicationLogManager.shared.logMedication(displayText: message, detailText: detail)
        NotificationCenter.default.post(name: .careCircleMessageSent, object: nil)
        #if DEBUG
        debugPrint("[CareCircleMessenger] broadcast: \(message.english)")
        #endif
    }
}


