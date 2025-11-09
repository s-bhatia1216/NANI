//
//  ThemeManager.swift
//  nani
//
//  Created by Yash Thakkar on 11/8/25.
//

import UIKit

enum ThemeMode {
    case light
    case dark
    case system
}

class ThemeManager {
    static let shared = ThemeManager()
    
    private var currentMode: ThemeMode = .system {
        didSet {
            applyTheme()
        }
    }
    
    var isDarkMode: Bool {
        switch currentMode {
        case .light:
            return false
        case .dark:
            return true
        case .system:
            return UITraitCollection.current.userInterfaceStyle == .dark
        }
    }
    
    // Colors
    var primaryBlue: UIColor {
        isDarkMode ? UIColor(red: 0.4, green: 0.6, blue: 0.9, alpha: 1.0) : UIColor(red: 0.15, green: 0.25, blue: 0.45, alpha: 1.0)
    }
    
    var lightBlue: UIColor {
        isDarkMode ? UIColor(red: 0.25, green: 0.35, blue: 0.5, alpha: 1.0) : UIColor(red: 0.75, green: 0.88, blue: 0.96, alpha: 1.0)
    }
    
    var backgroundColor: UIColor {
        isDarkMode ? UIColor(red: 0.05, green: 0.05, blue: 0.1, alpha: 1.0) : UIColor.white
    }
    
    var secondaryBackgroundColor: UIColor {
        isDarkMode ? UIColor(red: 0.12, green: 0.12, blue: 0.18, alpha: 1.0) : UIColor(red: 0.95, green: 0.95, blue: 0.97, alpha: 1.0)
    }
    
    var textColor: UIColor {
        isDarkMode ? UIColor(red: 0.95, green: 0.95, blue: 1.0, alpha: 1.0) : UIColor(red: 0.15, green: 0.25, blue: 0.45, alpha: 1.0)
    }
    
    var secondaryTextColor: UIColor {
        isDarkMode ? UIColor(red: 0.7, green: 0.75, blue: 0.85, alpha: 1.0) : UIColor(red: 0.5, green: 0.5, blue: 0.55, alpha: 1.0)
    }
    
    var cardBackgroundColor: UIColor {
        isDarkMode ? UIColor(red: 0.15, green: 0.15, blue: 0.22, alpha: 1.0) : UIColor(red: 0.98, green: 0.98, blue: 1.0, alpha: 1.0)
    }
    
    private init() {
        // Load saved theme preference
        if let savedMode = UserDefaults.standard.string(forKey: "themeMode"),
           let mode = ThemeMode(rawValue: savedMode) {
            currentMode = mode
        }
    }
    
    func setTheme(_ mode: ThemeMode) {
        currentMode = mode
        UserDefaults.standard.set(mode.rawValue, forKey: "themeMode")
    }
    
    func getTheme() -> ThemeMode {
        return currentMode
    }
    
    private func applyTheme() {
        NotificationCenter.default.post(name: .themeDidChange, object: nil)
    }
}

extension ThemeMode {
    var rawValue: String {
        switch self {
        case .light: return "light"
        case .dark: return "dark"
        case .system: return "system"
        }
    }
    
    init?(rawValue: String) {
        switch rawValue {
        case "light": self = .light
        case "dark": self = .dark
        case "system": self = .system
        default: return nil
        }
    }
}

extension Notification.Name {
    static let themeDidChange = Notification.Name("themeDidChange")
}

