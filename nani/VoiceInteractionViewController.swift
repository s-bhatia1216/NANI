//
//  VoiceInteractionViewController.swift
//  nani
//
//  Created by Yash Thakkar on 11/8/25.
//

import UIKit
import AVFoundation

class VoiceInteractionViewController: UIViewController {
    
    private let microphoneButton = UIButton(type: .custom)
    private let statusLabel = UILabel()
    private let responseLabel = UILabel()
    private let responseScrollView = UIScrollView()
    private let responseContentView = UIView()
    private var medicationContext: String?
    
    private var isRecording = false
    private let isoFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTheme()
        
        title = "AI Assistant"
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Close", style: .plain, target: self, action: #selector(closeTapped))
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(themeDidChange),
            name: .themeDidChange,
            object: nil
        )
        VoiceAssistantService.shared.onResponseReceived = { [weak self] response in
            DispatchQueue.main.async {
                self?.showResponse(response)
            }
        }
        VoiceAssistantService.shared.onError = { [weak self] error in
            DispatchQueue.main.async {
                self?.showError("Error: \(error.localizedDescription)")
            }
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Task { @MainActor [weak self] in
            self?.statusLabel.textColor = ThemeManager.shared.secondaryTextColor
            self?.statusLabel.text = "How can I help you today? Tap the microphone to ask a question"
            VoiceAssistantService.shared.playGreetingIfNeeded()
        }
    }
    
    func setMedicationContext(_ medication: String) {
        medicationContext = medication
    }
    
    private func setupUI() {
        view.backgroundColor = ThemeManager.shared.backgroundColor
        
        // Status Label
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.text = "How can I help you today? Tap the microphone to ask a question"
        statusLabel.font = UIFont.systemFont(ofSize: 16)
        statusLabel.textColor = ThemeManager.shared.secondaryTextColor
        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 0
        view.addSubview(statusLabel)
        
        // Microphone Button
        microphoneButton.translatesAutoresizingMaskIntoConstraints = false
        microphoneButton.backgroundColor = ThemeManager.shared.lightBlue
        microphoneButton.layer.cornerRadius = 60
        microphoneButton.setImage(UIImage(systemName: "mic.fill"), for: .normal)
        microphoneButton.tintColor = ThemeManager.shared.primaryBlue
        microphoneButton.addTarget(self, action: #selector(microphoneTapped), for: .touchUpInside)
        view.addSubview(microphoneButton)
        
        // Response Scroll View
        responseScrollView.translatesAutoresizingMaskIntoConstraints = false
        responseContentView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(responseScrollView)
        responseScrollView.addSubview(responseContentView)
        
        responseLabel.translatesAutoresizingMaskIntoConstraints = false
        responseLabel.text = medicationContext != nil ? "Ask me about \(medicationContext!)" : "I'm here to help with your medications. Ask me anything!"
        responseLabel.font = UIFont.systemFont(ofSize: 18)
        responseLabel.textColor = ThemeManager.shared.textColor
        responseLabel.numberOfLines = 0
        responseLabel.textAlignment = .center
        responseContentView.addSubview(responseLabel)
        
        NSLayoutConstraint.activate([
            statusLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            
            microphoneButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            microphoneButton.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -50),
            microphoneButton.widthAnchor.constraint(equalToConstant: 120),
            microphoneButton.heightAnchor.constraint(equalToConstant: 120),
            
            responseScrollView.topAnchor.constraint(equalTo: microphoneButton.bottomAnchor, constant: 40),
            responseScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            responseScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            responseScrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            responseContentView.topAnchor.constraint(equalTo: responseScrollView.topAnchor),
            responseContentView.leadingAnchor.constraint(equalTo: responseScrollView.leadingAnchor),
            responseContentView.trailingAnchor.constraint(equalTo: responseScrollView.trailingAnchor),
            responseContentView.bottomAnchor.constraint(equalTo: responseScrollView.bottomAnchor),
            responseContentView.widthAnchor.constraint(equalTo: responseScrollView.widthAnchor),
            
            responseLabel.topAnchor.constraint(equalTo: responseContentView.topAnchor, constant: 20),
            responseLabel.leadingAnchor.constraint(equalTo: responseContentView.leadingAnchor, constant: 20),
            responseLabel.trailingAnchor.constraint(equalTo: responseContentView.trailingAnchor, constant: -20),
            responseLabel.bottomAnchor.constraint(equalTo: responseContentView.bottomAnchor, constant: -20)
        ])
    }
    
    private func setupTheme() {
        view.backgroundColor = ThemeManager.shared.backgroundColor
        statusLabel.textColor = ThemeManager.shared.secondaryTextColor
        responseLabel.textColor = ThemeManager.shared.textColor
        microphoneButton.backgroundColor = ThemeManager.shared.lightBlue
        microphoneButton.tintColor = ThemeManager.shared.primaryBlue
    }
    
    @objc private func themeDidChange() {
        setupTheme()
    }
    
    @objc private func closeTapped() {
        dismiss(animated: true)
    }
    
    @objc private func microphoneTapped() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }
    
    private func startRecording() {
        guard !VoiceAssistantService.shared.isProcessingResponse else {
            showError("Please wait for the assistant to finish responding.")
            return
        }
        VoiceAssistantService.shared.requestSpeechAuthorization { [weak self] authorized in
            guard authorized else {
                DispatchQueue.main.async {
                    self?.showError("Speech recognition not authorized. Please enable it in Settings.")
                }
                return
            }
            
            DispatchQueue.main.async {
                self?.isRecording = true
                self?.microphoneButton.backgroundColor = .systemRed
                self?.statusLabel.text = "Listening... Speak now"
                Task { @MainActor in
                    VoiceAssistantService.shared.stopSpeaking()
                }
            }

            VoiceAssistantService.shared.startRecording { [weak self] result in
                DispatchQueue.main.async {
                    switch result {
                    case .success:
                        self?.responseLabel.text = "Listening..."
                    case .failure(let error):
                        self?.isRecording = false
                        self?.microphoneButton.backgroundColor = ThemeManager.shared.lightBlue
                        self?.showError("Error: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    private func stopRecording() {
        VoiceAssistantService.shared.stopRecording { [weak self] result in
            DispatchQueue.main.async {
                self?.isRecording = false
                self?.microphoneButton.backgroundColor = ThemeManager.shared.lightBlue
                switch result {
                case .success:
                    self?.statusLabel.text = "Processing your question..."
                case .failure(let error):
                    self?.showError("Error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func showResponse(_ response: AssistantResponse) {
        responseLabel.text = response.reply
        statusLabel.textColor = ThemeManager.shared.secondaryTextColor
        statusLabel.text = "Tap the microphone to ask another question"
        handleActions(response.actions ?? [])
    }
    
    private func handleActions(_ actions: [AssistantAction]) {
        actions.forEach { action in
            switch action.type {
            case "logMedication":
                let logDate: Date
                if let takenAtString = action.takenAt,
                   let parsedDate = isoFormatter.date(from: takenAtString) ?? ISO8601DateFormatter().date(from: takenAtString) {
                    logDate = parsedDate
                } else {
                    logDate = Date()
                }

                let medicationName = action.medicationName?.isEmpty == false ? action.medicationName! : "Medication"
                let displayText = "Logged \(medicationName)"

                var detailComponents: [String] = []
                if let dosage = action.dosage, !dosage.isEmpty {
                    detailComponents.append(dosage)
                }

                let timeFormatter = DateFormatter()
                timeFormatter.timeStyle = .short
                detailComponents.append(timeFormatter.string(from: logDate))

                if let caregiversNotified = action.caregiversNotified {
                    detailComponents.append(caregiversNotified ? "Care circle notified" : "Care circle not notified")
                }

                if let notes = action.notes, !notes.isEmpty {
                    detailComponents.append(notes)
                }

                MedicationLogManager.shared.logMedication(
                    displayText: displayText,
                    detailText: detailComponents.isEmpty ? nil : detailComponents.joined(separator: " • "),
                    date: logDate
                )
            default:
                break
            }
        }
    }
    
    private func showError(_ message: String) {
        statusLabel.text = message
        statusLabel.textColor = .systemRed
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.statusLabel.textColor = ThemeManager.shared.secondaryTextColor
            self.statusLabel.text = "Tap the microphone to ask a question"
        }
    }
}
