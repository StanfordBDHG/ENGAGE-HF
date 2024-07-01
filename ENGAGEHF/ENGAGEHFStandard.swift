//
// This source file is part of the ENGAGE-HF project based on the Stanford Spezi Template Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import FirebaseFirestore
import FirebaseStorage
import HealthKitOnFHIR
import OSLog
import PDFKit
import Spezi
import SpeziAccount
import SpeziDevices
import SpeziFirebaseAccountStorage
import SpeziFirestore
import SpeziHealthKit
import SpeziOnboarding
import SpeziQuestionnaire
import SwiftUI


actor ENGAGEHFStandard: Standard, EnvironmentAccessible, OnboardingConstraint, AccountStorageConstraint {
    enum ENGAGEHFStandardError: Error {
        case userNotAuthenticatedYet
        case invalidHKSampleType
    }

    private static var userCollection: CollectionReference {
        Firestore.firestore().collection("users")
    }

    @Dependency var accountStorage: FirestoreAccountStorage?

    @AccountReference var account: Account

    private let logger = Logger(subsystem: "ENGAGEHF", category: "Standard")
    
    
    private var userDocumentReference: DocumentReference {
        get async throws {
            guard let details = await account.details else {
                throw ENGAGEHFStandardError.userNotAuthenticatedYet
            }

            return Self.userCollection.document(details.accountId)
        }
    }
    
    private var userBucketReference: StorageReference {
        get async throws {
            guard let details = await account.details else {
                throw ENGAGEHFStandardError.userNotAuthenticatedYet
            }

            return Storage.storage().reference().child("users/\(details.accountId)")
        }
    }


    init() {
        if !FeatureFlags.disableFirebase {
            _accountStorage = Dependency(wrappedValue: FirestoreAccountStorage(storeIn: ENGAGEHFStandard.userCollection))
        }
    }


    func addMeasurement(samples: [HKSample]) async throws {
        guard !samples.isEmpty else {
            return
        }

        logger.debug("Saving \(samples.count) samples to firestore ...")
        let userDocument = try await userDocumentReference

        do {
            let batch = Firestore.firestore().batch()
            for sample in samples {
                do {
                    let document = try healthKitDocument(for: userDocument, id: sample.id, type: sample.sampleType)
                    try batch.setData(from: sample.resource, forDocument: document)
                } catch {
                    // either document retrieval or encoding failed, this should not stop other samples from getting saved
                    logger.debug("Failed to store sample in firebase, discarding: \(sample)")
                }
            }

            try await batch.commit()
        } catch {
            throw FirestoreError(error)
        }
    }
    
    
    func add(notification: Notification) async {
        do {
            let userDoc = try await userDocumentReference
            try userDoc.collection("notifications").addDocument(from: notification)
        } catch {
            logger.error("Could not store the notification: \(error)")
        }
    }
    
    
    func add(response: ModelsR4.QuestionnaireResponse) async {
        let id = response.identifier?.value?.value?.string ?? UUID().uuidString
        
        do {
            try await userDocumentReference
                .collection("QuestionnaireResponse") // Add all HealthKit sources in a /QuestionnaireResponse collection.
                .document(id) // Set the document identifier to the id of the response.
                .setData(from: response)
        } catch {
            logger.error("Could not store questionnaire response: \(error)")
        }
    }
    

    private func healthKitDocument(for user: DocumentReference, id uuid: UUID, type: HKSampleType) throws -> DocumentReference {
        var collectionBucket: String? {
            switch type {
            case HKQuantityType(.bodyMass):
                return "bodyWeightObservations"
            case HKQuantityType(.bodyMassIndex):
                return "bodyMassIndexObservations"
            case HKQuantityType(.height):
                return "heightObservations"
            case HKQuantityType(.heartRate):
                return "heartRateObservations"
            case HKCorrelationType(.bloodPressure):
                return "bloodPressureObservations"
            default:
                return nil
            }
        }
        
        guard let collectionBucket else {
            throw ENGAGEHFStandardError.invalidHKSampleType
        }
        
        return user
            .collection(collectionBucket)
            .document(uuid.uuidString) // Set the document identifier to the UUID of the document.
    }

    func deletedAccount() async throws {
        // delete all user associated data
        do {
            try await userDocumentReference.delete()
        } catch {
            logger.error("Could not delete user document: \(error)")
        }
    }
    
    /// Stores the given consent form in the user's document directory with a unique timestamped filename.
    ///
    /// - Parameter consent: The consent form's data to be stored as a `PDFDocument`.
    func store(consent: PDFDocument) async {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HHmmss"
        let dateString = formatter.string(from: Date())
        
        guard !FeatureFlags.disableFirebase else {
            guard let basePath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
                logger.error("Could not create path for writing consent form to user document directory.")
                return
            }
            
            let filePath = basePath.appending(path: "consentForm_\(dateString).pdf")
            consent.write(to: filePath)
            
            return
        }
        
        do {
            guard let consentData = consent.dataRepresentation() else {
                logger.error("Could not store consent form.")
                return
            }
            
            let metadata = StorageMetadata()
            metadata.contentType = "application/pdf"
            _ = try await userBucketReference.child("consent/\(dateString).pdf").putDataAsync(consentData, metadata: metadata)
        } catch {
            logger.error("Could not store consent form: \(error)")
        }
    }


    func create(_ identifier: AdditionalRecordId, _ details: SignupDetails) async throws {
        guard let accountStorage else {
            preconditionFailure("Account Storage was requested although not enabled in current configuration.")
        }
        try await accountStorage.create(identifier, details)
    }

    func load(_ identifier: AdditionalRecordId, _ keys: [any AccountKey.Type]) async throws -> PartialAccountDetails {
        guard let accountStorage else {
            preconditionFailure("Account Storage was requested although not enabled in current configuration.")
        }
        return try await accountStorage.load(identifier, keys)
    }

    func modify(_ identifier: AdditionalRecordId, _ modifications: AccountModifications) async throws {
        guard let accountStorage else {
            preconditionFailure("Account Storage was requested although not enabled in current configuration.")
        }
        try await accountStorage.modify(identifier, modifications)
    }

    func clear(_ identifier: AdditionalRecordId) async {
        guard let accountStorage else {
            preconditionFailure("Account Storage was requested although not enabled in current configuration.")
        }
        await accountStorage.clear(identifier)
    }

    func delete(_ identifier: AdditionalRecordId) async throws {
        guard let accountStorage else {
            preconditionFailure("Account Storage was requested although not enabled in current configuration.")
        }
        try await accountStorage.delete(identifier)
    }
}
