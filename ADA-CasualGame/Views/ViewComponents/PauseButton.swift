//
//  PauseButton.swift
//  ADA-CasualGame
//
//  Created by Derend Marvel Hanson Prionggo on 17/07/25.
//

import SwiftUI

struct PauseButton: View {
    var onPause: () -> Void
    var body: some View {
        Button(action: {
            onPause()
        }) {
            Image("PauseButton")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 50)
        }
    }
}

#Preview {
    PauseButton(onPause: {})
}
