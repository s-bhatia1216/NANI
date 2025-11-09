//
//  SideMenuViewController.swift
//  nani
//
//  Created by Yash Thakkar on 11/8/25.
//

import UIKit

class SideMenuViewController: UIViewController {
    
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let headerNameLabel = UILabel()
    
    private struct MenuSection {
        let title: LocalizedText
        let items: [MenuItem]
        
        var localizedTitle: String {
            LocalizationManager.shared.localized(title)
        }
    }
    
    private struct MenuItem {
        let title: LocalizedText
        let icon: String
        let action: () -> Void
        
        var localizedTitle: String {
            LocalizationManager.shared.localized(title)
        }
    }
    
    private var sections: [MenuSection] = []
    weak var delegate: SideMenuDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupSections()
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
        title = LocalizationManager.shared.localized(english: "Settings", hindi: "सेटिंग्स")
        
        // Header with profile
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: 120))
        headerView.backgroundColor = ThemeManager.shared.secondaryBackgroundColor
        
        let profileImageView = UIImageView()
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.clipsToBounds = true
        profileImageView.layer.cornerRadius = 40
        profileImageView.backgroundColor = ThemeManager.shared.lightBlue
        if let mayaImage = UIImage(named: "maya") {
            profileImageView.image = mayaImage
        } else {
            profileImageView.image = createPlaceholderProfileImage()
        }
        headerView.addSubview(profileImageView)
        
        headerNameLabel.translatesAutoresizingMaskIntoConstraints = false
        headerNameLabel.text = LocalizationManager.shared.localized(english: "Maya Sharma", hindi: "माया शर्मा")
        headerNameLabel.font = UIFont.boldSystemFont(ofSize: 20)
        headerNameLabel.textColor = ThemeManager.shared.textColor
        headerView.addSubview(headerNameLabel)
        
        NSLayoutConstraint.activate([
            profileImageView.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 20),
            profileImageView.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 20),
            profileImageView.widthAnchor.constraint(equalToConstant: 80),
            profileImageView.heightAnchor.constraint(equalToConstant: 80),
            
            headerNameLabel.centerYAnchor.constraint(equalTo: profileImageView.centerYAnchor),
            headerNameLabel.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 16)
        ])
        
        tableView.tableHeaderView = headerView
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupSections() {
        sections = [
            MenuSection(title: LocalizedText(english: "Appearance", hindi: "रूप-रंग"), items: [
                MenuItem(title: LocalizedText(english: "Dark Mode", hindi: "डार्क मोड"), icon: "moon.fill") { [weak self] in
                    self?.showThemeOptions()
                }
            ]),
            MenuSection(title: LocalizedText(english: "Language", hindi: "भाषा"), items: [
                MenuItem(title: LocalizedText(english: "Language Settings", hindi: "भाषा सेटिंग्स"), icon: "globe") { [weak self] in
                    self?.showLanguageOptions()
                }
            ]),
            MenuSection(title: LocalizedText(english: "Account", hindi: "खाता"), items: [
                MenuItem(title: LocalizedText(english: "Profile", hindi: "प्रोफ़ाइल"), icon: "person.fill") { [weak self] in
                    self?.showProfile()
                },
                MenuItem(title: LocalizedText(english: "Care Circle", hindi: "केयर सर्कल"), icon: "person.2.fill") { [weak self] in
                    self?.showCareCircle()
                }
            ]),
            MenuSection(title: LocalizedText(english: "Support", hindi: "सहायता"), items: [
                MenuItem(title: LocalizedText(english: "Help & Tutorial", hindi: "सहायता और ट्यूटोरियल"), icon: "questionmark.circle.fill") { [weak self] in
                    self?.showHelp()
                },
                MenuItem(title: LocalizedText(english: "Contact Support", hindi: "समर्थन से संपर्क करें"), icon: "envelope.fill") { [weak self] in
                    self?.showContactSupport()
                }
            ])
        ]
        tableView.reloadData()
    }
    
    private func createPlaceholderProfileImage() -> UIImage? {
        let size = CGSize(width: 80, height: 80)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            ThemeManager.shared.lightBlue.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            ThemeManager.shared.primaryBlue.setFill()
            let circleRect = CGRect(x: 20, y: 15, width: 40, height: 40)
            context.cgContext.fillEllipse(in: circleRect)
        }
    }
    
    private func setupTheme() {
        view.backgroundColor = ThemeManager.shared.backgroundColor
        tableView.backgroundColor = ThemeManager.shared.backgroundColor
        headerNameLabel.textColor = ThemeManager.shared.textColor
        tableView.reloadData()
    }
    
    private func updateLocalizedStrings() {
        title = LocalizationManager.shared.localized(english: "Settings", hindi: "सेटिंग्स")
        headerNameLabel.text = LocalizationManager.shared.localized(english: "Maya Sharma", hindi: "माया शर्मा")
        tableView.reloadData()
    }
    
    @objc private func themeDidChange() {
        setupTheme()
    }
    
    @objc private func languageDidChange() {
        updateLocalizedStrings()
    }
    
    private func showThemeOptions() {
        let manager = LocalizationManager.shared
        let alert = UIAlertController(
            title: manager.localized(english: "Appearance", hindi: "रूप-रंग"),
            message: manager.localized(english: "Choose your preferred theme", hindi: "अपनी पसंदीदा थीम चुनें"),
            preferredStyle: .actionSheet
        )
        
        alert.addAction(UIAlertAction(title: manager.localized(english: "Light", hindi: "हल्का"), style: .default) { _ in
            ThemeManager.shared.setTheme(.light)
        })
        
        alert.addAction(UIAlertAction(title: manager.localized(english: "Dark", hindi: "गहरा"), style: .default) { _ in
            ThemeManager.shared.setTheme(.dark)
        })
        
        alert.addAction(UIAlertAction(title: manager.localized(english: "System", hindi: "सिस्टम"), style: .default) { _ in
            ThemeManager.shared.setTheme(.system)
        })
        
        alert.addAction(UIAlertAction(title: manager.localized(english: "Cancel", hindi: "रद्द करें"), style: .cancel))
        
        if let popover = alert.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        present(alert, animated: true)
    }
    
    private func showLanguageOptions() {
        let manager = LocalizationManager.shared
        let alert = UIAlertController(
            title: manager.localized(english: "Language", hindi: "भाषा"),
            message: manager.localized(english: "Select your preferred language", hindi: "अपनी पसंदीदा भाषा चुनें"),
            preferredStyle: .actionSheet
        )
        
        let options: [(LocalizedText, AppLanguage?)] = [
            (LocalizedText(english: "English", hindi: "अंग्रेज़ी"), .english),
            (LocalizedText(english: "Hindi", hindi: "हिन्दी"), .hindi),
            (LocalizedText(english: "Spanish", hindi: "स्पैनिश"), nil),
            (LocalizedText(english: "Mandarin", hindi: "मंदारिन"), nil),
            (LocalizedText(english: "French", hindi: "फ़्रेंच"), nil),
            (LocalizedText(english: "Arabic", hindi: "अरबी"), nil)
        ]
        
        options.forEach { entry in
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
        
        alert.addAction(UIAlertAction(title: manager.localized(english: "Cancel", hindi: "रद्द करें"), style: .cancel))
        
        if let popover = alert.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        present(alert, animated: true)
    }
    
    private func showProfile() {
        delegate?.didSelectProfile()
    }
    
    private func showCareCircle() {
        delegate?.didSelectCareCircle()
    }
    
    private func showHelp() {
        delegate?.didSelectHelp()
    }
    
    private func showContactSupport() {
        let manager = LocalizationManager.shared
        let alert = UIAlertController(
            title: manager.localized(english: "Contact Support", hindi: "समर्थन से संपर्क करें"),
            message: manager.localized(english: "How would you like to contact us?", hindi: "आप हमसे कैसे संपर्क करना चाहेंगे?"),
            preferredStyle: .actionSheet
        )
        alert.addAction(UIAlertAction(title: manager.localized(english: "Voice Call", hindi: "वॉइस कॉल"), style: .default) { _ in
            // TODO: Initiate voice call
        })
        alert.addAction(UIAlertAction(title: manager.localized(english: "Email", hindi: "ईमेल"), style: .default) { _ in
            // TODO: Open email
        })
        alert.addAction(UIAlertAction(title: manager.localized(english: "Cancel", hindi: "रद्द करें"), style: .cancel))
        
        if let popover = alert.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        present(alert, animated: true)
    }
}

extension SideMenuViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].items.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section].localizedTitle
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let item = sections[indexPath.section].items[indexPath.row]
        
        cell.textLabel?.text = item.localizedTitle
        cell.textLabel?.textColor = ThemeManager.shared.textColor
        cell.imageView?.image = UIImage(systemName: item.icon)
        cell.imageView?.tintColor = ThemeManager.shared.primaryBlue
        cell.backgroundColor = ThemeManager.shared.secondaryBackgroundColor
        cell.accessoryType = .disclosureIndicator
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = sections[indexPath.section].items[indexPath.row]
        item.action()
    }
}

protocol SideMenuDelegate: AnyObject {
    func didSelectProfile()
    func didSelectCareCircle()
    func didSelectHelp()
}

