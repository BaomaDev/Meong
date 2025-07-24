//
//  GameoverView.swift
//  ADA-CasualGame
//
//  Created by Jesse Robinson Junior Simanjuntak on 24/07/25.
//


//
//  GameoverView.swift
//  ADA-CasualGame
//
//  Created by Jesse Robinson Junior Simanjuntak on 24/07/25.
//

import SwiftUI

struct GameoverView: View {
    let scoreCount: Int
    let highscoreCount: Int
    var onRestart: () -> Void
    var onGoHome: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("Game Over")
                .font(.largeTitle)
                .bold()
                .foregroundColor(.white)

            Text("Score: \(scoreCount)")
                .font(.title)
                .foregroundColor(.white)
            
            Text("Highscore: \(highscoreCount)")
                .font(.title2)
                .foregroundColor(.white)

            HStack(spacing: 30) {
                RestartButton() {
                    onRestart()
                }
                .padding(2)

                Button(action: {
                    onGoHome()
                }) {
                    Image(systemName: "house.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 55, height: 55)
                        .padding(10)
                        .background(Color.white.opacity(0.3))
                        .foregroundColor(.white)
                        .clipShape(Circle())
                }
                .padding(2)
            }
        }
        .padding(30)
        .background(Material.ultraThinMaterial)
        .cornerRadius(20)
        .padding()
        .transition(.scale)
    }
}

#Preview {
    ZStack {
        Color.blue.ignoresSafeArea()
        GameoverView(scoreCount: 201, highscoreCount: 200, onRestart: {}, onGoHome: {})
    }
}
