//
//  PauseMenu.swift
//  ADA-CasualGame
//
//  Created by Derend Marvel Hanson Prionggo on 18/07/25.
//

import SwiftUI

struct PauseMenu: View {
    @Binding var showPauseMenu: Bool
    @Binding var gameScene: GameScene
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Paused")
                .font(.largeTitle)
                .bold()
                .foregroundColor(.white)

            HStack {
                RestartButton(){
                    gameScene.gameOver()
                    showPauseMenu = false
                }
                .padding(2)
                
                PlayButton(){
                    showPauseMenu = false
                    gameScene.resumeGame()
                    gameScene.isPaused = false
                }
                .padding(2)
            }
        }
        .padding(24)
        .cornerRadius(20)
        .padding()
        .transition(.scale)
    }
}

#Preview {
    PauseMenu(
        showPauseMenu: .constant(true),
        gameScene: .constant(GameScene(size: CGSize(width: 100, height: 100)))
    )
}
