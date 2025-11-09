//
//  LocalNotificationManager.swift
//  nani
//
//  Created by Yash Thakkar on 11/8/25.
//

import Foundation
import UserNotifications

enum LocalNotificationManager {
    static func schedulePillAlert(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                print("Failed to schedule notification: \(error)")
            }
        }
    }
}
