//
//  ShopView.swift
//  ADA-CasualGame
//
//  Created by Syamsuddin Putra Riefli on 23/07/25.
//

import SwiftUI
import SpriteKit

struct ShopView: View {
    @State private var coins: Int = 0
    @State private var selectedCostume: String? = "default"
    @State private var purchasedCostumes: [String] = []
    @State private var shopScene: ShopScene = {
        let scene = ShopScene(size: UIScreen.main.bounds.size)
        scene.scaleMode = .resizeFill
        return scene
    }()
    var body: some View {
        ZStack {
            SpriteView(scene: shopScene)
                .ignoresSafeArea()
                .onAppear {
                    shopScene.coinUpdateHandler = { self.coins = $0 }
                    shopScene.costumePurchasedHandler = { self.purchasedCostumes = $0 }
                    shopScene.selectedCostumeHandle = { self.selectedCostume = $0 }
                }
        }
        
        HStack {
            Spacer()
            Text("Shop")
                .font(.title)
            Spacer()
            
            Text("\(coins)")
                .font(.title)
        }
        .padding()
        
        HStack {
            Spacer()
            Button(action: {
                shopScene.buyCostume(costume: "test", price: 9)
            }) {
                Text("Buy")
            }
            Spacer()
        }
        
    }
}

#Preview {
    ShopView()
}
