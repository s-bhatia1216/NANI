import Foundation

enum AppLanguage: String, CaseIterable {
    case english
    case hindi
    
    var identifier: String {
        switch self {
        case .english: return "en"
        case .hindi: return "hi"
        }
    }
    
    var displayTitle: LocalizedText {
        switch self {
        case .english:
            return LocalizedText(english: "English", hindi: "अंग्रेज़ी")
        case .hindi:
            return LocalizedText(english: "Hindi", hindi: "हिन्दी")
        }
    }
}

struct LocalizedText: Equatable {
    let english: String
    let hindi: String
    
    init(english: String, hindi: String) {
        self.english = english
        self.hindi = hindi
    }
    
    static func same(_ value: String) -> LocalizedText {
        return LocalizedText(english: value, hindi: value)
    }
    
    func value(for language: AppLanguage) -> String {
        switch language {
        case .english:
            return english
        case .hindi:
            return hindi
        }
    }
}

extension Notification.Name {
    static let languageDidChange = Notification.Name("LocalizationManagerLanguageDidChange")
}

final class LocalizationManager {
    
    static let shared = LocalizationManager()
    
    private let storageKey = "LocalizationManager.selectedLanguage"
    private(set) var currentLanguage: AppLanguage {
        didSet {
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: storageKey)
            NotificationCenter.default.post(name: .languageDidChange, object: nil)
        }
    }
    
    private init() {
        if let stored = UserDefaults.standard.string(forKey: storageKey),
           let language = AppLanguage(rawValue: stored) {
            currentLanguage = language
        } else {
            currentLanguage = .english
        }
    }
    
    func setLanguage(_ language: AppLanguage) {
        guard language != currentLanguage else { return }
        currentLanguage = language
    }
    
    func localized(_ text: LocalizedText) -> String {
        return text.value(for: currentLanguage)
    }
    
    func localized(english: String, hindi: String) -> String {
        return LocalizedText(english: english, hindi: hindi).value(for: currentLanguage)
    }
    
    func isCurrentLanguage(_ language: AppLanguage) -> Bool {
        return currentLanguage == language
    }
}


