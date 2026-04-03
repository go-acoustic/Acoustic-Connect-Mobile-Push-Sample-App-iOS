//
// Copyright (C) 2026 Acoustic, L.P. All rights reserved.
//
// Licensed under the Acoustic License (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy
// at https://www.acoustic.com/licenses/acoustic-license
//
// Sample app provided "as is", without warranty of any kind.
//

import SwiftUI

@main
struct ConnectPushSampleApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            TabView {
                PushDemoView()
                    .tabItem {
                        Label("Push", systemImage: "bell")
                    }
                IdentityDemoView()
                    .tabItem {
                        Label("Identity", systemImage: "person.crop.circle")
                    }
            }
            .tint(Color("periwinkle"))
        }
    }
}
