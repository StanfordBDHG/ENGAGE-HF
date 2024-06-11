//
// This source file is part of the ENGAGE-HF project based on the Stanford Spezi Template Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import FirebaseAuth
import FirebaseFirestore
import Foundation
import OSLog
import Spezi
import SpeziFirebaseConfiguration


//
// Notification manager
//
// Maintains a list of Notifications associated with the current user in firebase
// On configuration of the app, adds a snapshot listener to the user's notification collection
//
@Observable
class NotificationManager: Module, EnvironmentAccessible {
    @ObservationIgnored @Dependency private var configureFirebaseApp: ConfigureFirebaseApp
    @ObservationIgnored @StandardActor var standard: ENGAGEHFStandard
    
    private var authStateDidChangeListenerHandle: AuthStateDidChangeListenerHandle?
    private var snapshotListener: ListenerRegistration?
    
    private let logger = Logger(subsystem: "ENGAGEHF", category: "NotificationManager")
    
    private let expirationDate = 10
    
    var notifications: [Notification] = []
    
    
    func configure() {
        if ProcessInfo.processInfo.isPreviewSimulator {
            let dummyNotification = Notification(
                id: String(describing: UUID()),
                type: "Mock Notification",
                title: "Weight Recorded",
                description: "A weight measurement has been recorded."
            )
            notifications.append(dummyNotification)
            return
        }
        
        authStateDidChangeListenerHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.registerSnapshotListener(user: user)
            
            // If testing, add 3 notifications to firestore
            if FeatureFlags.setupTestEnvironment, user != nil {
                for notification_num in 1...3 {
                    let newNotification = Notification(
                        type: "Mock Notification \(notification_num)",
                        title: "This is a mock notification.",
                        description: "This is a long string that should be truncated by the expandable text class."
                    )
                    Task {
                        await standard.add(notification: newNotification)
                    }
                }
            }
        }
        self.registerSnapshotListener(user: Auth.auth().currentUser)
    }
    
    // Call on initialization
    //
    // Creates a snapshot listener to save new notifications to the manager
    // as they are added to the user's directory in Firebase
    func registerSnapshotListener(user: User?) {
        logger.info("Initializing notifiation snapshot listener...")
        
        // Remove previous snapshot listener for the user before creating new one
        snapshotListener?.remove()
        guard let uid = user?.uid else {
            return
        }
        
        let firestore = Firestore.firestore()
        
        // Ignore notifications older than expirationDate
        guard let thresholdDate = Calendar.current.date(byAdding: .day, value: -expirationDate, to: .now) else {
            logger.error("Unable to get threshold date: \(FetchingError.invalidTimestamp)")
            return
        }
        
        let thesholdTimeStamp = Timestamp(date: thresholdDate)
        
        // Set a snapshot listener on the query for valid notifications
        firestore.collection("users")
            .document(uid)
            .collection("notifications")
            .whereField("created", isGreaterThan: thesholdTimeStamp)
            .whereField("completed", isEqualTo: false)
            .addSnapshotListener { querySnapshot, error in
                guard let documentRefs = querySnapshot?.documents else {
                    self.logger.error("Error fetching documents: \(error)")
                    return
                }
                
                self.notifications = documentRefs.compactMap {
                    do {
                        return try $0.data(as: Notification.self)
                    } catch {
                        self.logger.error("Error decoding notifications: \(error)")
                        return nil
                    }
                }
                
                self.logger.debug("Notifications updated")
            }
    }
    
    func markComplete(id: String) async {
        if ProcessInfo.processInfo.isPreviewSimulator {
            notifications.removeAll { $0.id == id }
            return
        }
        
        logger.debug("Marking notitification complete with the following id: \(id)")
        
        let firestore = Firestore.firestore()
        
        guard let user = Auth.auth().currentUser else {
            logger.error("Unable to mark notitificaitons complete: \(FetchingError.userNotAuthenticated)")
            return
        }
        
        // Mark the notifications as completed in the Firestore
        let timestamp = Timestamp(date: .now)

        let docRef = firestore.collection("users")
            .document(user.uid)
            .collection("notifications")
            .document(id)
        
        do {
            try await docRef.updateData([
                "completed": timestamp
            ])
        } catch {
            logger.error("Unable to update notification \(id): \(error)")
        }
        
        logger.debug("Successfully marked notifications complete!")
    }
}


extension NotificationManager {
    // Function for adding a mock notification for the preview simulator
    func addMock() {
        let dummyNotification = Notification(
            id: String(describing: UUID()),
            type: "Medication Change",
            title: "Your dose of XXX was changed.",
            description: "Your dose of XXX was changed. You can review medication information in the Education Page."
        )
        notifications.append(dummyNotification)
    }
}
