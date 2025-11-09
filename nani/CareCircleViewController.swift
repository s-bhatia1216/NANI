//
//  CareCircleViewController.swift
//  nani
//
//  Created by Yash Thakkar on 11/8/25.
//

import UIKit

class CareCircleViewController: UIViewController {
    
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    
    private var members: [CareMember] = [
        CareMember(name: "Yash Thakkar", role: "Family Member", relationship: "Son", isOnline: true),
        CareMember(name: "Sonal Bhatia", role: "Family Member", relationship: "Daughter", isOnline: true),
        CareMember(name: "Dr. Smith", role: "Primary Care Physician", relationship: "Doctor", isOnline: false)
    ]
    
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
    }
    
    private func setupUI() {
        view.backgroundColor = ThemeManager.shared.backgroundColor
        title = "Care Circle"
        navigationController?.navigationBar.prefersLargeTitles = true
        
        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addMemberTapped))
        navigationItem.rightBarButtonItem = addButton
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(CareMemberTableViewCell.self, forCellReuseIdentifier: "MemberCell")
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupTheme() {
        view.backgroundColor = ThemeManager.shared.backgroundColor
        tableView.backgroundColor = ThemeManager.shared.backgroundColor
        tableView.reloadData()
    }
    
    @objc private func themeDidChange() {
        setupTheme()
    }
    
    @objc private func addMemberTapped() {
        let alert = UIAlertController(title: "Add to Care Circle", message: "Invite a family member or healthcare provider", preferredStyle: .alert)
        alert.addTextField { textField in
            textField.placeholder = "Email or phone number"
        }
        alert.addAction(UIAlertAction(title: "Send Invite", style: .default) { _ in
            // TODO: Send invite
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
}

extension CareCircleViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return members.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MemberCell", for: indexPath) as! CareMemberTableViewCell
        cell.configure(with: members[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let member = members[indexPath.row]
        let chatVC = ChatViewController(member: member)
        navigationController?.pushViewController(chatVC, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
}

class CareMemberTableViewCell: UITableViewCell {
    private let containerView = UIView()
    private let profileImageView = UIImageView()
    private let nameLabel = UILabel()
    private let roleLabel = UILabel()
    private let statusIndicator = UIView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none
        
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = ThemeManager.shared.secondaryBackgroundColor
        containerView.layer.cornerRadius = 12
        contentView.addSubview(containerView)
        
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.clipsToBounds = true
        profileImageView.layer.cornerRadius = 25
        profileImageView.backgroundColor = ThemeManager.shared.lightBlue
        containerView.addSubview(profileImageView)
        
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.font = UIFont.boldSystemFont(ofSize: 16)
        nameLabel.textColor = ThemeManager.shared.textColor
        containerView.addSubview(nameLabel)
        
        roleLabel.translatesAutoresizingMaskIntoConstraints = false
        roleLabel.font = UIFont.systemFont(ofSize: 14)
        roleLabel.textColor = ThemeManager.shared.secondaryTextColor
        containerView.addSubview(roleLabel)
        
        statusIndicator.translatesAutoresizingMaskIntoConstraints = false
        statusIndicator.layer.cornerRadius = 6
        containerView.addSubview(statusIndicator)
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
            
            profileImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            profileImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            profileImageView.widthAnchor.constraint(equalToConstant: 50),
            profileImageView.heightAnchor.constraint(equalToConstant: 50),
            
            nameLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            nameLabel.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 12),
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: statusIndicator.leadingAnchor, constant: -8),
            
            roleLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            roleLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            roleLabel.trailingAnchor.constraint(lessThanOrEqualTo: statusIndicator.leadingAnchor, constant: -8),
            roleLabel.bottomAnchor.constraint(lessThanOrEqualTo: containerView.bottomAnchor, constant: -16),
            
            statusIndicator.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            statusIndicator.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            statusIndicator.widthAnchor.constraint(equalToConstant: 12),
            statusIndicator.heightAnchor.constraint(equalToConstant: 12)
        ])
    }
    
    func configure(with member: CareMember) {
        nameLabel.text = member.name
        roleLabel.text = "\(member.role) • \(member.relationship)"
        statusIndicator.backgroundColor = member.isOnline ? .systemGreen : .systemGray
        
        // Load appropriate image based on member name
        if member.name.contains("Yash") {
            profileImageView.image = UIImage(named: "yash")
            profileImageView.tintColor = nil
            profileImageView.backgroundColor = .clear
        } else if member.name.contains("Sonal") {
            profileImageView.image = UIImage(named: "sonal")
            profileImageView.tintColor = nil
            profileImageView.backgroundColor = .clear
        } else if member.name.contains("Smith") {
            profileImageView.image = UIImage(named: "smith")
            profileImageView.tintColor = nil
            profileImageView.backgroundColor = .clear
        } else {
            profileImageView.image = UIImage(systemName: "person.crop.circle.fill")
            profileImageView.tintColor = ThemeManager.shared.primaryBlue
            profileImageView.backgroundColor = ThemeManager.shared.lightBlue
        }
        
        containerView.backgroundColor = ThemeManager.shared.secondaryBackgroundColor
        nameLabel.textColor = ThemeManager.shared.textColor
        roleLabel.textColor = ThemeManager.shared.secondaryTextColor
    }
}

