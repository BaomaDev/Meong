//
//  PlayButton.swift
//  ADA-CasualGame
//
//  Created by Derend Marvel Hanson Prionggo on 18/07/25.
//

import SwiftUI

struct PlayButton: View {
    var play: () -> Void
    var body: some View {
        Button(action: {
            play()
        }) {
            Image("PlayButton")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 75)
        }
    }
}

#Preview {
    PlayButton(play: {})
}
