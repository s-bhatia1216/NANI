//
//  MedicationDetailViewController.swift
//  nani
//
//  Created by Yash Thakkar on 11/8/25.
//

import UIKit

class MedicationDetailViewController: UIViewController {
    
    private let medication: Medication
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let nameLabel = UILabel()
    private let askAIButton = UIButton(type: .custom)
    private var infoCardLabels: [(titleLabel: UILabel, valueLabel: UILabel, titleText: LocalizedText, valueText: LocalizedText)] = []
    
    init(medication: Medication) {
        self.medication = medication
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
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
    }
    
    private func setupUI() {
        view.backgroundColor = ThemeManager.shared.backgroundColor
        title = medication.localizedName
        infoCardLabels.removeAll()
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        // Color indicator
        let colorView = UIView()
        colorView.translatesAutoresizingMaskIntoConstraints = false
        colorView.backgroundColor = medication.color
        colorView.layer.cornerRadius = 8
        contentView.addSubview(colorView)
        
        // Name
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.text = medication.localizedName
        nameLabel.font = UIFont.boldSystemFont(ofSize: 32)
        nameLabel.textColor = ThemeManager.shared.textColor
        contentView.addSubview(nameLabel)
        
        // Dosage
        let dosageCard = createInfoCard(
            title: LocalizedText(english: "Dosage", hindi: "खुराक"),
            value: medication.dosage,
            icon: "pills.fill"
        )
        contentView.addSubview(dosageCard)
        
        // Schedule
        let scheduleCard = createInfoCard(
            title: LocalizedText(english: "Schedule", hindi: "समय-सारणी"),
            value: medication.time,
            icon: "clock.fill"
        )
        contentView.addSubview(scheduleCard)
        
        // Frequency
        let frequencyCard = createInfoCard(
            title: LocalizedText(english: "Frequency", hindi: "आवृत्ति"),
            value: medication.frequency,
            icon: "arrow.clockwise"
        )
        contentView.addSubview(frequencyCard)
        
        // Ask AI button
        askAIButton.translatesAutoresizingMaskIntoConstraints = false
        askAIButton.backgroundColor = ThemeManager.shared.lightBlue
        askAIButton.layer.cornerRadius = 16
        askAIButton.setTitle(LocalizationManager.shared.localized(english: "Ask AI about this medication", hindi: "इस दवाई के बारे में एआई से पूछें"), for: .normal)
        askAIButton.setTitleColor(ThemeManager.shared.primaryBlue, for: .normal)
        askAIButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        askAIButton.setImage(UIImage(systemName: "mic.fill"), for: .normal)
        askAIButton.tintColor = ThemeManager.shared.primaryBlue
        askAIButton.addTarget(self, action: #selector(askAITapped), for: .touchUpInside)
        contentView.addSubview(askAIButton)
        
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
            
            colorView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            colorView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            colorView.widthAnchor.constraint(equalToConstant: 16),
            colorView.heightAnchor.constraint(equalToConstant: 60),
            
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            nameLabel.leadingAnchor.constraint(equalTo: colorView.trailingAnchor, constant: 16),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            dosageCard.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 24),
            dosageCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            dosageCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            scheduleCard.topAnchor.constraint(equalTo: dosageCard.bottomAnchor, constant: 16),
            scheduleCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            scheduleCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            frequencyCard.topAnchor.constraint(equalTo: scheduleCard.bottomAnchor, constant: 16),
            frequencyCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            frequencyCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            askAIButton.topAnchor.constraint(equalTo: frequencyCard.bottomAnchor, constant: 32),
            askAIButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            askAIButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            askAIButton.heightAnchor.constraint(equalToConstant: 56),
            askAIButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40)
        ])
    }
    
    private func createInfoCard(title: LocalizedText, value: LocalizedText, icon: String) -> UIView {
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
        titleLabel.font = UIFont.systemFont(ofSize: 14)
        titleLabel.textColor = ThemeManager.shared.secondaryTextColor
        card.addSubview(titleLabel)
        
        let valueLabel = UILabel()
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        valueLabel.text = LocalizationManager.shared.localized(value)
        valueLabel.font = UIFont.boldSystemFont(ofSize: 18)
        valueLabel.textColor = ThemeManager.shared.textColor
        card.addSubview(valueLabel)
        
        infoCardLabels.append((titleLabel, valueLabel, title, value))
        
        NSLayoutConstraint.activate([
            card.heightAnchor.constraint(equalToConstant: 80),
            
            iconView.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 20),
            iconView.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 24),
            iconView.heightAnchor.constraint(equalToConstant: 24),
            
            titleLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -20),
            
            valueLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            valueLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            valueLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -20),
            valueLabel.bottomAnchor.constraint(lessThanOrEqualTo: card.bottomAnchor, constant: -16)
        ])
        
        return card
    }
    
    private func setupTheme() {
        view.backgroundColor = ThemeManager.shared.backgroundColor
        nameLabel.textColor = ThemeManager.shared.textColor
        askAIButton.backgroundColor = ThemeManager.shared.lightBlue
        askAIButton.setTitleColor(ThemeManager.shared.primaryBlue, for: .normal)
        askAIButton.tintColor = ThemeManager.shared.primaryBlue
        infoCardLabels.forEach { labels in
            labels.titleLabel.textColor = ThemeManager.shared.secondaryTextColor
            labels.valueLabel.textColor = ThemeManager.shared.textColor
        }
    }
    
    @objc private func themeDidChange() {
        setupTheme()
        view.setNeedsLayout()
    }
    
    private func updateLocalizedStrings() {
        title = medication.localizedName
        nameLabel.text = medication.localizedName
        infoCardLabels.forEach { labels in
            labels.titleLabel.text = LocalizationManager.shared.localized(labels.titleText)
            labels.valueLabel.text = LocalizationManager.shared.localized(labels.valueText)
        }
        askAIButton.setTitle(
            LocalizationManager.shared.localized(english: "Ask AI about this medication", hindi: "इस दवाई के बारे में एआई से पूछें"),
            for: .normal
        )
    }
    
    @objc private func languageDidChange() {
        updateLocalizedStrings()
    }
    
    @objc private func askAITapped() {
        let voiceVC = VoiceInteractionViewController()
        voiceVC.setMedicationContext(medication.name)
        let navController = UINavigationController(rootViewController: voiceVC)
        present(navController, animated: true)
    }
}

