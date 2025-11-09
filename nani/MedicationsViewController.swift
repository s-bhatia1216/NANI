//
//  MedicationsViewController.swift
//  nani
//
//  Created by Yash Thakkar on 11/8/25.
//

import UIKit

class MedicationsViewController: UIViewController {
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let tableView = UITableView()
    
    // Sample medications data
    private var medications: [Medication] = [
        Medication(name: "Lisinopril", dosage: "10mg", frequency: "Once daily", time: "8:00 AM", color: .systemBlue),
        Medication(name: "Metformin", dosage: "500mg", frequency: "Twice daily", time: "8:00 AM, 8:00 PM", color: .systemGreen),
        Medication(name: "Aspirin", dosage: "81mg", frequency: "Once daily", time: "9:00 AM", color: .systemRed),
        Medication(name: "Vitamin D", dosage: "1000 IU", frequency: "Once daily", time: "10:00 AM", color: .systemOrange)
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
        
        // Title
        title = "My Medications"
        navigationController?.navigationBar.prefersLargeTitles = true
        
        // Table View
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(MedicationTableViewCell.self, forCellReuseIdentifier: "MedicationCell")
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        view.addSubview(tableView)
        
        // Add medication button
        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addMedicationTapped))
        navigationItem.rightBarButtonItem = addButton
        
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
    
    @objc private func addMedicationTapped() {
        let alert = UIAlertController(title: "Add Medication", message: "Use voice command or add manually", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Voice Command", style: .default) { _ in
            // TODO: Open voice interface
        })
        alert.addAction(UIAlertAction(title: "Add Manually", style: .default) { _ in
            // TODO: Open add medication form
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
}

extension MedicationsViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return medications.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MedicationCell", for: indexPath) as! MedicationTableViewCell
        cell.configure(with: medications[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let medication = medications[indexPath.row]
        let detailVC = MedicationDetailViewController(medication: medication)
        navigationController?.pushViewController(detailVC, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
}

// MARK: - Medication Model
struct Medication {
    let name: String
    let dosage: String
    let frequency: String
    let time: String
    let color: UIColor
}

// MARK: - Medication Cell
class MedicationTableViewCell: UITableViewCell {
    private let containerView = UIView()
    private let colorIndicator = UIView()
    private let nameLabel = UILabel()
    private let dosageLabel = UILabel()
    private let timeLabel = UILabel()
    private let frequencyLabel = UILabel()
    
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
        containerView.layer.cornerRadius = 16
        contentView.addSubview(containerView)
        
        colorIndicator.translatesAutoresizingMaskIntoConstraints = false
        colorIndicator.layer.cornerRadius = 4
        containerView.addSubview(colorIndicator)
        
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.font = UIFont.boldSystemFont(ofSize: 18)
        nameLabel.textColor = ThemeManager.shared.textColor
        containerView.addSubview(nameLabel)
        
        dosageLabel.translatesAutoresizingMaskIntoConstraints = false
        dosageLabel.font = UIFont.systemFont(ofSize: 14)
        dosageLabel.textColor = ThemeManager.shared.secondaryTextColor
        containerView.addSubview(dosageLabel)
        
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        timeLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        timeLabel.textColor = ThemeManager.shared.textColor
        containerView.addSubview(timeLabel)
        
        frequencyLabel.translatesAutoresizingMaskIntoConstraints = false
        frequencyLabel.font = UIFont.systemFont(ofSize: 12)
        frequencyLabel.textColor = ThemeManager.shared.secondaryTextColor
        containerView.addSubview(frequencyLabel)
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            
            colorIndicator.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            colorIndicator.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            colorIndicator.widthAnchor.constraint(equalToConstant: 8),
            colorIndicator.heightAnchor.constraint(equalToConstant: 60),
            
            nameLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            nameLabel.leadingAnchor.constraint(equalTo: colorIndicator.trailingAnchor, constant: 16),
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: containerView.trailingAnchor, constant: -16),
            
            dosageLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            dosageLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            
            timeLabel.topAnchor.constraint(equalTo: dosageLabel.bottomAnchor, constant: 8),
            timeLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            
            frequencyLabel.topAnchor.constraint(equalTo: timeLabel.bottomAnchor, constant: 4),
            frequencyLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            frequencyLabel.bottomAnchor.constraint(lessThanOrEqualTo: containerView.bottomAnchor, constant: -16)
        ])
    }
    
    func configure(with medication: Medication) {
        colorIndicator.backgroundColor = medication.color
        nameLabel.text = medication.name
        dosageLabel.text = medication.dosage
        timeLabel.text = "⏰ \(medication.time)"
        frequencyLabel.text = medication.frequency
        
        containerView.backgroundColor = ThemeManager.shared.secondaryBackgroundColor
        nameLabel.textColor = ThemeManager.shared.textColor
        dosageLabel.textColor = ThemeManager.shared.secondaryTextColor
        timeLabel.textColor = ThemeManager.shared.textColor
        frequencyLabel.textColor = ThemeManager.shared.secondaryTextColor
    }
}

