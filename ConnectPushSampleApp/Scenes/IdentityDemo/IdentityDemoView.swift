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
import SwiftUI

struct IdentityDemoView: View {

    @ObservedObject private var manager = ConnectSDKManager.shared

    @State private var identifierName: String = ""
    @State private var identifierValue: String = ""

    private var canLog: Bool {
        !identifierName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !identifierValue.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                headerView
                resultSection
                inputCard
                if manager.identityHistory.contains(where: { !$0.name.isEmpty && !$0.value.isEmpty }) {
                    recentsCard
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color("background"))
    }

    // MARK: - Header

    private var headerView: some View {
        VStack(spacing: 6) {
            Image("logo")
                .resizable()
                .scaledToFit()
                .frame(height: 36)
            Text("Identity Demo")
                .font(.title3.bold())
                .foregroundStyle(Color("violet"))
        }
        .padding(.top, 24)
    }

    // MARK: - Input card

    private var inputCard: some View {
        DemoCard(title: "Log Identity") {
            VStack(alignment: .leading, spacing: 10) {
                DemoTextField(
                    label: "Identifier Name",
                    placeholder: "Email Address",
                    text: $identifierName
                )
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)

                DemoTextField(
                    label: "Identifier Value",
                    placeholder: "user@example.com",
                    text: $identifierValue
                )
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)

                Button("Log Identity") {
                    manager.logIdentity(name: identifierName, value: identifierValue)
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(!canLog)
            }
        }
    }

    // MARK: - Recents card

    private var recentsCard: some View {
        let items = manager.identityHistory.filter { !$0.name.isEmpty && !$0.value.isEmpty }
        return DemoCard(title: "Recent") {
            VStack(spacing: 0) {
                ForEach(items) { pair in
                    Button {
                        identifierName = pair.name
                        identifierValue = pair.value
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(pair.name)
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(Color("violet"))
                                Text(pair.value)
                                    .font(.caption)
                                    .foregroundStyle(Color("darkGrey"))
                            }
                            Spacer()
                            Image(systemName: "arrow.up.left")
                                .font(.caption)
                                .foregroundStyle(Color("middleGrey"))
                        }
                        .padding(.vertical, 10)
                    }
                    .buttonStyle(.plain)

                    if pair != items.last {
                        Divider()
                            .background(Color("lightGrey"))
                    }
                }
            }
        }
    }

    // MARK: - Result section

    @ViewBuilder
    private var resultSection: some View {
        if let result = manager.identityLogResult {
            DemoCard(title: "Last Result") {
                Text(result)
                    .font(.subheadline)
                    .foregroundStyle(Color("darkGrey"))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

#Preview {
    IdentityDemoView()
}
