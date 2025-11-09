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
    private var medicationContext: LocalizedText?
    
    private var isRecording = false
    private var isShowingPlaceholderResponse = true
    private let isoFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
    
    private let defaultStatusText = LocalizedText(
        english: "How can I help you today? Tap the microphone to ask a question",
        hindi: "मैं आपकी आज कैसे मदद कर सकता हूँ? प्रश्न पूछने के लिए माइक्रोफ़ोन पर टैप करें"
    )
    private let defaultResponseText = LocalizedText(
        english: "I'm here to help with your medications. Ask me anything!",
        hindi: "मैं आपकी दवाइयों में मदद करने के लिए यहाँ हूँ। मुझसे कुछ भी पूछें!"
    )
    private let listeningStatusText = LocalizedText(
        english: "Listening... Speak now",
        hindi: "सुन रहा हूँ... अब बोलें"
    )
    private let listeningResponseText = LocalizedText(
        english: "Listening...",
        hindi: "सुन रहा हूँ..."
    )
    private let processingStatusText = LocalizedText(
        english: "Processing your question...",
        hindi: "आपके प्रश्न को संसाधित किया जा रहा है..."
    )
    private let askAnotherQuestionText = LocalizedText(
        english: "Tap the microphone to ask another question",
        hindi: "एक और प्रश्न पूछने के लिए माइक्रोफ़ोन पर टैप करें"
    )
    private let waitForResponseText = LocalizedText(
        english: "Please wait for the assistant to finish responding.",
        hindi: "कृपया सहायक के जवाब देने तक प्रतीक्षा करें।"
    )
    private let closeButtonText = LocalizedText(english: "Close", hindi: "बंद करें")
    private let errorPrefixText = LocalizedText(english: "Error", hindi: "त्रुटि")
    private let recordingNotAuthorizedText = LocalizedText(
        english: "Speech recognition not authorized. Please enable it in Settings.",
        hindi: "स्पीच रिकग्निशन अधिकृत नहीं है। कृपया इसे सेटिंग्स में सक्षम करें।"
    )
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTheme()
        updateLocalizedStrings()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(themeDidChange),
            name: .themeDidChange,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(languageDidChange),
            name: .languageDidChange,
            object: nil
        )
        VoiceAssistantService.shared.onResponseReceived = { [weak self] response in
            DispatchQueue.main.async {
                self?.showResponse(response)
            }
        }
        VoiceAssistantService.shared.onError = { [weak self] error in
            DispatchQueue.main.async {
                self?.showError(error.localizedDescription)
            }
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Task { @MainActor [weak self] in
            guard let self else { return }
            self.statusLabel.textColor = ThemeManager.shared.secondaryTextColor
            self.statusLabel.text = self.localized(self.defaultStatusText)
            VoiceAssistantService.shared.playGreetingIfNeeded()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        VoiceAssistantService.shared.stopSpeaking()
        if isRecording {
            VoiceAssistantService.shared.cancelRecording()
            isRecording = false
            microphoneButton.backgroundColor = ThemeManager.shared.lightBlue
        }
    }
    
    func setMedicationContext(_ medication: LocalizedText) {
        medicationContext = medication
        if isViewLoaded {
            updateResponsePlaceholder()
        }
    }
    
    private func setupUI() {
        view.backgroundColor = ThemeManager.shared.backgroundColor
        
        // Status Label
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.text = localized(defaultStatusText)
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
        if medicationContext != nil {
            updateResponsePlaceholder()
        } else {
            responseLabel.text = localized(defaultResponseText)
            isShowingPlaceholderResponse = true
        }
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
    
    private func localized(_ text: LocalizedText) -> String {
        LocalizationManager.shared.localized(text)
    }
    
    private func setStatusToDefault() {
        statusLabel.textColor = ThemeManager.shared.secondaryTextColor
        statusLabel.text = localized(defaultStatusText)
    }
    
    private func askAboutMedicationString(for context: LocalizedText) -> String {
        switch LocalizationManager.shared.currentLanguage {
        case .english:
            return "Ask me about \(context.english)"
        case .hindi:
            return "\(context.hindi) के बारे में मुझसे पूछें"
        }
    }
    
    private func updateResponsePlaceholder() {
        if let context = medicationContext {
            responseLabel.text = askAboutMedicationString(for: context)
        } else {
            responseLabel.text = localized(defaultResponseText)
        }
        responseLabel.textColor = ThemeManager.shared.textColor
        isShowingPlaceholderResponse = true
    }
    
    private func updateLocalizedStrings() {
        let manager = LocalizationManager.shared
        title = manager.localized(english: "AI Assistant", hindi: "एआई सहायक")
        if let closeButton = navigationItem.leftBarButtonItem {
            closeButton.title = localized(closeButtonText)
            closeButton.target = self
            closeButton.action = #selector(closeTapped)
        } else {
            navigationItem.leftBarButtonItem = UIBarButtonItem(
                title: localized(closeButtonText),
                style: .plain,
                target: self,
                action: #selector(closeTapped)
            )
        }
        
        if !isRecording && statusLabel.textColor != .systemRed {
            setStatusToDefault()
        } else if isRecording {
            statusLabel.text = localized(listeningStatusText)
        }
        
        if isShowingPlaceholderResponse {
            updateResponsePlaceholder()
        }
    }
    
    @objc private func languageDidChange() {
        updateLocalizedStrings()
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
            showError(localized(waitForResponseText), isLocalized: true)
            return
        }
        VoiceAssistantService.shared.requestSpeechAuthorization { [weak self] authorized in
            guard authorized else {
                DispatchQueue.main.async {
                    guard let self else { return }
                    self.showError(self.localized(self.recordingNotAuthorizedText), isLocalized: true)
                }
                return
            }
            
            DispatchQueue.main.async {
                guard let self else { return }
                self.isRecording = true
                self.microphoneButton.backgroundColor = .systemRed
                self.statusLabel.textColor = ThemeManager.shared.secondaryTextColor
                self.statusLabel.text = self.localized(self.listeningStatusText)
                Task { @MainActor in
                    VoiceAssistantService.shared.stopSpeaking()
                }
            }

            VoiceAssistantService.shared.startRecording { [weak self] result in
                DispatchQueue.main.async {
                    guard let self else { return }
                    switch result {
                    case .success:
                        self.responseLabel.text = self.localized(self.listeningResponseText)
                        self.isShowingPlaceholderResponse = false
                    case .failure(let error):
                        self.isRecording = false
                        self.microphoneButton.backgroundColor = ThemeManager.shared.lightBlue
                        self.showError(error.localizedDescription)
                    }
                }
            }
        }
    }
    
    private func stopRecording() {
        VoiceAssistantService.shared.stopRecording { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                self.isRecording = false
                self.microphoneButton.backgroundColor = ThemeManager.shared.lightBlue
                switch result {
                case .success:
                    self.statusLabel.textColor = ThemeManager.shared.secondaryTextColor
                    self.statusLabel.text = self.localized(self.processingStatusText)
                case .failure(let error):
                    self.showError(error.localizedDescription)
                }
            }
        }
    }
    
    private func showResponse(_ response: AssistantResponse) {
        responseLabel.text = response.reply
        isShowingPlaceholderResponse = false
        statusLabel.textColor = ThemeManager.shared.secondaryTextColor
        statusLabel.text = localized(askAnotherQuestionText)
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

                let medicationNameText: LocalizedText
                if let providedName = action.medicationName?.trimmingCharacters(in: .whitespacesAndNewlines),
                   !providedName.isEmpty {
                    medicationNameText = .same(providedName)
                } else {
                    medicationNameText = LocalizedText(english: "Medication", hindi: "दवाई")
                }
                let displayText = LocalizedText(
                    english: "Logged \(medicationNameText.english)",
                    hindi: "\(medicationNameText.hindi) दर्ज किया गया"
                )
                
                var detailComponents: [LocalizedText] = []
                if let dosage = action.dosage, !dosage.isEmpty {
                    detailComponents.append(.same(dosage))
                }

                let timeFormatter = DateFormatter()
                timeFormatter.timeStyle = .short
                detailComponents.append(.same(timeFormatter.string(from: logDate)))

                if let caregiversNotified = action.caregiversNotified {
                    let caregiversText = caregiversNotified
                    ? LocalizedText(english: "Care circle notified", hindi: "केयर सर्कल को सूचित किया गया")
                    : LocalizedText(english: "Care circle not notified", hindi: "केयर सर्कल को सूचित नहीं किया गया")
                    detailComponents.append(caregiversText)
                }

                if let notes = action.notes, !notes.isEmpty {
                    detailComponents.append(.same(notes))
                }

                let detailText: LocalizedText?
                if detailComponents.isEmpty {
                    detailText = nil
                } else {
                    let english = detailComponents.map { $0.english }.joined(separator: " • ")
                    let hindi = detailComponents.map { $0.hindi }.joined(separator: " • ")
                    detailText = LocalizedText(english: english, hindi: hindi)
                }
                
                MedicationLogManager.shared.logMedication(
                    displayText: displayText,
                    detailText: detailText,
                    date: logDate
                )
            default:
                break
            }
        }
    }
    
    private func showError(_ message: String, isLocalized: Bool = false) {
        let prefix = localized(errorPrefixText)
        statusLabel.text = isLocalized ? message : "\(prefix): \(message)"
        statusLabel.textColor = .systemRed
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.statusLabel.textColor = ThemeManager.shared.secondaryTextColor
            self.setStatusToDefault()
        }
    }
}
