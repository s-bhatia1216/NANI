//
//  ProfileViewController.swift
//  nani
//
//  Created by Yash Thakkar on 11/8/25.
//

import UIKit

class ProfileViewController: UIViewController {
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTheme()
        
        title = "Profile"
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
        
        // Profile Image
        let profileImageView = UIImageView()
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.clipsToBounds = true
        profileImageView.layer.cornerRadius = 60
        profileImageView.backgroundColor = ThemeManager.shared.lightBlue
        if let mayaImage = UIImage(named: "maya") {
            profileImageView.image = mayaImage
        } else {
            profileImageView.image = createPlaceholderProfileImage()
        }
        contentView.addSubview(profileImageView)
        
        // Name
        let nameLabel = UILabel()
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.text = "Maya Sharma"
        nameLabel.font = UIFont.boldSystemFont(ofSize: 28)
        nameLabel.textColor = ThemeManager.shared.textColor
        nameLabel.textAlignment = .center
        contentView.addSubview(nameLabel)
        
        // Edit Button
        let editButton = UIButton(type: .system)
        editButton.translatesAutoresizingMaskIntoConstraints = false
        editButton.setTitle("Edit Profile", for: .normal)
        editButton.setTitleColor(ThemeManager.shared.primaryBlue, for: .normal)
        editButton.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        editButton.addTarget(self, action: #selector(editTapped), for: .touchUpInside)
        contentView.addSubview(editButton)
        
        // Info Cards
        let ageCard = createInfoCard(title: "Age", value: "75 years", icon: "calendar")
        contentView.addSubview(ageCard)
        
        let languageCard = createInfoCard(title: "Preferred Language", value: "English", icon: "globe")
        contentView.addSubview(languageCard)
        
        let medicationsCard = createInfoCard(title: "Active Medications", value: "4", icon: "pills.fill")
        contentView.addSubview(medicationsCard)
        
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
            
            profileImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 30),
            profileImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            profileImageView.widthAnchor.constraint(equalToConstant: 120),
            profileImageView.heightAnchor.constraint(equalToConstant: 120),
            
            nameLabel.topAnchor.constraint(equalTo: profileImageView.bottomAnchor, constant: 16),
            nameLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            nameLabel.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor, constant: 20),
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -20),
            
            editButton.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 8),
            editButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            
            ageCard.topAnchor.constraint(equalTo: editButton.bottomAnchor, constant: 30),
            ageCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            ageCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            languageCard.topAnchor.constraint(equalTo: ageCard.bottomAnchor, constant: 16),
            languageCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            languageCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            medicationsCard.topAnchor.constraint(equalTo: languageCard.bottomAnchor, constant: 16),
            medicationsCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            medicationsCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            medicationsCard.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40)
        ])
    }
    
    private func createInfoCard(title: String, value: String, icon: String) -> UIView {
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
        titleLabel.font = UIFont.systemFont(ofSize: 14)
        titleLabel.textColor = ThemeManager.shared.secondaryTextColor
        card.addSubview(titleLabel)
        
        let valueLabel = UILabel()
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        valueLabel.text = value
        valueLabel.font = UIFont.boldSystemFont(ofSize: 18)
        valueLabel.textColor = ThemeManager.shared.textColor
        card.addSubview(valueLabel)
        
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
    
    private func createPlaceholderProfileImage() -> UIImage? {
        let size = CGSize(width: 120, height: 120)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            ThemeManager.shared.lightBlue.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            ThemeManager.shared.primaryBlue.setFill()
            let circleRect = CGRect(x: 30, y: 20, width: 60, height: 60)
            context.cgContext.fillEllipse(in: circleRect)
        }
    }
    
    private func setupTheme() {
        view.backgroundColor = ThemeManager.shared.backgroundColor
    }
    
    @objc private func themeDidChange() {
        setupTheme()
        view.setNeedsLayout()
    }
    
    @objc private func editTapped() {
        let alert = UIAlertController(title: "Edit Profile", message: "Use voice command to update your profile", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Use Voice", style: .default) { _ in
            let voiceVC = VoiceInteractionViewController()
            self.present(UINavigationController(rootViewController: voiceVC), animated: true)
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
}

