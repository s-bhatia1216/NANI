//
//  VoiceAssistantService.swift
//  nani
//
//  Created by Yash Thakkar on 11/8/25.
//

import Foundation
import AVFoundation

struct AssistantAction: Codable {
    let type: String
    let medicationName: String?
    let dosage: String?
    let takenAt: String?
    let caregiversNotified: Bool?
    let notes: String?
}

struct AssistantResponse: Codable {
    let reply: String
    let actions: [AssistantAction]?
}

enum VoiceAssistantError: LocalizedError {
    case invalidEndpoint
    case backendUnavailable
    case recordingNotStarted
    case audioEncodingFailed
    case decodingFailed
    case busyProcessing

    var errorDescription: String? {
        switch self {
        case .invalidEndpoint:
            return "The voice backend endpoint is invalid."
        case .backendUnavailable:
            return "The voice assistant service is currently unavailable."
        case .recordingNotStarted:
            return "Recording has not started."
        case .audioEncodingFailed:
            return "Unable to prepare microphone audio for the assistant."
        case .decodingFailed:
            return "Could not decode the assistant's response."
        case .busyProcessing:
            return "Please wait while I finish the previous request."
        }
    }
}

final class VoiceAssistantService: NSObject {
    static let shared = VoiceAssistantService()

    /// Update this to point to the Node backend (e.g. http://localhost:4000 during development).
    var backendBaseURL: URL? = URL(string: "http://127.0.0.1:4000")

    private let audioSession = AVAudioSession.sharedInstance()
    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?
    private let recordingURL = FileManager.default.temporaryDirectory.appendingPathComponent("nani-voice-query.wav")
    private let urlSession = URLSession(configuration: .default)
    private let speechSynthesizer = AVSpeechSynthesizer()
    private var hasPlayedGreeting = false

    private(set) var isRecording = false
    private(set) var isProcessingResponse = false

    var onResponseReceived: ((AssistantResponse) -> Void)?
    var onError: ((Error) -> Void)?

    private override init() {
        super.init()
        configureAudioSession()
    }

    private func configureAudioSession() {
        do {
            try audioSession.setCategory(
                .playAndRecord,
                mode: .voiceChat,
                options: [.defaultToSpeaker, .allowBluetoothHFP]
            )
            try audioSession.setActive(true)
        } catch {
            debugLog("Audio session configuration failed: \(error)")
        }
    }

    // MARK: - Permissions

    func requestSpeechAuthorization(completion: @escaping (Bool) -> Void) {
        let handler: (Bool) -> Void = { granted in
            DispatchQueue.main.async {
                completion(granted)
            }
        }

        if #available(iOS 17.0, *) {
            AVAudioApplication.requestRecordPermission(completionHandler: handler)
        } else {
            audioSession.requestRecordPermission(handler)
        }
    }

    // MARK: - Recording

    func startRecording(completion: @escaping (Result<Void, Error>) -> Void) {
        guard !isRecording else {
            completion(.success(()))
            return
        }

        guard !isProcessingResponse else {
            completion(.failure(VoiceAssistantError.busyProcessing))
            return
        }

        do {
            try audioSession.setActive(true)
            try prepareRecorder()
            guard audioRecorder?.record() == true else {
                throw VoiceAssistantError.audioEncodingFailed
            }
            isRecording = true
            completion(.success(()))
        } catch {
            completion(.failure(error))
        }
    }

    func stopRecording(completion: @escaping (Result<Void, Error>) -> Void) {
        guard isRecording else {
            completion(.failure(VoiceAssistantError.recordingNotStarted))
            return
        }

        audioRecorder?.stop()
        audioRecorder = nil
        isRecording = false

        let audioFileURL = recordingURL
        completion(.success(()))
        isProcessingResponse = true

        Task { [weak self] in
            guard let self else { return }
            do {
                try await self.sendAudioToBackend(fileURL: audioFileURL)
            } catch {
                await self.deliver(error: error)
            }
            self.isProcessingResponse = false
        }
    }

    func cancelRecording() {
        audioRecorder?.stop()
        audioRecorder = nil
        isRecording = false
    }

    // MARK: - Backend Integration

    private func sendAudioToBackend(fileURL: URL) async throws {
        guard let baseURL = backendBaseURL else {
            throw VoiceAssistantError.invalidEndpoint
        }

        let endpoint = baseURL.appendingPathComponent("api/voice-exchange")
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"

        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        body.appendString("--\(boundary)\r\n")
        body.appendString("Content-Disposition: form-data; name=\"audio\"; filename=\"query.wav\"\r\n")
        body.appendString("Content-Type: audio/wav\r\n\r\n")
        body.append(try Data(contentsOf: fileURL))
        body.appendString("\r\n--\(boundary)--\r\n")

        let (data, response) = try await urlSession.upload(for: request, from: body)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw VoiceAssistantError.backendUnavailable
        }

        do {
            let decoded = try JSONDecoder().decode(VoiceBackendResponse.self, from: data)
            await deliverSuccess(decoded)
        } catch {
            throw VoiceAssistantError.decodingFailed
        }
    }

    @MainActor
    private func deliverSuccess(_ backendResponse: VoiceBackendResponse) {
        let trimmed = backendResponse.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        let reply = trimmed?.isEmpty == false ? trimmed! : "I'm here."
        let assistantResponse = AssistantResponse(reply: reply, actions: [])
        onResponseReceived?(assistantResponse)

        if let base64 = backendResponse.audioBase64,
           let audioData = Data(base64Encoded: base64) {
            playAudioResponse(from: audioData)
        } else {
            speakFallback(reply)
        }
    }

    @MainActor
    private func deliver(error: Error) {
        onError?(error)
    }

    // MARK: - Audio Helpers

    private func prepareRecorder() throws {
        if FileManager.default.fileExists(atPath: recordingURL.path) {
            try FileManager.default.removeItem(at: recordingURL)
        }

        let settings: [String: Any] = [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVSampleRateKey: 16_000,
            AVNumberOfChannelsKey: 1,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMIsFloatKey: false,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        audioRecorder = try AVAudioRecorder(url: recordingURL, settings: settings)
        audioRecorder?.isMeteringEnabled = true
        audioRecorder?.prepareToRecord()
    }

    private func playAudioResponse(from data: Data) {
        do {
            speechSynthesizer.stopSpeaking(at: .immediate)
            audioPlayer?.stop()
            audioPlayer = try AVAudioPlayer(data: data)
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
        } catch {
            speakFallback("\(error.localizedDescription)")
        }
    }

    @MainActor
    private func speakFallback(_ text: String) {
        audioPlayer?.stop()
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        speechSynthesizer.speak(utterance)
    }

    // MARK: - Greeting Helpers

    @MainActor
    func playGreetingIfNeeded() {
        guard !hasPlayedGreeting else { return }
        hasPlayedGreeting = true
        speakFallback("How can I help you today?")
    }

    @MainActor
    func stopSpeaking() {
        audioPlayer?.stop()
        speechSynthesizer.stopSpeaking(at: .immediate)
    }

    // MARK: - Debug

    #if DEBUG
    private func debugLog(_ message: String) {
        print("[VoiceAssistantService] \(message)")
    }
    #else
    private func debugLog(_ message: String) {}
    #endif
}

// MARK: - Backend DTOs

private struct VoiceBackendResponse: Decodable {
    let text: String?
    let audioFormat: String?
    let audioBase64: String?
    let rawResponseId: String?
}

private extension Data {
    mutating func appendString(_ string: String) {
        guard let data = string.data(using: .utf8) else { return }
        append(data)
    }
}
