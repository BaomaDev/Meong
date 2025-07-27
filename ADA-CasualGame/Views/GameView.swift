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
    @State private var highScore: Int = 0

    @State private var showPauseMenu = false
    @State private var showShop = false
    @State private var showSettings = false
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
            
            if gamePhase == .none {
                EmptyView()
            }
            
            if gamePhase == .homeScreen {
                HomeMenu(
                    openShop: { showShop = true },
                    openSettings: { showSettings = true },
                    openLeaderboard: { showSettings = true },
                    openAchievements: { showSettings = true },
                )
            }

            if gamePhase == .playing || gamePhase == .tutorial {
                VStack {
                    ZStack {
                        HStack {
                            Spacer()
                            Text("\(score)")
                                .font(.custom("Comic Lemon", size: 32))
                                .fontWeight(.bold)
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
            }
            
            if showShop {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .transition(.opacity)

                ShopView(isShowing: $showShop, scene: $gameScene)
                    .onAppear {
                        gameScene.scoreUpdateHandler = nil
                        gameScene.coinUpdateHandler = nil
                        gameScene.healthUpdateHandler = nil
                        gameScene.gameStateUpdateHandler = nil
                        gameScene.highscoreUpdateHandler = nil
                    }
                    .onDisappear {
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
            }
            
            if showSettings {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .transition(.opacity)
                
                SettingMenu(isShowing: $showSettings, scene: $gameScene)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .gameDidAutoPause)) { _ in
            if gamePhase != .gameOver {
                pauseGame()
            }
        }
    }
    
    private func pauseGame() {
        if gamePhase == .playing || gamePhase == .tutorial {
            self.showPauseMenu = true
            self.gameScene.pauseGame()
        }
    }
    
    private func showShopUI() {
        if gamePhase == .homeScreen {
            self.showShop = true
        }
    }
}

//#Preview {
//    GameView()
//}
