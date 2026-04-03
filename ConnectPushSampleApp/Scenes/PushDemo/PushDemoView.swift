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
import UserNotifications

struct PushDemoView: View {

    @ObservedObject private var manager = ConnectSDKManager.shared
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                headerView
                authorizationSection
            }
            .padding(.horizontal)
            .padding(.bottom, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color("background"))
        .task {
            await manager.refreshAuthorizationStatus()
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                Task { await manager.refreshAuthorizationStatus() }
            }
        }
    }

    // MARK: - Header

    private var headerView: some View {
        VStack(spacing: 6) {
            Image("logo")
                .resizable()
                .scaledToFit()
                .frame(height: 36)
            Text("Push Demo")
                .font(.title3.bold())
                .foregroundStyle(Color("violet"))
        }
        .padding(.top, 24)
    }

    // MARK: - Authorization section

    private var authorizationSection: some View {
        DemoCard(title: "Notification Authorization") {
            VStack(alignment: .leading, spacing: 14) {
                StatusRow(
                    label: "Status",
                    value: authorizationStatusText,
                    indicatorColor: authorizationIndicatorColor
                )
                Button("Request Authorization") {
                    Task { await manager.requestAuthorization() }
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(manager.authorizationStatus != .notDetermined)
            }
        }
    }

    private var authorizationStatusText: String {
        switch manager.authorizationStatus {
        case .notDetermined: return "Not Requested"
        case .denied: return "Denied"
        case .authorized: return "Authorized"
        case .provisional: return "Provisional"
        case .ephemeral: return "Ephemeral"
        @unknown default: return "Unknown"
        }
    }

    private var authorizationIndicatorColor: Color {
        switch manager.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return Color("acousticGreen")
        case .denied:
            return Color("middleGrey")
        case .notDetermined:
            return Color("middleGrey")
        @unknown default:
            return Color("middleGrey")
        }
    }
}

#Preview {
    PushDemoView()
}
