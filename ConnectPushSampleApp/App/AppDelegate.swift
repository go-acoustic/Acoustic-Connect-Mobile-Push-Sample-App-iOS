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

final class AppDelegate: NSObject, UIApplicationDelegate {

    override init() {
        super.init()
        // Enable SDK debug logging for all builds of the demo app — including simulator
        // builds distributed via Artifactory where no debugger sets env vars.
        // setenv with overwrite=0 so any value already in the environment takes precedence
        // (e.g. when running via Xcode with scheme env vars enabled).
        // These calls must happen before SDK initialisation, which is deferred to
        // .task {} / .onAppear {} in the view layer, so this init() is the earliest
        // safe point where NSProcessInfo.environment has not yet been read by the SDK.
        // Comment out if not needed.
        setenv("CONNECT_DEBUG", "1", 0)
        setenv("TLF_DEBUG", "1", 0)
        setenv("EODebug", "1", 0)
    }

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Initialize the SDK and set up push notification handling.
        // Apple requires the UNUserNotificationCenter delegate to be set before
        // this method returns, so start() must be called here — not later.
        ConnectSDKManager.shared.start()
        return true
    }

    // ┌──────────────────────────────────────────────────────────────────────┐
    // │  Manual mode: forward APNs callbacks to the SDK.                    │
    // │                                                                     │
    // │  In automatic mode these methods are not needed — the SDK installs  │
    // │  a transparent proxy that intercepts the callbacks directly.        │
    // │  See ConnectSDKManager.start() for instructions on switching modes. │
    // └──────────────────────────────────────────────────────────────────────┘

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        ConnectSDKManager.shared.didReceiveToken(deviceToken)
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("[ConnectSample] APNs registration failed: \(error.localizedDescription)")
    }
}
