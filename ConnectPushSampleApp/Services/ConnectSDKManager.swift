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
import Combine
import UserNotifications

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - Configuration
//
// Replace these values with your Acoustic Connect credentials before running.
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

private enum ConnectConfiguration {

    /// Your Acoustic Connect application key.
    static let appKey = "YOUR_APP_KEY"

    /// Your Acoustic Connect collector endpoint URL.
    static let postURL = "YOUR_POST_URL"

    /// The App Group shared between the main app and notification extensions.
    /// Must match the App Group configured in your Apple Developer portal.
    static let appGroup = "YOUR_APP_GROUP"
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// Manages Connect SDK lifecycle and state for the sample app.
@MainActor
final class ConnectSDKManager: ObservableObject {

    // MARK: - Shared instance

    static let shared = ConnectSDKManager()

    // MARK: - Private

    private let notificationDelegate = NotificationDelegate()

    // MARK: - Observable state

    /// The current UNAuthorizationStatus for push notifications.
    @Published private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined

    // MARK: - Identity

    /// A name/value pair used in the Identity demo form.
    struct IdentityPair: Codable, Equatable, Identifiable {
        var id: String { name }
        var name: String
        var value: String
    }

    /// The last five logged identity pairs, most recent first.
    @Published private(set) var identityHistory: [IdentityPair] = {
        guard
            let data = UserDefaults.standard.data(forKey: "connectSampleIdentityPairs"),
            let saved = try? JSONDecoder().decode([IdentityPair].self, from: data)
        else { return [] }
        return saved
    }()

    /// The result message from the most recent identity log call.
    @Published private(set) var identityLogResult: String?

    // MARK: - Init

    private init() {
        Task { await self.refreshAuthorizationStatus() }
    }

    // MARK: - SDK startup

    /// Enables the Connect SDK. Call once from `AppDelegate.didFinishLaunchingWithOptions`.
    func start() {

        // ┌──────────────────────────────────────────────────────────────────┐
        // │  Manual mode (default)                                          │
        // │                                                                 │
        // │  Your app handles push registration and forwards callbacks to   │
        // │  the SDK. This gives you full control over                      │
        // │  UNUserNotificationCenterDelegate.                              │
        // │                                                                 │
        // │  Required AppDelegate methods:                                  │
        // │  • didRegisterForRemoteNotificationsWithDeviceToken             │
        // │  • didFailToRegisterForRemoteNotificationsWithError             │
        // │                                                                 │
        // │  Required UNUserNotificationCenterDelegate setup:               │
        // │  • Set your delegate before enable() returns                    │
        // │  • Forward notifications to ConnectSDK.shared.push             │
        // └──────────────────────────────────────────────────────────────────┘
        let pushConfig = ConnectPushConfig(
            mode: .manual,
            appGroupIdentifier: ConnectConfiguration.appGroup
        )

        // Set up the notification delegate before enabling the SDK.
        // In manual mode, the app is responsible for handling notification
        // callbacks and forwarding them to ConnectSDK.
        // See NotificationDelegate.swift for the implementation.
        UNUserNotificationCenter.current().delegate = notificationDelegate

        // ┌──────────────────────────────────────────────────────────────────┐
        // │  Automatic mode (alternative)                                   │
        // │                                                                 │
        // │  The SDK manages the full push lifecycle — no AppDelegate       │
        // │  token forwarding or notification delegate setup needed.        │
        // │                                                                 │
        // │  To switch to automatic mode:                                   │
        // │  1. Replace the pushConfig above with:                          │
        // │     let pushConfig = ConnectPushConfig(                         │
        // │         mode: .automatic,                                       │
        // │         appGroupIdentifier: ConnectConfiguration.appGroup       │
        // │     )                                                           │
        // │  2. Remove the UNUserNotificationCenter.delegate line above     │
        // │  3. In AppDelegate, you can remove:                             │
        // │     • didRegisterForRemoteNotificationsWithDeviceToken          │
        // │     • didFailToRegisterForRemoteNotificationsWithError          │
        // └──────────────────────────────────────────────────────────────────┘

        ConnectSDK.shared.enable(
            with: ConnectConfig(
                appKey: ConnectConfiguration.appKey,
                postURL: ConnectConfiguration.postURL,
                push: pushConfig
            )
        )
    }

    // MARK: - Authorization

    /// Requests push notification authorization from the user.
    func requestAuthorization() async {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
            try await ConnectSDK.shared.push.didReceiveAuthorization(granted: granted, error: nil)
        } catch {
            try? await ConnectSDK.shared.push.didReceiveAuthorization(granted: false, error: error)
        }
        await refreshAuthorizationStatus()
    }

    /// Refreshes ``authorizationStatus`` by querying `UNUserNotificationCenter`.
    func refreshAuthorizationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        authorizationStatus = settings.authorizationStatus
    }

    // MARK: - Token

    /// Forwards the APNs device token to the Connect SDK.
    ///
    /// Call from `AppDelegate.didRegisterForRemoteNotificationsWithDeviceToken`.
    /// Only needed in **manual** push mode — in automatic mode the SDK
    /// intercepts the token callback via a transparent proxy.
    nonisolated func didReceiveToken(_ token: Data) {
        Task { @MainActor in
            do {
                try ConnectSDK.shared.push.didRegisterWithToken(token)
            } catch {
                assertionFailure("[ConnectSample] Push not enabled — token not sent to SDK")
            }
        }
    }

    // MARK: - Identity

    /// Logs a single identity signal and records the pair in ``identityHistory``.
    func logIdentity(
        name: String,
        value: String,
        signalType: String = "pageView",
        additionalParameters: [String: String] = ["url": "http://acoustic.co/test"]
    ) {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        let trimmedValue = value.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty, !trimmedValue.isEmpty else { return }

        let success = ConnectSDK.shared.identity.log(
            identifierName: trimmedName,
            identifierValue: trimmedValue,
            signalType: signalType,
            additionalParameters: additionalParameters
        )
        identityLogResult = success
            ? "✓ \(trimmedName): \(trimmedValue)"
            : "✗ Failed to log \(trimmedName)"

        let pair = IdentityPair(name: trimmedName, value: trimmedValue)
        var history = identityHistory.filter { $0.name != pair.name }
        history.insert(pair, at: 0)
        identityHistory = Array(history.prefix(5))
        if let data = try? JSONEncoder().encode(identityHistory) {
            UserDefaults.standard.set(data, forKey: "connectSampleIdentityPairs")
        }
    }
}
