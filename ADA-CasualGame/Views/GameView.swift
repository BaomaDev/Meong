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
    
    var scene: SKScene {
        let gameScene = GameScene(size: UIScreen.main.bounds.size)
        gameScene.scaleMode = .resizeFill
        gameScene.scoreUpdateHandler = { newScore in
            DispatchQueue.main.async {
                self.score = newScore
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
