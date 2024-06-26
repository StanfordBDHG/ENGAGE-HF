//
// This source file is part of the ENGAGE-HF project based on the Stanford Spezi Template Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//
// Based on:
// https://stackoverflow.com/questions/59485532/swiftui-how-know-number-of-lines-in-text/75827200#75827200
//

import SwiftUI


struct ExpandableText: View {
    private enum TruncatedState {
        case isTruncated
        case notTruncated
        case unknown
    }
    
    
    let text: String
    let lineLimit: Int
    
    @ScaledMetric private var spacing: CGFloat = 4
    @State private var isExpanded = false
    @State private var isTruncated: TruncatedState = .unknown
    
    
    var body: some View {
        VStack(alignment: .leading, spacing: spacing) {
            Text(text)
                .lineLimit(isExpanded ? nil : lineLimit)
                .background(calculateTruncation(text: text))
                
            if isTruncated == .isTruncated {
                ShowMoreButton(isExpanded: $isExpanded)
            }
        }
            .multilineTextAlignment(.leading)
            // Re-calculate isTruncated for the new text
            .onChange(of: text) { isTruncated = .unknown }
            .onDisappear { isExpanded = false }
    }
    
    
    private func calculateTruncation(text: String) -> some View {
        // Select the view that fits in the background of the line-limited text.
        ViewThatFits(in: .vertical) {
            Text(text)
                .hidden()
                .onAppear {
                    // If the whole text fits, then isTruncated is set to false and no button is shown.
                    guard isTruncated == .unknown else {
                        return
                    }
                    isTruncated = .notTruncated
                }
            Color(.clear)
                .hidden()
                .onAppear {
                    // If the whole text does not fit, Color.clear is selected,
                    // isTruncated is set to true and button is shown.
                    guard isTruncated == .unknown else {
                        return
                    }
                    isTruncated = .isTruncated
                }
        }
    }
}


#Preview {
    let sampleText = "Your dose of XXX was changed. You can review medication information in the Education Page."
    return ExpandableText(text: sampleText, lineLimit: 1)
}
