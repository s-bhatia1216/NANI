//
//  SideMenuViewController.swift
//  nani
//
//  Created by Yash Thakkar on 11/8/25.
//

import UIKit

class SideMenuViewController: UIViewController {
    
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    
    private struct MenuSection {
        let title: String
        let items: [MenuItem]
    }
    
    private struct MenuItem {
        let title: String
        let icon: String
        let action: () -> Void
    }
    
    private var sections: [MenuSection] = []
    weak var delegate: SideMenuDelegate?
    
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
        
        let nameLabel = UILabel()
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.text = "Maya Sharma"
        nameLabel.font = UIFont.boldSystemFont(ofSize: 20)
        nameLabel.textColor = ThemeManager.shared.textColor
        headerView.addSubview(nameLabel)
        
        NSLayoutConstraint.activate([
            profileImageView.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 20),
            profileImageView.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 20),
            profileImageView.widthAnchor.constraint(equalToConstant: 80),
            profileImageView.heightAnchor.constraint(equalToConstant: 80),
            
            nameLabel.centerYAnchor.constraint(equalTo: profileImageView.centerYAnchor),
            nameLabel.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 16)
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
            MenuSection(title: "Appearance", items: [
                MenuItem(title: "Dark Mode", icon: "moon.fill") { [weak self] in
                    self?.showThemeOptions()
                }
            ]),
            MenuSection(title: "Language", items: [
                MenuItem(title: "Language Settings", icon: "globe") { [weak self] in
                    self?.showLanguageOptions()
                }
            ]),
            MenuSection(title: "Account", items: [
                MenuItem(title: "Profile", icon: "person.fill") { [weak self] in
                    self?.showProfile()
                },
                MenuItem(title: "Care Circle", icon: "person.2.fill") { [weak self] in
                    self?.showCareCircle()
                }
            ]),
            MenuSection(title: "Support", items: [
                MenuItem(title: "Help & Tutorial", icon: "questionmark.circle.fill") { [weak self] in
                    self?.showHelp()
                },
                MenuItem(title: "Contact Support", icon: "envelope.fill") { [weak self] in
                    self?.showContactSupport()
                }
            ])
        ]
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
        delegate?.didSelectProfile()
    }
    
    private func showCareCircle() {
        delegate?.didSelectCareCircle()
    }
    
    private func showHelp() {
        delegate?.didSelectHelp()
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

extension SideMenuViewController: UITableViewDataSource, UITableViewDelegate {
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

protocol SideMenuDelegate: AnyObject {
    func didSelectProfile()
    func didSelectCareCircle()
    func didSelectHelp()
}

