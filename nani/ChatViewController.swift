//
//  ChatViewController.swift
//  nani
//
//  Created by Yash Thakkar on 11/8/25.
//

import UIKit

struct CareMember {
    let name: String
    let role: LocalizedText
    let relationship: LocalizedText
    let isOnline: Bool
    
    var localizedRoleDescription: String {
        let manager = LocalizationManager.shared
        return "\(manager.localized(role)) • \(manager.localized(relationship))"
    }
}

struct ChatMessage {
    let text: LocalizedText
    let isFromUser: Bool
    let timestamp: Date
    
    var localizedText: String {
        LocalizationManager.shared.localized(text)
    }
}

class ChatViewController: UIViewController {
    
    private let member: CareMember
    private let tableView = UITableView()
    private let inputContainerView = UIView()
    private let messageTextField = UITextField()
    private let sendButton = UIButton(type: .system)
    
    private var messages: [ChatMessage] = [
        ChatMessage(
            text: LocalizedText(english: "Hope you're feeling well today!", hindi: "आशा है आज आप अच्छा महसूस कर रहे हैं!"),
            isFromUser: false,
            timestamp: Date().addingTimeInterval(-3600)
        ),
        ChatMessage(
            text: LocalizedText(english: "Did you take your morning medication?", hindi: "क्या आपने सुबह की दवाई ली?"),
            isFromUser: false,
            timestamp: Date().addingTimeInterval(-1800)
        ),
        ChatMessage(
            text: LocalizedText(english: "Yes, I took it at 8:00 AM", hindi: "हाँ, मैंने इसे सुबह 8:00 बजे लिया।"),
            isFromUser: true,
            timestamp: Date().addingTimeInterval(-1700)
        )
    ]
    
    init(member: CareMember) {
        self.member = member
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
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }
    
    private func setupUI() {
        view.backgroundColor = ThemeManager.shared.backgroundColor
        title = member.name
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(ChatMessageTableViewCell.self, forCellReuseIdentifier: "MessageCell")
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.keyboardDismissMode = .interactive
        view.addSubview(tableView)
        
        inputContainerView.translatesAutoresizingMaskIntoConstraints = false
        inputContainerView.backgroundColor = ThemeManager.shared.secondaryBackgroundColor
        view.addSubview(inputContainerView)
        
        messageTextField.translatesAutoresizingMaskIntoConstraints = false
        messageTextField.placeholder = LocalizationManager.shared.localized(
            english: "Type a message or use voice...",
            hindi: "संदेश लिखें या आवाज़ का उपयोग करें..."
        )
        messageTextField.backgroundColor = ThemeManager.shared.backgroundColor
        messageTextField.layer.cornerRadius = 20
        messageTextField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        messageTextField.leftViewMode = .always
        messageTextField.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        messageTextField.rightViewMode = .always
        messageTextField.textColor = ThemeManager.shared.textColor
        inputContainerView.addSubview(messageTextField)
        
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        sendButton.setImage(UIImage(systemName: "paperplane.fill"), for: .normal)
        sendButton.tintColor = ThemeManager.shared.primaryBlue
        sendButton.addTarget(self, action: #selector(sendTapped), for: .touchUpInside)
        inputContainerView.addSubview(sendButton)
        
        let voiceButton = UIButton(type: .system)
        voiceButton.translatesAutoresizingMaskIntoConstraints = false
        voiceButton.setImage(UIImage(systemName: "mic.fill"), for: .normal)
        voiceButton.tintColor = ThemeManager.shared.primaryBlue
        voiceButton.addTarget(self, action: #selector(voiceTapped), for: .touchUpInside)
        inputContainerView.addSubview(voiceButton)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: inputContainerView.topAnchor),
            
            inputContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            inputContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            inputContainerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            inputContainerView.heightAnchor.constraint(equalToConstant: 60),
            
            voiceButton.leadingAnchor.constraint(equalTo: inputContainerView.leadingAnchor, constant: 12),
            voiceButton.centerYAnchor.constraint(equalTo: inputContainerView.centerYAnchor),
            voiceButton.widthAnchor.constraint(equalToConstant: 40),
            voiceButton.heightAnchor.constraint(equalToConstant: 40),
            
            messageTextField.leadingAnchor.constraint(equalTo: voiceButton.trailingAnchor, constant: 8),
            messageTextField.centerYAnchor.constraint(equalTo: inputContainerView.centerYAnchor),
            messageTextField.heightAnchor.constraint(equalToConstant: 40),
            
            sendButton.leadingAnchor.constraint(equalTo: messageTextField.trailingAnchor, constant: 8),
            sendButton.trailingAnchor.constraint(equalTo: inputContainerView.trailingAnchor, constant: -12),
            sendButton.centerYAnchor.constraint(equalTo: inputContainerView.centerYAnchor),
            sendButton.widthAnchor.constraint(equalToConstant: 40),
            sendButton.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    private func setupTheme() {
        view.backgroundColor = ThemeManager.shared.backgroundColor
        tableView.backgroundColor = ThemeManager.shared.backgroundColor
        inputContainerView.backgroundColor = ThemeManager.shared.secondaryBackgroundColor
        messageTextField.backgroundColor = ThemeManager.shared.backgroundColor
        messageTextField.textColor = ThemeManager.shared.textColor
        tableView.reloadData()
    }
    
    private func updateLocalizedStrings() {
        messageTextField.placeholder = LocalizationManager.shared.localized(
            english: "Type a message or use voice...",
            hindi: "संदेश लिखें या आवाज़ का उपयोग करें..."
        )
        tableView.reloadData()
    }
    
    @objc private func themeDidChange() {
        setupTheme()
    }
    
    @objc private func languageDidChange() {
        updateLocalizedStrings()
    }
    
    @objc private func keyboardWillShow(_ notification: Notification) {
        if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
            let keyboardHeight = keyboardFrame.height
            inputContainerView.transform = CGAffineTransform(translationX: 0, y: -keyboardHeight + view.safeAreaInsets.bottom)
        }
    }
    
    @objc private func keyboardWillHide() {
        inputContainerView.transform = .identity
    }
    
    @objc private func sendTapped() {
        guard let text = messageTextField.text, !text.isEmpty else { return }
        messages.append(ChatMessage(text: .same(text), isFromUser: true, timestamp: Date()))
        messageTextField.text = ""
        tableView.reloadData()
        scrollToBottom()
    }
    
    @objc private func voiceTapped() {
        let voiceVC = VoiceInteractionViewController()
        present(UINavigationController(rootViewController: voiceVC), animated: true)
    }
    
    private func scrollToBottom() {
        DispatchQueue.main.async {
            let indexPath = IndexPath(row: self.messages.count - 1, section: 0)
            self.tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
        }
    }
}

extension ChatViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MessageCell", for: indexPath) as! ChatMessageTableViewCell
        cell.configure(with: messages[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
}

class ChatMessageTableViewCell: UITableViewCell {
    private let bubbleView = UIView()
    private let messageLabel = UILabel()
    
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
        
        bubbleView.translatesAutoresizingMaskIntoConstraints = false
        bubbleView.layer.cornerRadius = 16
        contentView.addSubview(bubbleView)
        
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        messageLabel.numberOfLines = 0
        messageLabel.font = UIFont.systemFont(ofSize: 16)
        bubbleView.addSubview(messageLabel)
        
        NSLayoutConstraint.activate([
            bubbleView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            bubbleView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            bubbleView.widthAnchor.constraint(lessThanOrEqualToConstant: 250),
            
            messageLabel.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: 12),
            messageLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 12),
            messageLabel.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -12),
            messageLabel.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: -12)
        ])
    }
    
    func configure(with message: ChatMessage) {
        messageLabel.text = message.localizedText
        
        if message.isFromUser {
            bubbleView.backgroundColor = ThemeManager.shared.lightBlue
            messageLabel.textColor = ThemeManager.shared.primaryBlue
            bubbleView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16).isActive = true
            bubbleView.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor, constant: 50).isActive = true
        } else {
            bubbleView.backgroundColor = ThemeManager.shared.secondaryBackgroundColor
            messageLabel.textColor = ThemeManager.shared.textColor
            bubbleView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16).isActive = true
            bubbleView.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -50).isActive = true
        }
    }
}

