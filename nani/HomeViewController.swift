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

    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTheme()
        
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
        applyActionButtonStyle(to: remindLaterButton, title: "Remind me later", systemImageName: "clock")
        
        takenButton.translatesAutoresizingMaskIntoConstraints = false
        takenButton.addTarget(self, action: #selector(takenTapped), for: .touchUpInside)
        nextMedicineContainer.addSubview(takenButton)
        applyActionButtonStyle(to: takenButton, title: "Taken", systemImageName: "checkmark")
        
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
        contentView.addSubview(careCircleContainer)
        
        // Care Circle Members
        careCircleStackView.translatesAutoresizingMaskIntoConstraints = false
        careCircleStackView.axis = .horizontal
        careCircleStackView.spacing = 12
        careCircleStackView.alignment = .center
        careCircleContainer.addSubview(careCircleStackView)
        
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
        careCircleContainer.addSubview(chatBubbleView)
        
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
            
            careCircleStackView.topAnchor.constraint(equalTo: careCircleContainer.topAnchor, constant: 16),
            careCircleStackView.leadingAnchor.constraint(equalTo: careCircleContainer.leadingAnchor, constant: 16),
            careCircleStackView.trailingAnchor.constraint(lessThanOrEqualTo: chatBubbleView.leadingAnchor, constant: -12),
            
            chatBubbleView.topAnchor.constraint(equalTo: careCircleContainer.topAnchor, constant: 16),
            chatBubbleView.trailingAnchor.constraint(equalTo: careCircleContainer.trailingAnchor, constant: -16),
            chatBubbleView.bottomAnchor.constraint(equalTo: careCircleContainer.bottomAnchor, constant: -16),
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
        applyActionButtonStyle(to: remindLaterButton, title: "Remind me later", systemImageName: "clock")
        applyActionButtonStyle(to: takenButton, title: "Taken", systemImageName: "checkmark")
    }

    private func applyActionButtonStyle(to button: UIButton, title: String, systemImageName: String) {
        var configuration = UIButton.Configuration.plain()
        configuration.title = title
        configuration.image = UIImage(systemName: systemImageName)
        configuration.imagePlacement = .leading
        configuration.imagePadding = 6
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16)
        configuration.baseForegroundColor = ThemeManager.shared.primaryBlue
        configuration.background.cornerRadius = 20
        configuration.background.backgroundColor = ThemeManager.shared.lightBlue
        button.configuration = configuration
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
        
        let nameLabel = UILabel()
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.text = name
        nameLabel.font = UIFont.systemFont(ofSize: 12)
        nameLabel.textColor = ThemeManager.shared.textColor
        nameLabel.textAlignment = .center
        container.addSubview(nameLabel)
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: container.topAnchor),
            imageView.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 60),
            imageView.heightAnchor.constraint(equalToConstant: 60),
            
            nameLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 8),
            nameLabel.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            nameLabel.bottomAnchor.constraint(equalTo: container.bottomAnchor)
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
        titleLabel.text = log.displayText
        titleLabel.numberOfLines = 0
        textStack.addArrangedSubview(titleLabel)
        
        if let detail = log.detailText, !detail.isEmpty {
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
            emptyLabel.text = "No recent activity."
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
        let alert = UIAlertController(title: "Language", message: "Select your preferred language", preferredStyle: .actionSheet)
        let languages = ["English", "Spanish", "Hindi", "Mandarin", "French", "Arabic"]
        for language in languages {
            alert.addAction(UIAlertAction(title: language, style: .default) { _ in
                // TODO: Implement language change
                print("Selected language: \(language)")
            })
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
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
        // TODO: Schedule reminder
        print("Remind later tapped")
    }
    
    @objc private func takenTapped() {
        // TODO: Mark medicine as taken
        print("Taken tapped")
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


