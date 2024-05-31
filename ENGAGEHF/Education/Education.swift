//
// This source file is part of the ENGAGE-HF project based on the Stanford Spezi Template Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import SwiftUI


struct Education: View {
    @Binding var presentingAccount: Bool
    
    
    var body: some View {
        VStack {
            Text("Introductory Videos go here")
        }
    }
}

#Preview {
    Education(presentingAccount: .constant(false))
}