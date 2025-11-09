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
        Medication(
            name: LocalizedText.same("Lisinopril"),
            dosage: LocalizedText.same("10mg"),
            frequency: LocalizedText(english: "Once daily", hindi: "दिन में एक बार"),
            time: LocalizedText(english: "8:00 AM", hindi: "सुबह 8:00 बजे"),
            color: .systemBlue
        ),
        Medication(
            name: LocalizedText.same("Metformin"),
            dosage: LocalizedText.same("500mg"),
            frequency: LocalizedText(english: "Twice daily", hindi: "दिन में दो बार"),
            time: LocalizedText(english: "8:00 AM, 8:00 PM", hindi: "सुबह 8:00 बजे, रात 8:00 बजे"),
            color: .systemGreen
        ),
        Medication(
            name: LocalizedText.same("Aspirin"),
            dosage: LocalizedText.same("81mg"),
            frequency: LocalizedText(english: "Once daily", hindi: "दिन में एक बार"),
            time: LocalizedText(english: "9:00 AM", hindi: "सुबह 9:00 बजे"),
            color: .systemRed
        ),
        Medication(
            name: LocalizedText.same("Vitamin D"),
            dosage: LocalizedText.same("1000 IU"),
            frequency: LocalizedText(english: "Once daily", hindi: "दिन में एक बार"),
            time: LocalizedText(english: "10:00 AM", hindi: "सुबह 10:00 बजे"),
            color: .systemOrange
        )
    ]
    
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
        
        // Title
        title = LocalizationManager.shared.localized(english: "My Medications", hindi: "मेरी दवाइयाँ")
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
        addButton.accessibilityLabel = LocalizationManager.shared.localized(english: "Add medication", hindi: "दवाई जोड़ें")
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
    
    private func updateLocalizedStrings() {
        title = LocalizationManager.shared.localized(english: "My Medications", hindi: "मेरी दवाइयाँ")
        navigationItem.rightBarButtonItem?.accessibilityLabel = LocalizationManager.shared.localized(english: "Add medication", hindi: "दवाई जोड़ें")
        tableView.reloadData()
    }
    
    @objc private func themeDidChange() {
        setupTheme()
    }
    
    @objc private func languageDidChange() {
        updateLocalizedStrings()
    }
    
    @objc private func addMedicationTapped() {
        let manager = LocalizationManager.shared
        let alert = UIAlertController(
            title: manager.localized(english: "Add Medication", hindi: "दवाई जोड़ें"),
            message: manager.localized(english: "Enter the medication details below.", hindi: "नीचे दवाई का विवरण दर्ज करें।"),
            preferredStyle: .alert
        )
        
        alert.addTextField { textField in
            textField.placeholder = manager.localized(english: "Medication name", hindi: "दवाई का नाम")
        }
        
        alert.addTextField { textField in
            textField.placeholder = manager.localized(english: "Dosage (e.g., 10mg)", hindi: "खुराक (उदा., 10mg)")
        }
        
        alert.addTextField { textField in
            textField.placeholder = manager.localized(english: "Frequency (e.g., Once daily)", hindi: "आवृत्ति (उदा., दिन में एक बार)")
        }
        
        alert.addTextField { textField in
            textField.placeholder = manager.localized(english: "Time (e.g., 8:00 AM)", hindi: "समय (उदा., सुबह 8:00 बजे)")
        }
        
        let addAction = UIAlertAction(title: manager.localized(english: "Add", hindi: "जोड़ें"), style: .default) { [weak self] _ in
            guard let self else { return }
            let name = alert.textFields?[0].text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let dosage = alert.textFields?[1].text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let frequency = alert.textFields?[2].text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let time = alert.textFields?[3].text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            
            guard !name.isEmpty else {
                self.presentValidationError()
                return
            }
            
            let defaultFrequency = LocalizedText(english: "As needed", hindi: "आवश्यकतानुसार")
            let defaultTime = LocalizedText(english: "Any time", hindi: "किसी भी समय")
            
            let newMedication = Medication(
                name: LocalizedText.same(name),
                dosage: dosage.isEmpty ? LocalizedText.same("—") : LocalizedText.same(dosage),
                frequency: frequency.isEmpty ? defaultFrequency : LocalizedText.same(frequency),
                time: time.isEmpty ? defaultTime : LocalizedText.same(time),
                color: UIColor.systemTeal
            )
            
            self.medications.insert(newMedication, at: 0)
            self.tableView.reloadData()
        }
        
        let cancelAction = UIAlertAction(title: manager.localized(english: "Cancel", hindi: "रद्द करें"), style: .cancel)
        
        alert.addAction(addAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true)
    }
    
    private func presentValidationError() {
        let manager = LocalizationManager.shared
        let alert = UIAlertController(
            title: manager.localized(english: "Missing Name", hindi: "नाम आवश्यक"),
            message: manager.localized(english: "Please enter at least the medication name.", hindi: "कृपया कम से कम दवाई का नाम दर्ज करें।"),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: manager.localized(english: "OK", hindi: "ठीक है"), style: .default))
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
    let name: LocalizedText
    let dosage: LocalizedText
    let frequency: LocalizedText
    let time: LocalizedText
    let color: UIColor
    
    var localizedName: String { LocalizationManager.shared.localized(name) }
    var localizedDosage: String { LocalizationManager.shared.localized(dosage) }
    var localizedFrequency: String { LocalizationManager.shared.localized(frequency) }
    var localizedTime: String { LocalizationManager.shared.localized(time) }
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
        nameLabel.text = medication.localizedName
        dosageLabel.text = medication.localizedDosage
        let timeString = medication.localizedTime
        timeLabel.text = "⏰ \(timeString)"
        frequencyLabel.text = medication.localizedFrequency
        
        containerView.backgroundColor = ThemeManager.shared.secondaryBackgroundColor
        nameLabel.textColor = ThemeManager.shared.textColor
        dosageLabel.textColor = ThemeManager.shared.secondaryTextColor
        timeLabel.textColor = ThemeManager.shared.textColor
        frequencyLabel.textColor = ThemeManager.shared.secondaryTextColor
    }
}

