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
        ZStack {
            Image("GameOver")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 600)
            VStack(spacing: 20) {
//                Text("Game Over")
//                    .font(.custom("Comic Lemon", size: 36))
//                    .font(.largeTitle)
//                    .bold()
//                    .foregroundColor(.orange)
                
                Text("Score: \(scoreCount)")
                    .font(.custom("Comic Lemon", size: 27))
                    .font(.title)
                    .foregroundColor(.orange)
                    .padding(.vertical, -4)
                
                Text("Highscore: \(highscoreCount)")
                    .font(.custom("Comic Lemon", size: 18))
                    .font(.title2)
                    .foregroundColor(.black)
                    .padding(.vertical, -4)
                
                HStack() {
                    RestartButton() {
                        onRestart()
                    }
                    .padding(2)
                    
                    Button(action: {
                        onGoHome()
                    }) {
                        Image("HomeButton")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 75)
                            .padding(10)
                            .background(Color.white.opacity(0.3))
                            .foregroundColor(.blue)
                            .clipShape(Circle())
                    }
                }
                .padding(.top, -10)
            }
            .padding(.top, 40)
            .padding(.leading, 90)
            .transition(.scale)
        }
        .padding(.top, 30)
    }
}

#Preview {
    ZStack {
        GameoverView(scoreCount: 201, highscoreCount: 200, onRestart: {}, onGoHome: {})
    }
}
