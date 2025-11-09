//
//  HomeViewController.swift
//  nani
//
//  Created by Yash Thakkar on 11/8/25.
//

import UIKit

private let medicationLogsToDisplay = 5

class HomeViewController: UIViewController {
    
    // MARK: - Properties
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    // Header Section
    private let profileImageView = UIImageView()
    private let greetingLabel = UILabel()
    private let languageButton = UIButton(type: .system)
    
    // AI Voice Assistant Section
    private let microphoneButton = UIButton(type: .custom)
    private let voicePromptLabel = UILabel()
    
    // Next Medicine Section
    private let nextMedicineContainer = UIView()
    private let pillIcon = UIImageView()
    private let nextMedicineLabel = UILabel()
    private let medicineNameLabel = UILabel()
    private let remindLaterButton = UIButton(type: .custom)
    private let takenButton = UIButton(type: .custom)
    
    // Care Circle Section
    private let careCircleTitleLabel = UILabel()
    private let careCircleStackView = UIStackView()
    private let chatBubbleView = UIView()
    private let chatMessageLabel = UILabel()
    private let activityLogStackView = UIStackView()

    // Localization
    private let greetingsText = LocalizedText(english: "Good Morning, Maya", hindi: "सुप्रभात, माया")
    private let voicePromptText = LocalizedText(english: "Ask me anything about your medicine, Maya.", hindi: "अपनी दवा के बारे में मुझसे कुछ भी पूछें, माया।")
    private let nextMedicineTitleText = LocalizedText(english: "Next medicine", hindi: "अगली दवाई")
    private let nextMedicineDetailText = LocalizedText(english: "Lisinopril at 8:00 AM", hindi: "सुबह 8:00 बजे लिसिनोप्रिल")
    private let remindLaterText = LocalizedText(english: "Remind me later", hindi: "बाद में याद दिलाएं")
    private let takenText = LocalizedText(english: "Taken", hindi: "ली गई")
    private let careCircleTitleText = LocalizedText(english: "Your Care Circle", hindi: "आपका केयर सर्कल")
    private let careCircleMessageText = LocalizedText(english: "Hope you're feeling well today!", hindi: "आशा है आज आप अच्छा महसूस कर रहे हैं!")
    private let emptyActivityText = LocalizedText(english: "No recent activity.", hindi: "हाल में कोई गतिविधि नहीं।")
    private let nextMedicineNameText = LocalizedText(english: "Lisinopril", hindi: "लिसिनोप्रिल")
    private let nextMedicineTimeText = LocalizedText(english: "8:00 AM", hindi: "सुबह 8:00 बजे")
    private let careCircleAlertTitleText = LocalizedText(english: "Care Circle Notified", hindi: "केयर सर्कल को सूचित किया गया")
    private let careCircleRemindConfirmationText = LocalizedText(english: "Your caregivers know you'll take this dose later.", hindi: "आपके केयरगिवर्स को पता चला कि आप यह दवाई बाद में लेंगे।")
    private let careCircleTakenConfirmationText = LocalizedText(english: "Your caregivers know you've taken this dose.", hindi: "आपके केयरगिवर्स को पता है कि आपने यह दवाई ले ली है।")
    
    
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
            selector: #selector(medicationLogsUpdated),
            name: MedicationLogManager.logsUpdatedNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(languageDidChange),
            name: .languageDidChange,
            object: nil
        )
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = ThemeManager.shared.backgroundColor
        
        setupScrollView()
        setupHeaderSection()
        setupVoiceAssistantSection()
        setupNextMedicineSection()
        setupCareCircleSection()
        
        setupConstraints()
    }
    
    private func setupScrollView() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        scrollView.showsVerticalScrollIndicator = false
    }
    
    private func setupHeaderSection() {
        // Profile Image
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.clipsToBounds = true
        profileImageView.layer.cornerRadius = 30
        profileImageView.backgroundColor = ThemeManager.shared.lightBlue
        // Load user's profile image
        if let mayaImage = UIImage(named: "maya") {
            profileImageView.image = mayaImage
        } else {
            profileImageView.image = createPlaceholderProfileImage()
        }
        profileImageView.isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(profileImageTapped))
        profileImageView.addGestureRecognizer(tapGesture)
        contentView.addSubview(profileImageView)
        
        // Greeting Label
        greetingLabel.translatesAutoresizingMaskIntoConstraints = false
        greetingLabel.text = "Good Morning, Maya"
        greetingLabel.font = UIFont.boldSystemFont(ofSize: 28)
        greetingLabel.textColor = ThemeManager.shared.textColor
        contentView.addSubview(greetingLabel)
        
        // Language Button
        languageButton.translatesAutoresizingMaskIntoConstraints = false
        languageButton.setImage(UIImage(systemName: "globe"), for: .normal)
        languageButton.tintColor = ThemeManager.shared.primaryBlue
        languageButton.backgroundColor = ThemeManager.shared.lightBlue
        languageButton.layer.cornerRadius = 20
        languageButton.addTarget(self, action: #selector(languageButtonTapped), for: .touchUpInside)
        contentView.addSubview(languageButton)
    }
    
    private func setupVoiceAssistantSection() {
        // Microphone Button
        microphoneButton.translatesAutoresizingMaskIntoConstraints = false
        microphoneButton.backgroundColor = ThemeManager.shared.lightBlue
        microphoneButton.layer.cornerRadius = 50
        microphoneButton.setImage(UIImage(systemName: "mic.fill"), for: .normal)
        microphoneButton.tintColor = ThemeManager.shared.primaryBlue
        microphoneButton.addTarget(self, action: #selector(microphoneButtonTapped), for: .touchUpInside)
        contentView.addSubview(microphoneButton)
        
        // Voice Prompt Label
        voicePromptLabel.translatesAutoresizingMaskIntoConstraints = false
        voicePromptLabel.text = "Ask me anything about your medicine, Maya."
        voicePromptLabel.font = UIFont.systemFont(ofSize: 16)
        voicePromptLabel.textColor = ThemeManager.shared.textColor
        voicePromptLabel.textAlignment = .center
        voicePromptLabel.numberOfLines = 0
        contentView.addSubview(voicePromptLabel)
    }
    
    private func setupNextMedicineSection() {
        nextMedicineContainer.translatesAutoresizingMaskIntoConstraints = false
        nextMedicineContainer.backgroundColor = ThemeManager.shared.cardBackgroundColor
        nextMedicineContainer.layer.cornerRadius = 16
        contentView.addSubview(nextMedicineContainer)
        
        // Pill Icon
        pillIcon.translatesAutoresizingMaskIntoConstraints = false
        pillIcon.image = UIImage(systemName: "pills.fill")
        pillIcon.tintColor = ThemeManager.shared.primaryBlue
        pillIcon.contentMode = .scaleAspectFit
        nextMedicineContainer.addSubview(pillIcon)
        
        // Medicine Labels Container
        let medicineLabelsContainer = UIView()
        medicineLabelsContainer.translatesAutoresizingMaskIntoConstraints = false
        nextMedicineContainer.addSubview(medicineLabelsContainer)
        
        nextMedicineLabel.translatesAutoresizingMaskIntoConstraints = false
        nextMedicineLabel.text = "Next medicine"
        nextMedicineLabel.font = UIFont.systemFont(ofSize: 14)
        nextMedicineLabel.textColor = ThemeManager.shared.textColor
        medicineLabelsContainer.addSubview(nextMedicineLabel)
        
        medicineNameLabel.translatesAutoresizingMaskIntoConstraints = false
        medicineNameLabel.text = "Lisinopril at 8:00 AM"
        medicineNameLabel.font = UIFont.boldSystemFont(ofSize: 16)
        medicineNameLabel.textColor = ThemeManager.shared.textColor
        medicineLabelsContainer.addSubview(medicineNameLabel)
        
        // Action Buttons
        remindLaterButton.translatesAutoresizingMaskIntoConstraints = false
        remindLaterButton.addTarget(self, action: #selector(remindLaterTapped), for: .touchUpInside)
        nextMedicineContainer.addSubview(remindLaterButton)
        applyActionButtonStyle(to: remindLaterButton, text: remindLaterText, systemImageName: "clock")
        
        takenButton.translatesAutoresizingMaskIntoConstraints = false
        takenButton.addTarget(self, action: #selector(takenTapped), for: .touchUpInside)
        nextMedicineContainer.addSubview(takenButton)
        applyActionButtonStyle(to: takenButton, text: takenText, systemImageName: "checkmark")
        
        // Stack buttons horizontally
        let buttonStackView = UIStackView(arrangedSubviews: [remindLaterButton, takenButton])
        buttonStackView.translatesAutoresizingMaskIntoConstraints = false
        buttonStackView.axis = .horizontal
        buttonStackView.spacing = 12
        buttonStackView.distribution = .fillEqually
        nextMedicineContainer.addSubview(buttonStackView)
        
        NSLayoutConstraint.activate([
            medicineLabelsContainer.topAnchor.constraint(equalTo: nextMedicineContainer.topAnchor, constant: 16),
            medicineLabelsContainer.leadingAnchor.constraint(equalTo: pillIcon.trailingAnchor, constant: 12),
            medicineLabelsContainer.trailingAnchor.constraint(equalTo: nextMedicineContainer.trailingAnchor, constant: -16),
            
            nextMedicineLabel.topAnchor.constraint(equalTo: medicineLabelsContainer.topAnchor),
            nextMedicineLabel.leadingAnchor.constraint(equalTo: medicineLabelsContainer.leadingAnchor),
            nextMedicineLabel.trailingAnchor.constraint(equalTo: medicineLabelsContainer.trailingAnchor),
            
            medicineNameLabel.topAnchor.constraint(equalTo: nextMedicineLabel.bottomAnchor, constant: 4),
            medicineNameLabel.leadingAnchor.constraint(equalTo: medicineLabelsContainer.leadingAnchor),
            medicineNameLabel.trailingAnchor.constraint(equalTo: medicineLabelsContainer.trailingAnchor),
            medicineNameLabel.bottomAnchor.constraint(equalTo: medicineLabelsContainer.bottomAnchor),
            
            buttonStackView.topAnchor.constraint(equalTo: medicineLabelsContainer.bottomAnchor, constant: 12),
            buttonStackView.leadingAnchor.constraint(equalTo: pillIcon.trailingAnchor, constant: 12),
            buttonStackView.trailingAnchor.constraint(equalTo: nextMedicineContainer.trailingAnchor, constant: -16),
            buttonStackView.heightAnchor.constraint(equalToConstant: 40),
            buttonStackView.bottomAnchor.constraint(equalTo: nextMedicineContainer.bottomAnchor, constant: -16)
        ])
    }
    
    private func setupCareCircleSection() {
        careCircleTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        careCircleTitleLabel.text = "Your Care Circle"
        careCircleTitleLabel.font = UIFont.boldSystemFont(ofSize: 20)
        careCircleTitleLabel.textColor = ThemeManager.shared.textColor
        contentView.addSubview(careCircleTitleLabel)
        
        // Care Circle Container
        let careCircleContainer = UIView()
        careCircleContainer.translatesAutoresizingMaskIntoConstraints = false
        careCircleContainer.backgroundColor = ThemeManager.shared.cardBackgroundColor
        careCircleContainer.layer.cornerRadius = 16
        let careCircleTapGesture = UITapGestureRecognizer(target: self, action: #selector(careCircleTapped))
        careCircleContainer.addGestureRecognizer(careCircleTapGesture)
        careCircleContainer.isAccessibilityElement = true
        careCircleContainer.accessibilityLabel = "Your Care Circle"
        contentView.addSubview(careCircleContainer)
        
        // Care Circle Content Stack
        let careCircleContentStack = UIStackView()
        careCircleContentStack.translatesAutoresizingMaskIntoConstraints = false
        careCircleContentStack.axis = .horizontal
        careCircleContentStack.spacing = 12
        careCircleContentStack.alignment = .center
        careCircleContainer.addSubview(careCircleContentStack)
        
        // Care Circle Members
        careCircleStackView.translatesAutoresizingMaskIntoConstraints = false
        careCircleStackView.axis = .horizontal
        careCircleStackView.spacing = 12
        careCircleStackView.alignment = .center
        careCircleContentStack.addArrangedSubview(careCircleStackView)
        
        // Yash Profile
        let yashImage = UIImage(named: "yash") ?? createPlaceholderProfileImage()
        let yashView = createProfileView(name: "Yash Thakkar", image: yashImage)
        careCircleStackView.addArrangedSubview(yashView)
        
        // Sonal Profile
        let sonalImage = UIImage(named: "sonal") ?? createPlaceholderProfileImage()
        let sonalView = createProfileView(name: "Sonal Bhatia", image: sonalImage)
        careCircleStackView.addArrangedSubview(sonalView)
        
        // Chat Bubble
        chatBubbleView.translatesAutoresizingMaskIntoConstraints = false
        chatBubbleView.backgroundColor = ThemeManager.shared.lightBlue
        chatBubbleView.layer.cornerRadius = 12
        chatBubbleView.setContentHuggingPriority(.required, for: .horizontal)
        chatBubbleView.setContentCompressionResistancePriority(.required, for: .horizontal)
        careCircleContentStack.addArrangedSubview(chatBubbleView)
        
        chatMessageLabel.translatesAutoresizingMaskIntoConstraints = false
        chatMessageLabel.text = "Hope you're feeling well today!"
        chatMessageLabel.font = UIFont.systemFont(ofSize: 14)
        chatMessageLabel.textColor = ThemeManager.shared.primaryBlue
        chatMessageLabel.numberOfLines = 0
        chatBubbleView.addSubview(chatMessageLabel)
        
        // Activity Log Container
        let activityContainer = UIView()
        activityContainer.translatesAutoresizingMaskIntoConstraints = false
        activityContainer.backgroundColor = ThemeManager.shared.cardBackgroundColor
        activityContainer.layer.cornerRadius = 16
        contentView.addSubview(activityContainer)
        
        // Activity Log
        activityLogStackView.translatesAutoresizingMaskIntoConstraints = false
        activityLogStackView.axis = .vertical
        activityLogStackView.spacing = 12
        activityLogStackView.alignment = .leading
        activityContainer.addSubview(activityLogStackView)
        
        updateActivityLog()
        
        // Update constraints
        NSLayoutConstraint.activate([
            careCircleContainer.topAnchor.constraint(equalTo: careCircleTitleLabel.bottomAnchor, constant: 12),
            careCircleContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            careCircleContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            careCircleContentStack.topAnchor.constraint(equalTo: careCircleContainer.topAnchor, constant: 16),
            careCircleContentStack.leadingAnchor.constraint(equalTo: careCircleContainer.leadingAnchor, constant: 16),
            careCircleContentStack.trailingAnchor.constraint(equalTo: careCircleContainer.trailingAnchor, constant: -16),
            careCircleContentStack.bottomAnchor.constraint(equalTo: careCircleContainer.bottomAnchor, constant: -16),
            
            chatBubbleView.widthAnchor.constraint(greaterThanOrEqualToConstant: 150),
            
            chatMessageLabel.topAnchor.constraint(equalTo: chatBubbleView.topAnchor, constant: 8),
            chatMessageLabel.leadingAnchor.constraint(equalTo: chatBubbleView.leadingAnchor, constant: 12),
            chatMessageLabel.trailingAnchor.constraint(equalTo: chatBubbleView.trailingAnchor, constant: -12),
            chatMessageLabel.bottomAnchor.constraint(equalTo: chatBubbleView.bottomAnchor, constant: -8),
            
            activityContainer.topAnchor.constraint(equalTo: careCircleContainer.bottomAnchor, constant: 16),
            activityContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            activityContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            activityLogStackView.topAnchor.constraint(equalTo: activityContainer.topAnchor, constant: 16),
            activityLogStackView.leadingAnchor.constraint(equalTo: activityContainer.leadingAnchor, constant: 16),
            activityLogStackView.trailingAnchor.constraint(equalTo: activityContainer.trailingAnchor, constant: -16),
            activityLogStackView.bottomAnchor.constraint(equalTo: activityContainer.bottomAnchor, constant: -16),
            activityContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])
    }
    
    private func setupTheme() {
        view.backgroundColor = ThemeManager.shared.backgroundColor
        profileImageView.backgroundColor = ThemeManager.shared.lightBlue
        greetingLabel.textColor = ThemeManager.shared.textColor
        languageButton.tintColor = ThemeManager.shared.primaryBlue
        languageButton.backgroundColor = ThemeManager.shared.lightBlue
        microphoneButton.backgroundColor = ThemeManager.shared.lightBlue
        microphoneButton.tintColor = ThemeManager.shared.primaryBlue
        voicePromptLabel.textColor = ThemeManager.shared.textColor
        pillIcon.tintColor = ThemeManager.shared.primaryBlue
        nextMedicineLabel.textColor = ThemeManager.shared.textColor
        medicineNameLabel.textColor = ThemeManager.shared.textColor
        careCircleTitleLabel.textColor = ThemeManager.shared.textColor
        chatBubbleView.backgroundColor = ThemeManager.shared.lightBlue
        chatMessageLabel.textColor = ThemeManager.shared.primaryBlue
        updateActivityLog()
        applyActionButtonStyle(to: remindLaterButton, text: remindLaterText, systemImageName: "clock")
        applyActionButtonStyle(to: takenButton, text: takenText, systemImageName: "checkmark")
    }

    private func applyActionButtonStyle(to button: UIButton, text: LocalizedText, systemImageName: String) {
        var configuration = UIButton.Configuration.plain()
        configuration.title = LocalizationManager.shared.localized(text)
        configuration.image = UIImage(systemName: systemImageName)
        configuration.imagePlacement = .leading
        configuration.imagePadding = 6
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16)
        configuration.baseForegroundColor = ThemeManager.shared.primaryBlue
        configuration.background.cornerRadius = 20
        configuration.background.backgroundColor = ThemeManager.shared.lightBlue
        button.configuration = configuration
    }
    
    private func updateLocalizedStrings() {
        let manager = LocalizationManager.shared
        greetingLabel.text = manager.localized(greetingsText)
        voicePromptLabel.text = manager.localized(voicePromptText)
        nextMedicineLabel.text = manager.localized(nextMedicineTitleText)
        medicineNameLabel.text = manager.localized(nextMedicineDetailText)
        careCircleTitleLabel.text = manager.localized(careCircleTitleText)
        chatMessageLabel.text = manager.localized(careCircleMessageText)
        applyActionButtonStyle(to: remindLaterButton, text: remindLaterText, systemImageName: "clock")
        applyActionButtonStyle(to: takenButton, text: takenText, systemImageName: "checkmark")
        let languageAccessibility = manager.localized(english: "Change language", hindi: "भाषा बदलें")
        languageButton.accessibilityLabel = languageAccessibility
        updateActivityLog()
    }
    
    // MARK: - Helper Methods
    private func createPlaceholderProfileImage() -> UIImage? {
        let size = CGSize(width: 60, height: 60)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            ThemeManager.shared.lightBlue.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            ThemeManager.shared.primaryBlue.setFill()
            let circleRect = CGRect(x: 15, y: 10, width: 30, height: 30)
            context.cgContext.fillEllipse(in: circleRect)
        }
    }
    
    private func createProfileView(name: String, image: UIImage?) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = image
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 30
        container.addSubview(imageView)
        
        container.isAccessibilityElement = true
        container.accessibilityLabel = name
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: container.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 60),
            imageView.heightAnchor.constraint(equalToConstant: 60),
            imageView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        
        return container
    }
    
    private func createActivityItem(for log: MedicationLog) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        
        let iconView = UIImageView()
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.image = UIImage(systemName: "checkmark.circle.fill")
        iconView.tintColor = ThemeManager.shared.primaryBlue
        iconView.contentMode = .scaleAspectFit
        container.addSubview(iconView)
        
        let textStack = UIStackView()
        textStack.translatesAutoresizingMaskIntoConstraints = false
        textStack.axis = .vertical
        textStack.spacing = 2
        container.addSubview(textStack)
        
        let titleLabel = UILabel()
        titleLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        titleLabel.textColor = ThemeManager.shared.textColor
        titleLabel.text = log.localizedDisplayText
        titleLabel.numberOfLines = 0
        textStack.addArrangedSubview(titleLabel)
        
        if let detail = log.localizedDetailText, !detail.isEmpty {
            let detailLabel = UILabel()
            detailLabel.font = UIFont.systemFont(ofSize: 12)
            detailLabel.textColor = ThemeManager.shared.secondaryTextColor
            detailLabel.text = detail
            detailLabel.numberOfLines = 0
            textStack.addArrangedSubview(detailLabel)
        }
        
        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            iconView.topAnchor.constraint(equalTo: container.topAnchor, constant: 2),
            iconView.widthAnchor.constraint(equalToConstant: 20),
            iconView.heightAnchor.constraint(equalToConstant: 20),
            
            textStack.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 8),
            textStack.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            textStack.topAnchor.constraint(equalTo: container.topAnchor),
            textStack.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        
        return container
    }
    
    @objc private func medicationLogsUpdated() {
        updateActivityLog()
    }
    
    private func updateActivityLog() {
        activityLogStackView.arrangedSubviews.forEach { subview in
            activityLogStackView.removeArrangedSubview(subview)
            subview.removeFromSuperview()
        }
        let logs = MedicationLogManager.shared.logs.prefix(medicationLogsToDisplay)
        if logs.isEmpty {
            let emptyLabel = UILabel()
            emptyLabel.translatesAutoresizingMaskIntoConstraints = false
            emptyLabel.text = LocalizationManager.shared.localized(emptyActivityText)
            emptyLabel.font = UIFont.systemFont(ofSize: 14)
            emptyLabel.textColor = ThemeManager.shared.secondaryTextColor
            activityLogStackView.addArrangedSubview(emptyLabel)
            return
        }
        logs.forEach { log in
            let item = createActivityItem(for: log)
            activityLogStackView.addArrangedSubview(item)
        }
    }
    
    // MARK: - Constraints
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // ScrollView
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // Header Section
            profileImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            profileImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            profileImageView.widthAnchor.constraint(equalToConstant: 60),
            profileImageView.heightAnchor.constraint(equalToConstant: 60),
            
            greetingLabel.centerYAnchor.constraint(equalTo: profileImageView.centerYAnchor),
            greetingLabel.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 12),
            
            languageButton.centerYAnchor.constraint(equalTo: profileImageView.centerYAnchor),
            languageButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            languageButton.widthAnchor.constraint(equalToConstant: 40),
            languageButton.heightAnchor.constraint(equalToConstant: 40),
            
            // Voice Assistant Section
            microphoneButton.topAnchor.constraint(equalTo: profileImageView.bottomAnchor, constant: 30),
            microphoneButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            microphoneButton.widthAnchor.constraint(equalToConstant: 100),
            microphoneButton.heightAnchor.constraint(equalToConstant: 100),
            
            voicePromptLabel.topAnchor.constraint(equalTo: microphoneButton.bottomAnchor, constant: 16),
            voicePromptLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 40),
            voicePromptLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -40),
            
            // Next Medicine Section
            nextMedicineContainer.topAnchor.constraint(equalTo: voicePromptLabel.bottomAnchor, constant: 30),
            nextMedicineContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            nextMedicineContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            pillIcon.topAnchor.constraint(equalTo: nextMedicineContainer.topAnchor, constant: 16),
            pillIcon.leadingAnchor.constraint(equalTo: nextMedicineContainer.leadingAnchor, constant: 16),
            pillIcon.widthAnchor.constraint(equalToConstant: 24),
            pillIcon.heightAnchor.constraint(equalToConstant: 24),
            
            // Care Circle Section
            careCircleTitleLabel.topAnchor.constraint(equalTo: nextMedicineContainer.bottomAnchor, constant: 30),
            careCircleTitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            careCircleTitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
        ])
    }
    
    // MARK: - Actions
    @objc private func languageButtonTapped() {
        let manager = LocalizationManager.shared
        let title = manager.localized(english: "Language", hindi: "भाषा")
        let message = manager.localized(english: "Select your preferred language", hindi: "अपनी पसंदीदा भाषा चुनें")
        let alert = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
        
        let coreLanguages: [(LocalizedText, AppLanguage?)] = [
            (LocalizedText(english: "English", hindi: "अंग्रेज़ी"), .english),
            (LocalizedText(english: "Hindi", hindi: "हिन्दी"), .hindi),
            (LocalizedText(english: "Spanish", hindi: "स्पैनिश"), nil),
            (LocalizedText(english: "Mandarin", hindi: "मंदारिन"), nil),
            (LocalizedText(english: "French", hindi: "फ़्रेंच"), nil),
            (LocalizedText(english: "Arabic", hindi: "अरबी"), nil)
        ]
        
        coreLanguages.forEach { entry in
            let (label, language) = entry
            let baseTitle = manager.localized(label)
            let actionTitle: String
            if let language, manager.isCurrentLanguage(language) {
                actionTitle = "\(baseTitle) ✓"
            } else {
                actionTitle = baseTitle
            }
            
            let action = UIAlertAction(title: actionTitle, style: .default) { _ in
                guard let language else {
                    print("Language option coming soon: \(label.english)")
                    return
                }
                LocalizationManager.shared.setLanguage(language)
            }
            alert.addAction(action)
        }
        
        let cancelTitle = manager.localized(english: "Cancel", hindi: "रद्द करें")
        alert.addAction(UIAlertAction(title: cancelTitle, style: .cancel))
        
        if let popover = alert.popoverPresentationController {
            popover.sourceView = languageButton
            popover.sourceRect = languageButton.bounds
        }
        
        present(alert, animated: true)
    }
    
    @objc private func microphoneButtonTapped() {
        let voiceVC = VoiceInteractionViewController()
        let navController = UINavigationController(rootViewController: voiceVC)
        present(navController, animated: true)
    }
    
    @objc private func profileImageTapped() {
        showSideMenu()
    }
    
    private func showSideMenu() {
        let sideMenuVC = SideMenuViewController()
        sideMenuVC.delegate = self
        let navController = UINavigationController(rootViewController: sideMenuVC)
        navController.modalPresentationStyle = .pageSheet
        
        if let sheet = navController.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
        }
        
        present(navController, animated: true)
    }
    
    @objc private func remindLaterTapped() {
        sendCareCircleUpdate(action: .remindLater)
    }
    
    @objc private func takenTapped() {
        sendCareCircleUpdate(action: .taken)
    }
    
    @objc private func languageDidChange() {
        updateLocalizedStrings()
    }
    
    private enum CareCircleAction {
        case remindLater
        case taken
    }
    
    private func sendCareCircleUpdate(action: CareCircleAction) {
        let haptic = UINotificationFeedbackGenerator()
        haptic.notificationOccurred(.success)
        
        let message: LocalizedText
        let detail = LocalizedText(
            english: "Care circle notified about the \(nextMedicineTimeText.english) dose.",
            hindi: "\(nextMedicineTimeText.hindi) की खुराक के बारे में केयर सर्कल को सूचित किया गया।"
        )
        
        switch action {
        case .remindLater:
            message = LocalizedText(
                english: "Maya will take \(nextMedicineNameText.english) a little later.",
                hindi: "माया \(nextMedicineNameText.hindi) थोड़ी देर में लेंगी।"
            )
            CareCircleMessenger.shared.broadcastToCareCircle(message: message, detail: detail)
            presentCareCircleConfirmation(message: careCircleRemindConfirmationText)
        case .taken:
            message = LocalizedText(
                english: "Maya just took \(nextMedicineNameText.english).",
                hindi: "माया ने अभी \(nextMedicineNameText.hindi) ले ली है।"
            )
            CareCircleMessenger.shared.broadcastToCareCircle(message: message, detail: detail)
            presentCareCircleConfirmation(message: careCircleTakenConfirmationText)
        }
    }
    
    private func presentCareCircleConfirmation(message: LocalizedText) {
        let manager = LocalizationManager.shared
        if let presented = presentedViewController {
            presented.dismiss(animated: false)
        }
        let alert = UIAlertController(
            title: manager.localized(careCircleAlertTitleText),
            message: manager.localized(message),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: manager.localized(english: "OK", hindi: "ठीक है"), style: .default))
        present(alert, animated: true)
    }
    
    @objc private func careCircleTapped() {
        let careCircleVC = CareCircleViewController()
        navigationController?.pushViewController(careCircleVC, animated: true)
    }
    
    @objc private func themeDidChange() {
        setupTheme()
    }
}

// MARK: - SideMenuDelegate
extension HomeViewController: SideMenuDelegate {
    func didSelectProfile() {
        dismiss(animated: true) {
            let profileVC = ProfileViewController()
            self.navigationController?.pushViewController(profileVC, animated: true)
        }
    }
    
    func didSelectCareCircle() {
        dismiss(animated: true) {
            let careCircleVC = CareCircleViewController()
            self.navigationController?.pushViewController(careCircleVC, animated: true)
        }
    }
    
    func didSelectHelp() {
        dismiss(animated: true) {
            let helpVC = HelpViewController()
            self.navigationController?.pushViewController(helpVC, animated: true)
        }
    }
}


