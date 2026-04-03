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

struct DemoTextField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    var isDisabled: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(isDisabled ? Color("middleGrey") : Color("darkGrey"))
            TextField(placeholder, text: $text)
                .font(.system(.subheadline, design: .monospaced))
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .disabled(isDisabled)
                .padding(10)
                .background(isDisabled ? Color("lightGrey").opacity(0.5) : Color("lightGrey"))
                .foregroundStyle(isDisabled ? Color("middleGrey") : Color("violet"))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color("middleGrey"), lineWidth: 1)
                )
        }
    }
}
