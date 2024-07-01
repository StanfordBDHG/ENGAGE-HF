//
// This source file is part of the ENGAGE-HF project based on the Stanford Spezi Template Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

#if DEBUG || TEST
@_spi(TestingSupport)
#endif
import SpeziDevices
import SwiftUI


struct Dashboard: View {
    @Binding var presentingAccount: Bool
    
#if DEBUG || TEST
    @Environment(HealthMeasurements.self) private var measurements
#endif

    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 20) {
                    // Notifications
                    NotificationSection()
                    
                    // Most recent vitals
                    RecentVitalsSection()
                }
                .padding()
            }
                .background(Color(.systemGroupedBackground))
                .navigationTitle("Home")
                .toolbar {
                    if AccountButton.shouldDisplay {
                        AccountButton(isPresented: $presentingAccount)
                    }
                }
#if DEBUG || TEST
                .toolbar {
                    if FeatureFlags.testMockDevices {
                        ToolbarItemGroup(placement: .secondaryAction) {
                            Button("Trigger Weight Measurement", systemImage: "scalemass.fill") {
                                measurements.loadMockWeightMeasurement()
                            }
                            Button("Trigger Blood Pressure Measurement", systemImage: "drop.fill") {
                                measurements.loadMockBloodPressureMeasurement()
                            }
                            Button("Show Measurements", systemImage: "heart.text.square") {
                                measurements.shouldPresentMeasurements = true
                            }
                        }
                    }
                }
#endif
        }
    }
}


#if DEBUG
#Preview {
    Dashboard(presentingAccount: .constant(false))
        .previewWith(standard: ENGAGEHFStandard()) {
            NotificationManager()
            HealthMeasurements()
            VitalsManager()
        }
}
#endif
