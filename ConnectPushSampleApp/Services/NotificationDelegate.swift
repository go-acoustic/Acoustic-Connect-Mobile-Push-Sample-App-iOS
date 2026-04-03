//
// Copyright (C) 2026 Acoustic, L.P. All rights reserved.
//
// Licensed under the Acoustic License (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy
// at https://www.acoustic.com/licenses/acoustic-license
//
// Sample app provided "as is", without warranty of any kind.
//

import Connect
import UIKit
import UserNotifications

@MainActor
final class NotificationDelegate: NSObject, @preconcurrency UNUserNotificationCenterDelegate {

    // MARK: - Callbacks

    /// Invoked when a notification is delivered while the app is in the foreground.
    ///
    /// - Parameter notification: The notification that was delivered.
    var onForegroundNotificationReceived: ((UNNotification) -> Void)?

    /// Invoked when the user interacts with an Acoustic notification (banner tap or action button).
    ///
    /// - Parameters:
    ///   - actionType: The resolved action type string (e.g. `"OPEN_URL"`, `"OPEN_DIALER"`, `"OPEN_APP"`).
    ///   - notification: The notification that was interacted with.
    var onActionReceived: ((String, UNNotification) -> Void)?

    // MARK: - Debug helpers

    private func logPayload(_ userInfo: [AnyHashable: Any], event: String) {
        guard let data = try? JSONSerialization.data(withJSONObject: userInfo, options: .prettyPrinted),
              let json = String(data: data, encoding: .utf8) else {
            print("[ConnectSample] \(event) — payload (non-JSON): \(userInfo)")
            return
        }
        print("[ConnectSample] \(event) payload:\n\(json)")
    }

    // MARK: - UNUserNotificationCenterDelegate

    /// Called when a notification is delivered while the app is in the foreground.
    ///
    /// Forwards the notification to the Connect SDK so a `pushReceived` signal is recorded,
    /// then fires `onForegroundNotificationReceived` to update the UI.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        logPayload(notification.request.content.userInfo, event: "willPresent")
        try? ConnectSDK.shared.push.didReceiveNotification(notification)
        onForegroundNotificationReceived?(notification)
        completionHandler([.banner, .badge, .sound])
    }

    /// Called when the user interacts with a delivered notification (taps the banner or an action button).
    ///
    /// Forwards the response to the Connect SDK so built-in actions (`OPEN_URL`, `OPEN_DIALER`) are
    /// executed. The demo app then fires `onActionReceived` to update the UI.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        logPayload(response.notification.request.content.userInfo, event: "didReceive(response:)")
        try? ConnectSDK.shared.push.didReceive(response)

        if response.actionIdentifier != UNNotificationDismissActionIdentifier {
            let userInfo = response.notification.request.content.userInfo
            let actionType: String?
            if response.actionIdentifier == UNNotificationDefaultActionIdentifier {
                let data = userInfo["data"] as? [String: Any]
                let action = data?["action"] as? [String: Any]
                actionType = action?["type"] as? String
            } else {
                actionType = response.actionIdentifier
            }
            if let type = actionType {
                onActionReceived?(type, response.notification)
            }
        }

        completionHandler()
    }
}
