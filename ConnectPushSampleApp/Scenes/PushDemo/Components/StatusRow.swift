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

struct StatusRow: View {
    let label: String
    let value: String
    let indicatorColor: Color

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(indicatorColor)
                .frame(width: 9, height: 9)
            Text(label + ":")
                .font(.subheadline)
                .foregroundStyle(Color("darkGrey"))
            Text(value)
                .font(.subheadline.bold())
                .foregroundStyle(Color("darkGrey"))
        }
    }
}
