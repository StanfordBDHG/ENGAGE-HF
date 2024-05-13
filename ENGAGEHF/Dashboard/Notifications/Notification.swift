//
// This source file is part of the ENGAGE-HF project based on the Stanford Spezi Template Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import Foundation


// A notification
//
// Mirrors the representation of a notification in firestore
// When assigned to a patient, the title will be displayed
// and the description will be displayed in a drop-down field
//
// Title and Descprition may be markdown text
struct Notification: Identifiable {
    var id: String
    
    var title: String
    var description: String
    
    var completed = false
    
    init(title: String, description: String, id: String) {
        self.id = id
        self.title = title
        self.description = description
    }
}
