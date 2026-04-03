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

// NSExtension principal class — referenced by NSExtensionPrincipalClass in Info.plist.
// @unchecked Sendable: restates inherited conformance from ConnectNotificationService.
final class NotificationService: ConnectNotificationService, @unchecked Sendable {
    override var appGroupIdentifier: String? {
        "YOUR_APP_GROUP"
    }
}
