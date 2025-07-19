//
//  RestartButton.swift
//  ADA-CasualGame
//
//  Created by Derend Marvel Hanson Prionggo on 18/07/25.
//

import SwiftUI

struct RestartButton: View {
    var restart: () -> Void
    var body: some View {
        Button(action: {
            restart()
        }) {
            Image("RestartButton")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 75)
        }
    }
}

#Preview {
    RestartButton(restart: {})
}
