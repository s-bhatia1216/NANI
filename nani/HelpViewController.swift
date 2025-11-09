//
//  HelpViewController.swift
//  nani
//
//  Created by Yash Thakkar on 11/8/25.
//

import UIKit

class HelpViewController: UIViewController {
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let tutorialButton = UIButton(type: .custom)
    private var helpCardLabels: [(titleLabel: UILabel, descriptionLabel: UILabel, titleText: LocalizedText, descriptionText: LocalizedText)] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTheme()
        updateLocalizedStrings()
        
        title = LocalizationManager.shared.localized(english: "Help & Tutorial", hindi: "सहायता और ट्यूटोरियल")
        navigationController?.navigationBar.prefersLargeTitles = true
        
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
    }
    
    private func setupUI() {
        view.backgroundColor = ThemeManager.shared.backgroundColor
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 24
        contentView.addSubview(stackView)
        helpCardLabels.removeAll()
        
        // Welcome Section
        let welcomeCard = createHelpCard(
            title: LocalizedText(english: "Welcome to Nani", hindi: "नानी में आपका स्वागत है"),
            description: LocalizedText(english: "Your AI-powered medication assistant designed to help you manage your medications easily through voice commands.", hindi: "आपका एआई संचालित दवाई सहायक जो आपको आवाज़ द्वारा आसानी से दवाइयों का प्रबंधन करने में मदद करता है।"),
            icon: "heart.fill"
        )
        stackView.addArrangedSubview(welcomeCard)
        
        // Voice Commands Section
        let voiceCard = createHelpCard(
            title: LocalizedText(english: "Using Voice Commands", hindi: "वॉइस कमांड का उपयोग"),
            description: LocalizedText(english: "Tap the microphone button to ask questions about your medications. You can ask in your native language, and the AI will respond in the same language.", hindi: "अपनी दवाइयों के बारे में प्रश्न पूछने के लिए माइक्रोफ़ोन बटन पर टैप करें। आप अपनी मातृभाषा में पूछ सकते हैं और एआई उसी भाषा में जवाब देगा।"),
            icon: "mic.fill"
        )
        stackView.addArrangedSubview(voiceCard)
        
        // Medications Section
        let medsCard = createHelpCard(
            title: LocalizedText(english: "Managing Medications", hindi: "दवाइयों का प्रबंधन"),
            description: LocalizedText(english: "View all your medications, schedules, and dosages. Mark medications as taken or set reminders.", hindi: "अपनी सभी दवाइयों, समय-सारणी और खुराक को देखें। दवाइयों को लिया हुआ चिह्नित करें या रिमाइंडर सेट करें।"),
            icon: "pills.fill"
        )
        stackView.addArrangedSubview(medsCard)
        
        // Care Circle Section
        let careCard = createHelpCard(
            title: LocalizedText(english: "Care Circle", hindi: "केयर सर्कल"),
            description: LocalizedText(english: "Stay connected with family members and healthcare providers. They can see your medication schedule and chat with you.", hindi: "परिवार के सदस्यों और स्वास्थ्य सेवा प्रदाताओं से जुड़े रहें। वे आपकी दवाई का समय-सारणी देख सकते हैं और आपसे बात कर सकते हैं।"),
            icon: "person.2.fill"
        )
        stackView.addArrangedSubview(careCard)
        
        // Tutorial Button
        tutorialButton.translatesAutoresizingMaskIntoConstraints = false
        tutorialButton.backgroundColor = ThemeManager.shared.lightBlue
        tutorialButton.layer.cornerRadius = 16
        tutorialButton.setTitle(LocalizationManager.shared.localized(english: "Start Interactive Tutorial", hindi: "इंटरैक्टिव ट्यूटोरियल शुरू करें"), for: .normal)
        tutorialButton.setTitleColor(ThemeManager.shared.primaryBlue, for: .normal)
        tutorialButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        tutorialButton.addTarget(self, action: #selector(tutorialTapped), for: .touchUpInside)
        stackView.addArrangedSubview(tutorialButton)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40),
            
            tutorialButton.heightAnchor.constraint(equalToConstant: 56)
        ])
    }
    
    private func createHelpCard(title: LocalizedText, description: LocalizedText, icon: String) -> UIView {
        let card = UIView()
        card.translatesAutoresizingMaskIntoConstraints = false
        card.backgroundColor = ThemeManager.shared.secondaryBackgroundColor
        card.layer.cornerRadius = 16
        
        let iconView = UIImageView(image: UIImage(systemName: icon))
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.tintColor = ThemeManager.shared.primaryBlue
        card.addSubview(iconView)
        
        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = LocalizationManager.shared.localized(title)
        titleLabel.font = UIFont.boldSystemFont(ofSize: 20)
        titleLabel.textColor = ThemeManager.shared.textColor
        card.addSubview(titleLabel)
        
        let descriptionLabel = UILabel()
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.text = LocalizationManager.shared.localized(description)
        descriptionLabel.font = UIFont.systemFont(ofSize: 16)
        descriptionLabel.textColor = ThemeManager.shared.secondaryTextColor
        descriptionLabel.numberOfLines = 0
        card.addSubview(descriptionLabel)
        
        helpCardLabels.append((titleLabel, descriptionLabel, title, description))
        
        NSLayoutConstraint.activate([
            iconView.topAnchor.constraint(equalTo: card.topAnchor, constant: 20),
            iconView.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 20),
            iconView.widthAnchor.constraint(equalToConstant: 32),
            iconView.heightAnchor.constraint(equalToConstant: 32),
            
            titleLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -20),
            
            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            descriptionLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 20),
            descriptionLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -20),
            descriptionLabel.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -20)
        ])
        
        return card
    }
    
    private func setupTheme() {
        view.backgroundColor = ThemeManager.shared.backgroundColor
        tutorialButton.setTitleColor(ThemeManager.shared.primaryBlue, for: .normal)
        helpCardLabels.forEach { labels in
            labels.titleLabel.textColor = ThemeManager.shared.textColor
            labels.descriptionLabel.textColor = ThemeManager.shared.secondaryTextColor
        }
    }
    
    @objc private func themeDidChange() {
        setupTheme()
        view.setNeedsLayout()
    }
    
    private func updateLocalizedStrings() {
        title = LocalizationManager.shared.localized(english: "Help & Tutorial", hindi: "सहायता और ट्यूटोरियल")
        helpCardLabels.forEach { labels in
            labels.titleLabel.text = LocalizationManager.shared.localized(labels.titleText)
            labels.descriptionLabel.text = LocalizationManager.shared.localized(labels.descriptionText)
        }
        tutorialButton.setTitle(
            LocalizationManager.shared.localized(english: "Start Interactive Tutorial", hindi: "इंटरैक्टिव ट्यूटोरियल शुरू करें"),
            for: .normal
        )
    }
    
    @objc private func languageDidChange() {
        updateLocalizedStrings()
    }
    
    @objc private func tutorialTapped() {
        let manager = LocalizationManager.shared
        let alert = UIAlertController(
            title: manager.localized(english: "Interactive Tutorial", hindi: "इंटरैक्टिव ट्यूटोरियल"),
            message: manager.localized(english: "Would you like to start a guided tour of the app?", hindi: "क्या आप ऐप का मार्गदर्शित दौरा शुरू करना चाहेंगे?"),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: manager.localized(english: "Start Tutorial", hindi: "ट्यूटोरियल शुरू करें"), style: .default) { _ in
            // TODO: Implement tutorial
            print("Tutorial started")
        })
        alert.addAction(UIAlertAction(title: manager.localized(english: "Cancel", hindi: "रद्द करें"), style: .cancel))
        present(alert, animated: true)
    }
}

