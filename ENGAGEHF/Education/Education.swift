//
// This source file is part of the ENGAGE-HF project based on the Stanford Spezi Template Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import SpeziContact
import SwiftUI


struct Education: View {
    @Binding var presentingAccount: Bool
    
    
    let contactPI = Contact(
        name: PersonNameComponents(givenName: "Alexander", familyName: "Sandhu"),
        title: "Principal Investigator",
        description: """
        Alex Sandhu, MD, MS is a cardiologist with a special interest in the
        care of patients with advanced heart failure.
        """,
        organization: "Stanford University",
        address: {
            let address = CNMutablePostalAddress()
            address.country = "USA"
            address.state = "CA"
            address.postalCode = "94304"
            address.city = "Palo Alto"
            address.street = "870 Quarry Rd Ext CV 289"
            return address
        }(),
        contactOptions: [
            .call("+1 (650) 723-6459"),
            .text("+1 (650) 723-6459"),
            .email(addresses: ["ats114@stanford.edu"], subject: "ENGAGE-HF Study Inquiry")
        ]
    )
    
    
    var body: some View {
        NavigationStack {
            ContactsList(contacts: [contactPI])
                .navigationTitle("Education")
                .toolbar {
                    if AccountButton.shouldDisplay {
                        AccountButton(isPresented: $presentingAccount)
                    }
                }
        }
    }
}


#if DEBUG
#Preview {
    Education(presentingAccount: .constant(false))
}
#endif
