//
//  MainTabBarController.swift
//  nani
//
//  Created by Yash Thakkar on 11/8/25.
//

import UIKit

class MainTabBarController: UITabBarController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViewControllers()
        setupTabBar()
        setupTheme()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(themeDidChange),
            name: .themeDidChange,
            object: nil
        )
    }
    
    private func setupViewControllers() {
        // Home
        let homeVC = HomeViewController()
        let homeNav = UINavigationController(rootViewController: homeVC)
        homeNav.tabBarItem = UITabBarItem(title: "Home", image: UIImage(systemName: "house.fill"), tag: 0)
        
        // Voice AI - Microphone tab
        let voiceVC = VoiceInteractionViewController()
        let voiceNav = UINavigationController(rootViewController: voiceVC)
        voiceNav.tabBarItem = UITabBarItem(title: "AI Assistant", image: UIImage(systemName: "mic.fill"), tag: 1)
        
        // Medications
        let medsVC = MedicationsViewController()
        let medsNav = UINavigationController(rootViewController: medsVC)
        medsNav.tabBarItem = UITabBarItem(title: "My Medications", image: UIImage(systemName: "pills"), tag: 2)
        
        viewControllers = [homeNav, voiceNav, medsNav]
        selectedIndex = 0
        
        // Set delegate to handle tab selection
        delegate = self
    }
    
    private func setupTabBar() {
        tabBar.backgroundColor = ThemeManager.shared.backgroundColor
        tabBar.barTintColor = ThemeManager.shared.backgroundColor
        tabBar.tintColor = ThemeManager.shared.primaryBlue
        tabBar.unselectedItemTintColor = ThemeManager.shared.secondaryTextColor
    }
    
    private func setupTheme() {
        tabBar.backgroundColor = ThemeManager.shared.backgroundColor
        tabBar.barTintColor = ThemeManager.shared.backgroundColor
        tabBar.tintColor = ThemeManager.shared.primaryBlue
        tabBar.unselectedItemTintColor = ThemeManager.shared.secondaryTextColor
    }
    
    @objc private func themeDidChange() {
        setupTheme()
    }
}

// MARK: - UITabBarControllerDelegate
extension MainTabBarController: UITabBarControllerDelegate {
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        // If the microphone tab is selected, present it modally instead of switching tabs
        if let navController = viewController as? UINavigationController,
           navController.viewControllers.first is VoiceInteractionViewController {
            let voiceVC = VoiceInteractionViewController()
            let modalNav = UINavigationController(rootViewController: voiceVC)
            present(modalNav, animated: true)
            return false // Prevent tab switch
        }
        return true
    }
}

