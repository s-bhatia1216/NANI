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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTheme()
        
        title = "Help & Tutorial"
        navigationController?.navigationBar.prefersLargeTitles = true
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(themeDidChange),
            name: .themeDidChange,
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
        
        // Welcome Section
        let welcomeCard = createHelpCard(
            title: "Welcome to Nani",
            description: "Your AI-powered medication assistant designed to help you manage your medications easily through voice commands.",
            icon: "heart.fill"
        )
        stackView.addArrangedSubview(welcomeCard)
        
        // Voice Commands Section
        let voiceCard = createHelpCard(
            title: "Using Voice Commands",
            description: "Tap the microphone button to ask questions about your medications. You can ask in your native language, and the AI will respond in the same language.",
            icon: "mic.fill"
        )
        stackView.addArrangedSubview(voiceCard)
        
        // Medications Section
        let medsCard = createHelpCard(
            title: "Managing Medications",
            description: "View all your medications, schedules, and dosages. Mark medications as taken or set reminders.",
            icon: "pills.fill"
        )
        stackView.addArrangedSubview(medsCard)
        
        // Care Circle Section
        let careCard = createHelpCard(
            title: "Care Circle",
            description: "Stay connected with family members and healthcare providers. They can see your medication schedule and chat with you.",
            icon: "person.2.fill"
        )
        stackView.addArrangedSubview(careCard)
        
        // Tutorial Button
        let tutorialButton = UIButton(type: .custom)
        tutorialButton.translatesAutoresizingMaskIntoConstraints = false
        tutorialButton.backgroundColor = ThemeManager.shared.lightBlue
        tutorialButton.layer.cornerRadius = 16
        tutorialButton.setTitle("Start Interactive Tutorial", for: .normal)
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
    
    private func createHelpCard(title: String, description: String, icon: String) -> UIView {
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
        titleLabel.text = title
        titleLabel.font = UIFont.boldSystemFont(ofSize: 20)
        titleLabel.textColor = ThemeManager.shared.textColor
        card.addSubview(titleLabel)
        
        let descriptionLabel = UILabel()
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.text = description
        descriptionLabel.font = UIFont.systemFont(ofSize: 16)
        descriptionLabel.textColor = ThemeManager.shared.secondaryTextColor
        descriptionLabel.numberOfLines = 0
        card.addSubview(descriptionLabel)
        
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
    }
    
    @objc private func themeDidChange() {
        setupTheme()
        view.setNeedsLayout()
    }
    
    @objc private func tutorialTapped() {
        let alert = UIAlertController(title: "Interactive Tutorial", message: "Would you like to start a guided tour of the app?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Start Tutorial", style: .default) { _ in
            // TODO: Implement tutorial
            print("Tutorial started")
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
}

