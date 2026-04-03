# Acoustic Connect iOS SDK — Push Notification Integration Guide

This guide walks through the complete integration of mobile push notifications
using the Acoustic Connect iOS SDK. It covers everything from Apple Developer
portal setup through to testing on a device.

For a working reference implementation, see the
[ConnectPushSampleApp](../ConnectPushSampleApp/) in this repository.

---

## Table of contents

1. [Prerequisites](#1-prerequisites)
2. [Apple Developer portal setup](#2-apple-developer-portal-setup)
3. [Upload APNs key to Acoustic Connect](#3-upload-apns-key-to-acoustic-connect)
4. [Add the SDK to your project](#4-add-the-sdk-to-your-project)
5. [Configure App Groups](#5-configure-app-groups)
6. [Configure entitlements](#6-configure-entitlements)
7. [Configure Info.plist](#7-configure-infoplist)
8. [Initialize the SDK](#8-initialize-the-sdk)
9. [Request notification authorization](#9-request-notification-authorization)
10. [Analytics configuration](#10-analytics-configuration)
11. [Add the Notification Service Extension](#11-add-the-notification-service-extension)
12. [Add the Notification Content Extension](#12-add-the-notification-content-extension)
13. [Testing](#13-testing)
14. [Troubleshooting](#14-troubleshooting)

---

## 1. Prerequisites

- **Xcode 16** or later
- **iOS 15.1** or later deployment target
- An **Apple Developer Program** membership (push notifications require a paid account)
- An **Acoustic Connect** account with your app key and collector URL

---

## 2. Apple Developer portal setup

Push notifications require configuration in the Apple Developer portal before
any code changes.

### 2.1 Register an App ID

1. Go to [Certificates, Identifiers & Profiles](https://developer.apple.com/account/resources/identifiers/list)
2. Click **Identifiers** > **+** to register a new App ID
3. Select **App IDs** > **App**
4. Enter a description and your **Bundle ID** (e.g., `com.yourcompany.yourapp`)
5. Under **Capabilities**, enable:
   - **Push Notifications**
   - **App Groups** (required for the Notification Service Extension)
6. Click **Continue** > **Register**

If your App ID already exists, edit it to enable these capabilities.

### 2.2 Create an App Group

1. Go to **Identifiers** > **+** > select **App Groups**
2. Enter a description and an identifier (e.g., `group.com.yourcompany.yourapp`)
3. Click **Continue** > **Register**

> **Important:** The App Group identifier must be identical across your main app
> and all notification extensions. A mismatch is one of the most common
> integration issues.

### 2.3 Create an APNs Authentication Key

Apple recommends using a key (`.p8` file) rather than certificates for push
authentication. A single key works across all your apps in the same team.

1. Go to **Keys** > **+**
2. Enter a name (e.g., "Acoustic Connect APNs")
3. Enable **Apple Push Notifications service (APNs)**
4. Click **Continue** > **Register**
5. **Download the `.p8` file** — Apple only lets you download it once
6. Note the **Key ID** displayed on the confirmation page
7. Note your **Team ID** (visible in the top-right of the portal, or under
   Membership)

> **Keep the `.p8` file safe.** If you lose it, you must revoke the key and
> create a new one.

### 2.4 Register extension App IDs

If you plan to use rich push (Notification Service Extension and/or
Notification Content Extension), register App IDs for each:

- `com.yourcompany.yourapp.NotificationServiceExtension`
- `com.yourcompany.yourapp.NotificationContentExtension`

Enable **App Groups** on each extension App ID and assign the same App Group
created in step 2.2.

---

## 3. Upload APNs key to Acoustic Connect

1. Log in to the **Acoustic Connect** dashboard
2. Navigate to the mobile push configuration section for your app
3. Upload the `.p8` file downloaded in step 2.3
4. Enter the **Key ID** and **Team ID**
5. Enter your app's **Bundle ID**
6. Save the configuration

<!-- TODO: Add exact navigation path and screenshots when dashboard UI is finalized -->

---

## 4. Add the SDK to your project

### Option A: Swift Package Manager (recommended)

1. In Xcode, go to **File** > **Add Package Dependencies...**
2. Enter the repository URL:
   ```
   https://github.com/go-acoustic/ConnectDebug-SP
   ```
   > **Note:** This is the debug package. For production, use the release
   > package URL when available.
3. Set the version rule to **Up to Next Major Version** from `2.0.0`
4. Click **Add Package**
5. In the target selection dialog, add the **Connect** library to:
   - Your **main app** target
   - Your **Notification Service Extension** target (if using rich push)
   - Your **Notification Content Extension** target (if using rich push)

### Option B: CocoaPods

Add the following to your `Podfile`:

```ruby
platform :ios, '15.1'

target 'YourApp' do
  use_frameworks!
  pod 'AcousticConnectDebug'
  # For production: pod 'AcousticConnect'
end

# If using Notification Service Extension:
target 'YourNotificationServiceExtension' do
  use_frameworks!
  pod 'AcousticConnectDebug'
end

# If using Notification Content Extension:
target 'YourNotificationContentExtension' do
  use_frameworks!
  pod 'AcousticConnectDebug'
end
```

Then run:

```bash
pod install
```

> **Pitfall:** After `pod install`, always open the `.xcworkspace` file, not the
> `.xcodeproj`. Opening the wrong file is a common source of "module not found"
> errors.

### Option C: Carthage

Create a `Cartfile` in your project root:

```
binary "https://raw.githubusercontent.com/go-acoustic/EOCore/master/EOCoreDebug.json" >= 2.3.273
binary "https://raw.githubusercontent.com/go-acoustic/Tealeaf/master/TealeafDebug.json" >= 10.6.288
binary "https://raw.githubusercontent.com/go-acoustic/Connect/master/ConnectDebug.json" >= 2.0.0
```

> **Note:** For production, replace the `Debug` variants:
> ```
> binary "https://raw.githubusercontent.com/go-acoustic/EOCore/master/EOCore.json" >= 2.3.273
> binary "https://raw.githubusercontent.com/go-acoustic/Tealeaf/master/Tealeaf.json" >= 10.6.288
> binary "https://raw.githubusercontent.com/go-acoustic/Connect/master/Connect.json" >= 2.0.0
> ```
> **Do not mix debug and release variants** — use one or the other, never both.

Then run:

```bash
carthage update --use-xcframeworks
```

This downloads the prebuilt xcframeworks into `Carthage/Build/`.

**Link the frameworks:**

1. In Xcode, select your target > **General** > **Frameworks, Libraries, and
   Embedded Content**
2. Click **+** and add from `Carthage/Build/`:
   - `Connect.xcframework`
   - `Tealeaf.xcframework`
   - `EOCore.xcframework`
3. Ensure each framework is set to **Embed & Sign**
4. Repeat for your Notification Service Extension and Notification Content
   Extension targets — but set frameworks to **Do Not Embed** for extensions
   (they inherit the frameworks from the host app)

> **Pitfall:** Carthage requires all three frameworks to be linked. Unlike SPM
> and CocoaPods where you add a single dependency, Carthage exposes the
> individual xcframeworks. Missing any one of them will cause linker errors.

> **Pitfall:** If you see `"framework not found"` after running `carthage update`,
> ensure you are using the `--use-xcframeworks` flag. Without it, Carthage
> builds universal fat frameworks which are not compatible with modern Xcode.

### Verifying the installation

Create a Swift file with `import Connect` and build. If it compiles, the SDK is
correctly linked.

```swift
import Connect
// If this builds, the SDK is installed correctly.
```

---

## 5. Configure App Groups

App Groups enable data sharing between your main app and the notification
extensions. This is required for:

- Rich push media downloads
- Push delivery tracking
- Shared push token storage

### 5.1 Enable in Xcode

For **each target** (main app, NSE, NCE):

1. Select the target in Xcode
2. Go to **Signing & Capabilities**
3. Click **+ Capability** > **App Groups**
4. Add the App Group identifier created in step 2.2

### 5.2 Verify consistency

The App Group identifier must be **exactly the same** string in:

- Xcode capability for each target
- Your `ConnectConfig` code (the `appGroupIdentifier` parameter)
- Your Notification Service Extension subclass
- Your Notification Content Extension subclass

> **Pitfall:** A typo or mismatch in the App Group identifier is the #1 cause
> of rich push not working. The SDK will not produce an error — rich media will
> simply not appear.

---

## 6. Configure entitlements

Xcode generates entitlements files automatically when you add capabilities. Verify
that each target's entitlements file contains the correct values.

### Main app entitlements

```xml
<key>aps-environment</key>
<string>development</string>
<key>com.apple.security.application-groups</key>
<array>
    <string>group.com.yourcompany.yourapp</string>
</array>
<key>keychain-access-groups</key>
<array>
    <string>$(AppIdentifierPrefix)com.yourcompany.yourapp</string>
</array>
```

### Extension entitlements (NSE and NCE)

```xml
<key>com.apple.security.application-groups</key>
<array>
    <string>group.com.yourcompany.yourapp</string>
</array>
<key>keychain-access-groups</key>
<array>
    <string>$(AppIdentifierPrefix)com.yourcompany.yourapp</string>
</array>
```

> **Note:** The `aps-environment` value is `development` for debug builds. Xcode
> automatically uses `production` for App Store and ad-hoc distribution builds.

---

## 7. Configure Info.plist

Add the following to your main app's `Info.plist` (or via Xcode's Info tab):

```xml
<key>UIBackgroundModes</key>
<array>
    <string>remote-notification</string>
</array>
```

This enables your app to receive silent push notifications in the background.

---

## 8. Initialize the SDK

The SDK should be initialized early in your app's lifecycle — ideally in
`AppDelegate.application(_:didFinishLaunchingWithOptions:)`.

### Choose a push mode

The SDK supports two push modes:

| Mode | Description | Best for |
|------|-------------|----------|
| **Manual** | Your app handles token registration, notification delegate, and forwards all callbacks to the SDK | Apps with existing push infrastructure, or when you need full control |
| **Automatic** | The SDK handles token registration and notification callbacks automatically. You still need to request notification permission (see step 9) | New apps with no existing push handling |

### Manual mode (recommended for understanding the full flow)

**AppDelegate.swift:**

```swift
import Connect
import UIKit

final class AppDelegate: NSObject, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // 1. Set up the notification delegate BEFORE enabling the SDK.
        //    Apple requires this to be done before this method returns.
        UNUserNotificationCenter.current().delegate = yourNotificationDelegate

        // 2. Enable the SDK with your configuration.
        ConnectSDK.shared.enable(
            with: ConnectConfig(
                appKey: "YOUR_APP_KEY",
                postURL: "YOUR_POST_URL",
                push: ConnectPushConfig(
                    mode: .manual,
                    appGroupIdentifier: "group.com.yourcompany.yourapp"
                )
            )
        )
        return true
    }

    // 3. Forward the APNs device token to the SDK.
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        try? ConnectSDK.shared.push.didRegisterWithToken(deviceToken)
    }

    // 4. Forward registration failures to the SDK.
    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        try? ConnectSDK.shared.push.didFailToRegisterWithError(error)
    }
}
```

**UNUserNotificationCenterDelegate:**

```swift
import Connect
import UserNotifications

class YourNotificationDelegate: NSObject, UNUserNotificationCenterDelegate {

    // Called when a notification arrives while the app is in the foreground.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Forward to SDK — generates a pushReceived signal.
        try? ConnectSDK.shared.push.didReceiveNotification(notification)

        // Show the notification banner even when the app is in the foreground.
        completionHandler([.banner, .badge, .sound])
    }

    // Called when the user taps a notification or action button.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        // Forward to SDK — handles built-in actions (OPEN_URL, OPEN_DIALER, etc.)
        try? ConnectSDK.shared.push.didReceive(response)

        completionHandler()
    }
}
```

### Automatic mode

Automatic mode requires significantly less code. The SDK installs a transparent
delegate proxy that handles token registration and notification callbacks.

```swift
func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
) -> Bool {
    ConnectSDK.shared.enable(
        with: ConnectConfig(
            appKey: "YOUR_APP_KEY",
            postURL: "YOUR_POST_URL",
            push: ConnectPushConfig(
                mode: .automatic,
                appGroupIdentifier: "group.com.yourcompany.yourapp"
            )
        )
    )
    return true
}

// No didRegisterForRemoteNotificationsWithDeviceToken needed.
// No UNUserNotificationCenterDelegate setup needed.
// The SDK handles token registration and notification callbacks automatically.
// You still need to request notification permission (see step 9).
```

> **Pitfall:** If you use automatic mode but also set
> `UNUserNotificationCenter.current().delegate` yourself, the SDK's proxy will
> be overwritten and push signals will not be tracked. Use manual mode if you
> need your own delegate.

### SwiftUI apps

If your app uses SwiftUI's `@main App` struct, use `@UIApplicationDelegateAdaptor`
to bridge to an `AppDelegate`:

```swift
import SwiftUI

@main
struct YourApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

> **Pitfall:** Do not initialize the SDK in a SwiftUI `.onAppear` or `.task`
> modifier. The SDK must be initialized in
> `didFinishLaunchingWithOptions` so the notification delegate is set before
> iOS delivers any pending notification from a cold-start tap.

---

## 9. Request notification authorization

Regardless of push mode, your app must request notification permission from the
user. Push registration only happens after the user grants it. Request
authorization at an appropriate point in your app's UX.

### Manual mode

In manual mode, forward the authorization result to the SDK so it can send a
`pushRegistration` signal to the Acoustic backend:

```swift
func requestNotificationPermission() async {
    do {
        let granted = try await UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .badge, .sound])
        try await ConnectSDK.shared.push.didReceiveAuthorization(
            granted: granted, error: nil
        )
    } catch {
        try? await ConnectSDK.shared.push.didReceiveAuthorization(
            granted: false, error: error
        )
    }
}
```

### Automatic mode

In automatic mode, the SDK intercepts the authorization result automatically —
you only need to trigger the system prompt:

```swift
func requestNotificationPermission() async {
    _ = try? await UNUserNotificationCenter.current()
        .requestAuthorization(options: [.alert, .badge, .sound])
}
```

> **Pitfall:** iOS only shows the system permission dialog **once**. If the user
> denies it, subsequent calls to `requestAuthorization` return immediately with
> `granted: false`. The only way for the user to re-enable notifications is
> through Settings. Design your UX accordingly — don't request permission on
> first launch without context.

---

## 10. Analytics configuration

The SDK captures user interactions, screen visits, and screenshots
**automatically** with no additional setup. When no `ConnectLayoutConfig.json`
file is present in your app bundle, the SDK uses its built-in `basicAnalytics`
layout which enables sensible defaults for all screens:

- **User events** — taps, swipes, text changes captured on every screen
- **Screen transitions** — recorded automatically
- **Screenshots** — taken on screen transitions for session replay
- **Default masking** — digits masked as `9`, letters as `x`/`X`, symbols as `#`

This means analytics work out of the box with a minimal `ConnectConfig` — no
layout file or additional configuration needed.

### Customising analytics per screen

If you need per-screen control (e.g., disabling capture on a settings screen, or
adding custom masking rules for sensitive fields), add a
`ConnectLayoutConfig.json` file to your app's main bundle:

```json
{
    "AutoLayout": {
        "GlobalScreenSettings": {
            "ScreenChange": true,
            "ScreenShot": true,
            "CaptureUserEvents": true,
            "CaptureScreenVisits": true,
            "CaptureLayoutOn": 2,
            "CaptureScreenshotOn": 2,
            "Masking": {
                "HasMasking": true,
                "HasCustomMask": true,
                "Sensitive": {
                    "capitalCaseAlphabet": "X",
                    "number": "9",
                    "smallCaseAlphabet": "x",
                    "symbol": "#"
                },
                "MaskIdList": [],
                "MaskValueList": []
            }
        },
        "MySettingsViewController": {
            "CaptureUserEvents": false,
            "ScreenShot": false
        }
    }
}
```

When the file is present, the SDK uses it instead of the built-in defaults.
Per-screen entries override `GlobalScreenSettings` for matching view controllers.

### Explicit programmatic layout

You can also pass the layout configuration directly in code:

```swift
ConnectSDK.shared.enable(
    with: ConnectConfig(
        appKey: "YOUR_APP_KEY",
        postURL: "YOUR_POST_URL",
        push: pushConfig,
        layout: .basicAnalytics   // same as the default when no file is present
    )
)
```

Or provide a fully custom layout dictionary:

```swift
ConnectSDK.shared.enable(
    with: ConnectConfig(
        appKey: "YOUR_APP_KEY",
        postURL: "YOUR_POST_URL",
        push: pushConfig,
        layout: ConnectConfig.Layout(autoLayout: [
            "GlobalScreenSettings": [
                "ScreenChange": true,
                "ScreenShot": true,
                "CaptureUserEvents": true,
                "CaptureScreenVisits": true,
                "CaptureLayoutOn": 2,
                "CaptureScreenshotOn": 2
            ]
        ])
    )
)
```

---

## 11. Add the Notification Service Extension

The Notification Service Extension (NSE) enables:

- **Rich push** — downloading and attaching images to notifications
- **Delivery tracking** — recording that a push was delivered to the device

### 11.1 Create the extension target

1. In Xcode, go to **File** > **New** > **Target...**
2. Select **Notification Service Extension**
3. Name it (e.g., `NotificationServiceExtension`)
4. Ensure the **Embed in Application** dropdown shows your main app
5. Click **Finish**

### 11.2 Add the SDK dependency

- **SPM:** In the target selection for the Connect package, check the NSE target
- **CocoaPods:** Add the pod to the NSE target in your Podfile
- **Carthage:** Link the xcframeworks to the NSE target (set to **Do Not Embed**)

### 11.3 Implement the extension

Replace the generated `NotificationService.swift` with:

```swift
import Connect

final class NotificationService: ConnectNotificationService, @unchecked Sendable {
    override var appGroupIdentifier: String? {
        "group.com.yourcompany.yourapp"  // Must match your main app
    }
}
```

That's it. The base class handles media download, attachment, and delivery
tracking.

### 12.4 Configure Info.plist

The generated `Info.plist` should already be correct. Verify it contains:

```xml
<key>NSExtension</key>
<dict>
    <key>NSExtensionPointIdentifier</key>
    <string>com.apple.usernotifications.service</string>
    <key>NSExtensionPrincipalClass</key>
    <string>$(PRODUCT_MODULE_NAME).NotificationService</string>
</dict>
```

> **Pitfall:** The NSE has a **30-second time limit** for processing. If the
> image download takes too long, iOS will display the notification without the
> attachment. The SDK handles this timeout gracefully.

---

## 12. Add the Notification Content Extension

The Notification Content Extension (NCE) provides custom UI for expanded
notifications (long-press on the notification).

### 12.1 Create the extension target

1. In Xcode, go to **File** > **New** > **Target...**
2. Select **Notification Content Extension**
3. Name it (e.g., `NotificationContentExtension`)
4. Click **Finish**

### 12.2 Add the SDK dependency

Same as step 11.2 — add the Connect library to this target.

### 12.3 Implement the extension

Replace the generated `NotificationViewController.swift` with:

```swift
import Connect

final class NotificationViewController: ConnectNotificationContentExtension {
    override var appGroupIdentifier: String? {
        "group.com.yourcompany.yourapp"  // Must match your main app
    }
}
```

### 12.4 Configure Info.plist

Update the NCE's `Info.plist` to register for the Acoustic notification
categories:

```xml
<key>NSExtension</key>
<dict>
    <key>NSExtensionAttributes</key>
    <dict>
        <key>UNNotificationExtensionCategory</key>
        <array>
            <string>ACOUSTIC_RICH_NOTIFICATION</string>
        </array>
        <key>UNNotificationExtensionDefaultContentHidden</key>
        <false/>
        <key>UNNotificationExtensionInitialContentSizeRatio</key>
        <real>1</real>
    </dict>
    <key>NSExtensionPointIdentifier</key>
    <string>com.apple.usernotifications.content</string>
    <key>NSExtensionPrincipalClass</key>
    <string>$(PRODUCT_MODULE_NAME).NotificationViewController</string>
</dict>
```

### 12.5 Delete the storyboard

Xcode generates a `MainInterface.storyboard` for the NCE. The SDK's base class
handles all UI programmatically, so you should **delete** this storyboard file
and **remove** the `NSExtensionMainStoryboard` key from the Info.plist if
present.

---

## 13. Testing

### 13.1 Simulator testing with .apns files

You can test push notifications in the simulator using `.apns` payload files.
See the [TestPayloads](../TestPayloads/) directory for examples.

To send a test notification, drag an `.apns` file onto the running simulator.

The `.apns` file must include a `Simulator Target Bundle` key matching your app's
bundle identifier:

```json
{
    "Simulator Target Bundle": "com.yourcompany.yourapp",
    "aps": {
        "alert": {
            "title": "Test notification",
            "body": "This is a test push notification."
        },
        "sound": "default"
    }
}
```

### 13.2 Rich push payload

To test rich push (images), include `mutable-content` in the payload:

```json
{
    "Simulator Target Bundle": "com.yourcompany.yourapp",
    "aps": {
        "alert": {
            "title": "Rich notification",
            "body": "This notification includes an image."
        },
        "mutable-content": 1,
        "sound": "default"
    },
    "data": {
        "notification": {
            "expandedImage": "https://example.com/image.jpg",
            "expandedBody": "Extended content shown in the expanded view."
        }
    }
}
```

> **Note:** `mutable-content: 1` tells iOS to pass the notification through
> your Notification Service Extension before displaying it. Without this flag,
> the NSE will not be invoked and no image will be attached.

### 13.3 Actionable notifications

To test action buttons:

```json
{
    "Simulator Target Bundle": "com.yourcompany.yourapp",
    "aps": {
        "alert": {
            "title": "New offer",
            "body": "Tap to view or use the action buttons."
        },
        "sound": "default"
    },
    "data": {
        "action": {
            "type": "OPEN_URL",
            "url": "https://example.com/offer",
            "label": "View offer"
        }
    }
}
```

### 13.4 Device testing

Push notifications require a real device for full end-to-end testing. The
simulator supports basic `.apns` file delivery but cannot receive real remote
push notifications.

To test on a device:
1. Build and run on a physical device
2. Grant notification permission when prompted
3. Send a test push from the Acoustic Connect dashboard
4. Verify the notification appears and actions work correctly

---

## 14. Troubleshooting

### SDK fails to initialize (legacy file-based configuration)

**Symptom:** Console shows messages like `failed to enable` or
`bundle not found in main bundle`.

**Cause:** If your project uses file-based SDK configuration (configuration
bundle files), those files must be present in the main app target's **Copy
Bundle Resources** build phase. This does not apply to new integrations using
`ConnectConfig` programmatic setup.

**Fix:** Verify the configuration bundles are included in your target's build
phases and contain valid values.

---

### "Module 'Connect' not found" build error

**Cause:** The SDK is not linked to the target that's importing it.

**Fix (SPM):** In project settings > Package Dependencies, verify the Connect
library is added to the correct target. For extension targets, you may need to
add it manually via the target's **Frameworks, Libraries, and Embedded
Content** section.

**Fix (CocoaPods):** Ensure the pod is listed under the correct target in your
`Podfile`, run `pod install`, and open the `.xcworkspace` (not `.xcodeproj`).

---

### Push token not received

**Symptom:** `didRegisterForRemoteNotificationsWithDeviceToken` is never called.

**Possible causes:**
1. Running on the simulator (tokens are not available on simulator in most
   configurations)
2. The user denied notification permission
3. `remote-notification` is not in `UIBackgroundModes` in Info.plist
4. The app's bundle ID doesn't match any App ID with Push Notifications enabled
   in the Apple Developer portal

---

### Rich push images not showing

**Symptom:** Notifications arrive but without images.

**Checklist:**
1. Is `mutable-content: 1` present in the push payload?
2. Is the Notification Service Extension target included in the app?
3. Does the NSE's `appGroupIdentifier` exactly match the main app's?
4. Is the Connect library linked to the NSE target?
5. Is the image URL accessible (HTTPS, valid, not too large)?
6. Check the NSE's console output for download errors (in Xcode, attach to the
   NSE process)

---

### Notification actions not working

**Symptom:** Tapping a notification action button does nothing.

**Checklist:**
1. Is the Notification Content Extension configured with matching categories in
   its Info.plist?
2. In manual mode, are you forwarding `didReceive(response:)` to the SDK?

---

### Duplicate notifications in foreground

**Symptom:** Notification appears as both a banner and an in-app alert.

**Cause:** Using automatic mode but also setting your own
`UNUserNotificationCenterDelegate` that presents the notification.

**Fix:** Use manual mode if you need your own delegate, or remove your delegate
and let automatic mode handle it.

---

### Push signals not appearing in Acoustic dashboard

**Symptom:** Notifications work on the device but the Acoustic Connect dashboard
shows no push engagement data.

**Checklist:**
1. Is the `appKey` correct and matching the dashboard configuration?
2. Is the `postURL` pointing to the correct collector endpoint?
3. In manual mode, are you calling `didReceiveAuthorization(granted:error:)`
   after requesting permission?
4. In manual mode, are you forwarding the device token via
   `didRegisterWithToken(_:)`?
5. In manual mode, are you forwarding notification responses via
   `didReceive(response:)` and `didReceiveNotification(_:)`?
6. Check the Xcode console for SDK debug logs by adding these environment
   variables in your scheme (**Product** > **Scheme** > **Edit Scheme** >
   **Run** > **Arguments** > **Environment Variables**):
   - `CONNECT_DEBUG=1`
   - `TLF_DEBUG=1`
   - `EODebug=1`

---

### Extension crashes on launch

**Symptom:** NSE or NCE crashes immediately.

**Common causes:**
1. Missing SDK dependency — the extension target needs the Connect library linked
2. Wrong principal class name in Info.plist — must be
   `$(PRODUCT_MODULE_NAME).YourClassName`
3. Missing App Group entitlement on the extension target
4. Extension deployment target is higher than the device OS version

---

## Quick reference: integration checklist

Use this checklist to verify your integration is complete:

- [ ] Apple Developer portal: App ID with Push Notifications enabled
- [ ] Apple Developer portal: APNs authentication key (.p8) created
- [ ] Apple Developer portal: App Group created and assigned to all targets
- [ ] Acoustic Connect: APNs key uploaded with Key ID, Team ID, and Bundle ID
- [ ] Xcode: SDK added via SPM, CocoaPods, or Carthage to all targets (app + extensions)
- [ ] Xcode: App Groups capability enabled on all targets with matching identifier
- [ ] Xcode: Push Notifications capability enabled on main app target
- [ ] Xcode: `remote-notification` background mode in Info.plist
- [ ] Code: SDK initialized in `didFinishLaunchingWithOptions`
- [ ] Code: Notification authorization requested and result forwarded to SDK
- [ ] Code: (Manual mode) Token forwarding in AppDelegate
- [ ] Code: (Manual mode) UNUserNotificationCenterDelegate forwarding to SDK
- [ ] Code: Notification Service Extension with correct App Group
- [ ] Code: Notification Content Extension with correct App Group and categories
- [ ] Test: Push received on device with correct content
- [ ] Test: Rich push displays image
- [ ] Test: Action buttons work (OPEN_URL, OPEN_APP, OPEN_DIALER)
- [ ] Test: Push signals appear in Acoustic Connect dashboard
