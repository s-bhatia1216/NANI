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
            return LocalizationManager.shared.localized(english: "The voice backend endpoint is invalid.", hindi: "वॉइस बैकएंड एंडपॉइंट अमान्य है।")
        case .backendUnavailable:
            return LocalizationManager.shared.localized(english: "The voice assistant service is currently unavailable.", hindi: "वॉइस सहायक सेवा वर्तमान में उपलब्ध नहीं है।")
        case .recordingNotStarted:
            return LocalizationManager.shared.localized(english: "Recording has not started.", hindi: "रिकॉर्डिंग शुरू नहीं हुई है।")
        case .audioEncodingFailed:
            return LocalizationManager.shared.localized(english: "Unable to prepare microphone audio for the assistant.", hindi: "सहायक के लिए माइक्रोफोन ऑडियो तैयार नहीं किया जा सका।")
        case .decodingFailed:
            return LocalizationManager.shared.localized(english: "Could not decode the assistant's response.", hindi: "सहायक के जवाब को डिकोड नहीं किया जा सका।")
        case .busyProcessing:
            return LocalizationManager.shared.localized(english: "Please wait while I finish the previous request.", hindi: "कृपया तब तक प्रतीक्षा करें जब तक मैं पिछली अनुरोध को पूरा कर लूँ।")
        }
    }
}

final class VoiceAssistantService: NSObject, URLSessionDataDelegate {
    static let shared = VoiceAssistantService()

    /// Update this to point to the Node backend (e.g. http://localhost:4000 during development).
    var backendBaseURL: URL? = URL(string: "http://127.0.0.1:4000")

    private let audioSession = AVAudioSession.sharedInstance()
    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?
    private var greetingAudioPlayer: AVAudioPlayer?
    private let recordingURL = FileManager.default.temporaryDirectory.appendingPathComponent("nani-voice-query.wav")
    private lazy var urlSession: URLSession = {
        URLSession(configuration: .default, delegate: self, delegateQueue: nil)
    }()
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
        let fallback = LocalizationManager.shared.localized(english: "I'm here.", hindi: "मैं यहाँ हूँ।")
        let reply = trimmed?.isEmpty == false ? trimmed! : fallback
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
            print("oh audio failed")
        }
    }

    @MainActor
    private func speakFallback(_ text: String) {
        audioPlayer?.stop()
        let utterance = AVSpeechUtterance(string: text)
        let language = LocalizationManager.shared.currentLanguage
        if let preferredIdentifier = preferredVoiceIdentifier(for: language),
           let preferredVoice = AVSpeechSynthesisVoice(identifier: preferredIdentifier) {
            utterance.voice = preferredVoice
        } else {
            let fallbackLanguageCode: String
            switch language {
            case .english:
                fallbackLanguageCode = "en-US"
            case .hindi:
                fallbackLanguageCode = "hi-IN"
            }
            utterance.voice = AVSpeechSynthesisVoice(language: fallbackLanguageCode)
        }
        
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.85
        utterance.pitchMultiplier = 1.05
        utterance.preUtteranceDelay = 0.05
        utterance.postUtteranceDelay = 0.05
        speechSynthesizer.speak(utterance)
    }

    // MARK: - Greeting Helpers

    @MainActor
    func playGreetingIfNeeded() {
        guard !hasPlayedGreeting else { return }
        hasPlayedGreeting = true
        _ = playGreetingAudioIfAvailable()
    }

    @MainActor
    func stopSpeaking() {
        audioPlayer?.stop()
        greetingAudioPlayer?.stop()
        speechSynthesizer.stopSpeaking(at: .immediate)
    }
    
    private func preferredVoiceIdentifier(for language: AppLanguage) -> String? {
        switch language {
        case .english:
            let premium = "com.apple.ttsbundle.Samantha-premium"
            if AVSpeechSynthesisVoice(identifier: premium) != nil {
                return premium
            }
            return "com.apple.ttsbundle.Samantha-compact"
        case .hindi:
            // Natural-sounding Hindi voice; fall back to compact variant if premium unavailable
            let premium = "com.apple.ttsbundle.Priyanka-premium"
            if AVSpeechSynthesisVoice(identifier: premium) != nil {
                return premium
            }
            return "com.apple.ttsbundle.Priyanka-compact"
        }
    }
    
    @MainActor
    private func playGreetingAudioIfAvailable() -> Bool {
        guard let url = Bundle.main.url(forResource: "nani_reply", withExtension: "wav") else {
            return false
        }
        
        do {
            speechSynthesizer.stopSpeaking(at: .immediate)
            audioPlayer?.stop()
            greetingAudioPlayer?.stop()
            
            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            player.play()
            greetingAudioPlayer = player
            return true
        } catch {
            debugLog("Failed to play greeting audio: \(error)")
            return false
        }
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
