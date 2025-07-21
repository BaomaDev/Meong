//
//  GameView.swift
//  ADA-CasualGame
//
//  Created by Derend Marvel Hanson Prionggo on 16/07/25.
//

import SwiftUI
import SpriteKit

struct GameView: View {
    @State private var score: Int = 0
    @State private var coin: Int = 0
    @State private var health: Int = 9

    @State private var showPauseMenu = false
    @State private var gameScene: GameScene = {
        let scene = GameScene(size: UIScreen.main.bounds.size)
        scene.scaleMode = .resizeFill
        return scene
    }()

    var body: some View {
        ZStack {
            ZStack(alignment: .topTrailing) {
                SpriteView(scene: gameScene)
                    .ignoresSafeArea()
                
                // Update handlers (moved here to avoid re-initializing GameScene)
                .onAppear {
                    gameScene.scoreUpdateHandler = { newScore in
                        DispatchQueue.main.async { self.score = newScore }
                    }
                    gameScene.coinUpdateHandler = { newCoin in
                        DispatchQueue.main.async { self.coin = newCoin }
                    }
                    gameScene.healthUpdateHandler = { newHealth in
                        DispatchQueue.main.async { self.health = newHealth }
                    }
                }

                HStack {
                    HStack {
                        HealthBar(health: health)
                        CoinIndicator(coinCount: coin)
                    }
                    Spacer()
                }
                .padding(.top, 15)

                HStack {
                    Spacer()
                    Text("\(score)")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                        .shadow(radius: 3)
                    Spacer()
                }
                .padding(.top, 24)

                HStack {
                    PauseButton {
                        showPauseMenu = true
                        gameScene.pauseGame()
                        gameScene.isPaused = true
                    }
                }
                .padding(.top, 24)
            }

            if showPauseMenu {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .transition(.opacity)

                PauseMenu(showPauseMenu: $showPauseMenu, gameScene: $gameScene)
            }
        }
    }
}

#Preview {
    GameView()
}
