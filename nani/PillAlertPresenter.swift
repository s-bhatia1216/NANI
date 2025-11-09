//
//  PillAlertPresenter.swift
//  nani
//
//  Created by Yash Thakkar on 11/8/25.
//

import UIKit

final class PillAlertPresenter {
    static let shared = PillAlertPresenter()
    
    private init() {}
    
    func showAlert(title: String, message: String) {
        guard let topController = Self.topViewController() else { return }
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: LocalizationManager.shared.localized(english: "OK", hindi: "ठीक है"), style: .default))
        topController.present(alert, animated: true)
    }
    
    private static func topViewController(base: UIViewController? = nil) -> UIViewController? {
        let baseVC: UIViewController?
        if let base {
            baseVC = base
        } else {
            baseVC = UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .first(where: { $0.isKeyWindow })?.rootViewController
        }
        guard let root = baseVC else { return nil }
        if let nav = root as? UINavigationController {
            return topViewController(base: nav.visibleViewController)
        }
        if let tab = root as? UITabBarController {
            return topViewController(base: tab.selectedViewController)
        }
        if let presented = root.presentedViewController {
            return topViewController(base: presented)
        }
        return root
    }
}
