# Acoustic Connect Push Sample App

SwiftUI sample app demonstrating **mobile push notification** integration with
the [Acoustic Connect iOS SDK](https://github.com/go-acoustic/ConnectDebug-SP).

Use this alongside the
[Integration Guide](docs/integration-guide.md)
to see a working implementation of push registration, notification handling, and
identity logging.

---

## What's included

| Feature | Description |
|---------|-------------|
| **Push registration** | Manual mode (default) with commented-out automatic alternative |
| **Notification authorization** | Request and display push permission status |
| **Notification Service Extension** | Rich push support (images, expanded content) |
| **Notification Content Extension** | Custom notification UI |
| **Analytics capture** | Enabled by default — events, screenshots, and screen visits out of the box |
| **Identity logging** | Log identity signals and view recent history |
| **Test payloads** | `.apns` files for simulator push testing |

---

## Getting started

For the complete step-by-step walkthrough — including Apple Developer portal
setup, APNs key configuration, dependency installation (SPM, CocoaPods,
Carthage), and troubleshooting — see the
**[Integration Guide](docs/integration-guide.md)**.

The quick-start steps below assume you've completed the prerequisites in the
guide.

### 1. Clone the repository

```bash
git clone https://github.com/go-acoustic/Acoustic-Connect-Mobile-Push-Sample-App.git
cd Acoustic-Connect-Mobile-Push-Sample-App
```

### 2. Open in Xcode

```bash
open ConnectPushSampleApp.xcodeproj
```

Xcode will automatically resolve the Connect SDK Swift Package dependency.

### 3. Configure your credentials

Open `ConnectPushSampleApp/Services/ConnectSDKManager.swift` and replace the
placeholder values:

```swift
private enum ConnectConfiguration {
    static let appKey = "YOUR_APP_KEY"       // <-- your Acoustic app key
    static let postURL = "YOUR_POST_URL"     // <-- your collector URL
    static let appGroup = "YOUR_APP_GROUP_ID" // <-- your app group id
}
```

### 4. Build and run

Select the **ConnectPushSampleApp** scheme and run on a device or simulator.

---

## Project structure

```
ConnectPushSampleApp/
  App/
    AppDelegate.swift              # SDK init + APNs token forwarding (manual mode)
    ConnectPushSampleApp.swift     # @main SwiftUI entry point
  Services/
    ConnectSDKManager.swift        # SDK lifecycle, authorization, identity
    NotificationDelegate.swift     # UNUserNotificationCenterDelegate (manual mode)
  Scenes/
    PushDemo/
      PushDemoView.swift           # Push authorization UI
      Components/                  # Reusable UI components
    IdentityDemo/
      IdentityDemoView.swift       # Identity logging UI
  Resources/
    Assets.xcassets                # Acoustic brand colours and images

ConnectNSE/                        # Notification Service Extension (rich push)
ConnectNCE/                        # Notification Content Extension (custom UI)
TestPayloads/                      # .apns files for simulator testing
docs/
  integration-guide.md             # Full integration guide
```

---

## Manual vs automatic push mode

The sample app defaults to **manual mode**, where your app handles push
registration and notification callbacks explicitly. This is the more
educational setup because you can see exactly what happens at each step.

To switch to **automatic mode** (SDK handles token registration and callbacks):

1. In `ConnectSDKManager.swift`, follow the inline comments in `start()` to
   swap the `pushConfig`
2. Remove the `UNUserNotificationCenter.delegate` line
3. In `AppDelegate.swift`, remove the token forwarding methods

> **Note:** Both modes still require you to request notification permission from
> the user. See the [Integration Guide](docs/integration-guide.md#9-request-notification-authorization)
> for details.

Both approaches are documented with inline comments in the source code.

---

## Analytics capture

The SDK captures user interactions, screen visits, and screenshots
**automatically** with no additional configuration. This is powered by the
`basicAnalytics` layout default — when no `ConnectLayoutConfig.json` file is
present, the SDK enables sensible defaults for all screens:

- User events (taps, swipes, text changes)
- Screen transition tracking
- Screenshots for session replay
- Default sensitive data masking (digits, letters, symbols)

For per-screen customisation (e.g., disabling capture on specific screens or
adding custom masking rules), add a `ConnectLayoutConfig.json` to your app
bundle. See the [Integration Guide](docs/integration-guide.md#analytics-configuration)
for details.

---

## Testing push notifications in the simulator

Drag any `.apns` file from `TestPayloads/` onto the running simulator to
deliver a test push notification:

| Payload | Action |
|---------|--------|
| `open-app.apns` | Simple notification that opens the app |
| `open-url.apns` | Opens a URL with action buttons |
| `open-dialer.apns` | Opens the phone dialer |
| `rich-push.apns` | Rich notification with image and expanded content |

---

## Documentation

- **[Integration Guide](docs/integration-guide.md)** — Full step-by-step guide
  covering Apple Developer portal setup, SDK installation, push configuration,
  extensions, testing, and troubleshooting

---

## License

Copyright (C) 2026 Acoustic, L.P. All rights reserved.
