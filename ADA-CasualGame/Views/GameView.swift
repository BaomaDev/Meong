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
<<<<<<< Updated upstream
    
    var scene: SKScene {
        let gameScene = GameScene(size: UIScreen.main.bounds.size)
        gameScene.scaleMode = .resizeFill
        gameScene.scoreUpdateHandler = { newScore in
            DispatchQueue.main.async {
                self.score = newScore
=======
    @State private var highScore: Int = 0

    @State private var showPauseMenu = false
    @State private var gameScene: GameScene = {
        let scene = GameScene(size: UIScreen.main.bounds.size)
        scene.scaleMode = .resizeFill
        return scene
    }()
    @State private var gamePhase: GamePhase = .homeScreen

    var body: some View {
        ZStack {
            SpriteView(scene: gameScene)
                .ignoresSafeArea()
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
                    gameScene.gameStateUpdateHandler = { self.gamePhase = $0 }
                    gameScene.highscoreUpdateHandler = { self.highScore = $0 }
                }

            if gamePhase == .playing || gamePhase == .tutorial {
                VStack {
                    ZStack {
                        HStack {
                            Spacer()
                            Text("\(score)")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.white)
                                .shadow(radius: 3)
                            Spacer()
                        }
                        
                        HStack {
                            HStack {
                                HealthBar(health: health)
                                CoinIndicator(coinCount: coin)
                            }
                            
                            Spacer()
                            
                            PauseButton {
                                pauseGame()
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 15)
                    
                    Spacer()
                }
            }
            
            if gamePhase == .homeScreen {
               EmptyView()
            }
            
            if gamePhase == .none {
                EmptyView()
            }

            if showPauseMenu {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .transition(.opacity)

                PauseMenu(showPauseMenu: $showPauseMenu, gameScene: $gameScene)
            } else if gamePhase == .gameOver {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .transition(.opacity)
                
                GameoverView(
                    scoreCount: score,
                    highscoreCount: highScore,
                    onRestart: {
                        gameScene.restart()
                    },
                    onGoHome: {
                        gameScene.returnToHomeScreen()
                    }
                )
>>>>>>> Stashed changes
            }
        }
        
        gameScene.coinUpdateHandler = { newCoin in
            DispatchQueue.main.async {
                    self.coin = newCoin
            }
        }
        
        gameScene.healthUpdateHandler = { newHealth in
            DispatchQueue.main.async {
                self.health = newHealth
            }
        }
        return gameScene
    }
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            SpriteView(scene: scene)
                .ignoresSafeArea()
            HStack{
                HStack{
                    HealthBar(health: health)
                    CoinIndicator(coinCount: coin)
                }
                Spacer()
            }
            .padding(.top, 15)
            HStack{
                Spacer()
                HStack{
                    Text("\(score)")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                        .shadow(radius: 3)
                        .padding(.bottom, 0)
                }
                Spacer()
            }
            .padding(.top, 24)
            
            HStack{
                PauseButton()
            }
            .padding(.top, 24)
            
        }
    }
}

#Preview {
    GameView()
}
