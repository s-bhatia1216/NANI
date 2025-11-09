//
//  PillDetectionListener.swift
//  nani
//
//  Created by Yash Thakkar on 11/8/25.
//

import Foundation

final class PillDetectionListener: NSObject, URLSessionDataDelegate {
    static let shared = PillDetectionListener()
    
    private var eventSource: URLSessionDataTask?
    private lazy var session: URLSession = {
        URLSession(configuration: .default, delegate: self, delegateQueue: nil)
    }()
    private var buffer = Data()
    private let isoFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
    
    private override init() {}
    
    func start() {
        guard eventSource == nil else { return }
        guard let baseURL = VoiceAssistantService.shared.backendBaseURL else { return }
        let streamURL = baseURL.appendingPathComponent("events/sheet")
        let request = URLRequest(url: streamURL, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 0)
        eventSource = session.dataTask(with: request)
        eventSource?.resume()
    }
    
    func handleEvent(event: String?, data: String) {
        guard event == "pillDetected" else { return }
        guard let payload = data.data(using: .utf8) else { return }
        guard let decoded = try? JSONDecoder().decode(PillEvent.self, from: payload) else { return }
        let medicationName = decoded.entry?["Medication"] ?? decoded.entry?["medicine"] ?? "Medicine"
        let message = LocalizedText(
            english: "\(medicationName) pill was taken.",
            hindi: "\(medicationName) गोली ली गई (शीट डिटेक्शन)।"
        )
        let detectedTime = formattedTime(from: decoded.timestamp) ?? formattedSheetTimestamp(decoded.entry?["Timestamp"])
        let detail = detectedTime.map {
            LocalizedText(
                english: "Detected at \($0).",
                hindi: "\($0) पर पता चला।"
            )
        }
        CareCircleMessenger.shared.broadcastToCareCircle(message: message, detail: detail)
    }
}

private struct PillEvent: Decodable {
    let type: String
    let timestamp: String
    let entry: [String: String]?
}

// MARK: - URLSessionDataDelegate
extension PillDetectionListener {
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        buffer.append(data)
        let separator = Data("\n\n".utf8)
        while let range = buffer.range(of: separator) {
            let chunk = buffer.subdata(in: buffer.startIndex..<range.lowerBound)
            buffer.removeSubrange(buffer.startIndex..<range.upperBound)
            process(chunk: chunk)
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        eventSource = nil
        buffer.removeAll()
        if let error {
            debugPrint("[PillDetectionListener] SSE error:", error.localizedDescription)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.start()
        }
    }
    
    private func process(chunk: Data) {
        guard let text = String(data: chunk, encoding: .utf8) else { return }
        var eventName: String?
        var dataLines: [String] = []
        text.split(separator: "\n").forEach { line in
            if line.hasPrefix("event:") {
                eventName = line.replacingOccurrences(of: "event:", with: "").trimmingCharacters(in: .whitespaces)
            } else if line.hasPrefix("data:") {
                let value = line.replacingOccurrences(of: "data:", with: "").trimmingCharacters(in: .whitespaces)
                dataLines.append(value)
            }
        }
        guard !dataLines.isEmpty else { return }
        let payload = dataLines.joined(separator: "\n")
        handleEvent(event: eventName, data: payload)
    }
    
    private func formattedTime(from iso: String) -> String? {
        guard let date = isoFormatter.date(from: iso) else { return nil }
        return DateFormatter.localizedString(from: date, dateStyle: .none, timeStyle: .medium)
    }
    
    private func formattedSheetTimestamp(_ raw: String?) -> String? {
        guard let raw, !raw.isEmpty else { return nil }
        if let date = isoFormatter.date(from: raw) {
            return DateFormatter.localizedString(from: date, dateStyle: .none, timeStyle: .medium)
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d/yyyy H:mm:ss"
        if let date = formatter.date(from: raw) {
            return DateFormatter.localizedString(from: date, dateStyle: .none, timeStyle: .medium)
        }
        return raw
    }
}
