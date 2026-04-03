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

// MARK: - PrimaryButtonStyle

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.bold())
            .foregroundStyle(Color.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                Color("periwinkle")
                    .opacity(configuration.isPressed ? 0.75 : 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - SecondaryButtonStyle

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.bold())
            .foregroundStyle(Color.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                Color("darkGrey")
                    .opacity(configuration.isPressed ? 0.75 : 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
