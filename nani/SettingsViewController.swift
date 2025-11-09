//
//  SettingsViewController.swift
//  nani
//
//  Created by Yash Thakkar on 11/8/25.
//

import UIKit

class SettingsViewController: UIViewController {
    
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    
    private struct SettingSection {
        let title: String
        let items: [SettingItem]
    }
    
    private struct SettingItem {
        let title: String
        let icon: String
        let action: () -> Void
    }
    
    private var sections: [SettingSection] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupSections()
        setupTheme()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(themeDidChange),
            name: .themeDidChange,
            object: nil
        )
    }
    
    private func setupUI() {
        view.backgroundColor = ThemeManager.shared.backgroundColor
        title = "Settings"
        navigationController?.navigationBar.prefersLargeTitles = true
        
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
            SettingSection(title: "Appearance", items: [
                SettingItem(title: "Dark Mode", icon: "moon.fill") { [weak self] in
                    self?.showThemeOptions()
                }
            ]),
            SettingSection(title: "Language", items: [
                SettingItem(title: "Language Settings", icon: "globe") { [weak self] in
                    self?.showLanguageOptions()
                }
            ]),
            SettingSection(title: "Account", items: [
                SettingItem(title: "Profile", icon: "person.fill") { [weak self] in
                    self?.showProfile()
                },
                SettingItem(title: "Care Circle", icon: "person.2.fill") { [weak self] in
                    self?.showCareCircle()
                }
            ]),
            SettingSection(title: "Support", items: [
                SettingItem(title: "Help & Tutorial", icon: "questionmark.circle.fill") { [weak self] in
                    self?.showHelp()
                },
                SettingItem(title: "Contact Support", icon: "envelope.fill") { [weak self] in
                    self?.showContactSupport()
                }
            ])
        ]
    }
    
    private func setupTheme() {
        view.backgroundColor = ThemeManager.shared.backgroundColor
        tableView.backgroundColor = ThemeManager.shared.backgroundColor
        tableView.reloadData()
    }
    
    @objc private func themeDidChange() {
        setupTheme()
    }
    
    private func showThemeOptions() {
        let alert = UIAlertController(title: "Appearance", message: "Choose your preferred theme", preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Light", style: .default) { _ in
            ThemeManager.shared.setTheme(.light)
        })
        
        alert.addAction(UIAlertAction(title: "Dark", style: .default) { _ in
            ThemeManager.shared.setTheme(.dark)
        })
        
        alert.addAction(UIAlertAction(title: "System", style: .default) { _ in
            ThemeManager.shared.setTheme(.system)
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        if let popover = alert.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        present(alert, animated: true)
    }
    
    private func showLanguageOptions() {
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
            popover.sourceView = view
            popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        present(alert, animated: true)
    }
    
    private func showProfile() {
        let profileVC = ProfileViewController()
        navigationController?.pushViewController(profileVC, animated: true)
    }
    
    private func showCareCircle() {
        let careCircleVC = CareCircleViewController()
        navigationController?.pushViewController(careCircleVC, animated: true)
    }
    
    private func showHelp() {
        let helpVC = HelpViewController()
        navigationController?.pushViewController(helpVC, animated: true)
    }
    
    private func showContactSupport() {
        let alert = UIAlertController(title: "Contact Support", message: "How would you like to contact us?", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Voice Call", style: .default) { _ in
            // TODO: Initiate voice call
        })
        alert.addAction(UIAlertAction(title: "Email", style: .default) { _ in
            // TODO: Open email
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        if let popover = alert.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        present(alert, animated: true)
    }
}

extension SettingsViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].items.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section].title
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let item = sections[indexPath.section].items[indexPath.row]
        
        cell.textLabel?.text = item.title
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

