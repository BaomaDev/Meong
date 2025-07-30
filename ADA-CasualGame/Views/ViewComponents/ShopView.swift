//
//  ShopView.swift
//  ADA-CasualGame
//
//  Created by Syamsuddin Putra Riefli on 23/07/25.
//

import SwiftUI
import SpriteKit

struct ShopView: View {
    @Binding var isShowing: Bool
    @State private var coins: Int = 0
    @State private var selectedCostume: String? = "costume_default"
    @State private var purchasedCostumes: [String] = []
    @Binding var scene: GameScene
    var body: some View {
        ZStack {
            Image("UI_Box")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 700)
            VStack (spacing: 40){
                ZStack {
                    HStack {
                        Spacer()
                        Image("ShopBanner")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 200)
                            .padding(.top, -50)
                        Spacer()
                    }
                    
                    HStack {
                        HStack {
                            Button(action: {
                                isShowing = false // 👈 close shop
                            }){
                                Image("CloseButton")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 50)
                                    .padding(.leading, 15)
                                    .padding(.top, 20)
                            }
                            .padding(2)
                            
                            Spacer()
                            
                            CoinIndicator(coinCount: coins)
                                .padding(.trailing, 15)
                                .padding(.top, 20)
                        }
                        .padding(.top, 10)
                    }
                }
                .padding(.horizontal)
                .padding(.top, -90)
                
                ZStack {
                    HStack(spacing: 20) {
                        ZStack {
                            Image("ShopCard")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 170)
                            
                            VStack (spacing: 12) {
                                Image("cat")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 100)
                                Text("Oyen")
                                    .font(.custom("Comic Lemon", size: 18))
                                    .foregroundStyle(.black)
                                Text("Owned")
                                    .font(.custom("Comic Lemon", size: 12))
                                    .foregroundStyle(.black)
                                    .padding(.bottom, 10)
                                if selectedCostume != "costume_default" {
                                    Button(action: {
                                        scene.selectCostume("costume_default")
                                    }){
                                        Image("EquipButton")
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 100)
                                    }
                                } else {
                                    Text("Selected")
                                        .font(.custom("Comic Lemon", size: 20))
                                        .foregroundStyle(.black)
                                        .padding(.bottom, 10)
                                }
                            }
                        }
                        
                        ZStack {
                            Image("ShopCard")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 170)
                            
                            VStack (spacing: 12) {
                                Image("cat")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 100)
                                Text("Kitter")
                                    .font(.custom("Comic Lemon", size: 18))
                                    .foregroundStyle(.black)
                                if !purchasedCostumes.contains("costume_kitter") {
                                    Text("1000 Coins")
                                        .font(.custom("Comic Lemon", size: 12))
                                        .foregroundStyle(.black)
                                    Button(action: {
                                        scene.buyCostume(costume: "costume_kitter", price: 1000)
                                    }){
                                        Image("BuyButton")
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 100)
                                    }
                                } else {
                                    Text("Owned")
                                        .font(.custom("Comic Lemon", size: 12))
                                        .foregroundStyle(.black)
                                        .padding(.bottom, 10)
                                    if selectedCostume != "costume_kitter" {
                                        Button(action: {
                                            scene.selectCostume("costume_kitter")
                                        }){
                                            Image("EquipButton")
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                                .frame(width: 100)
                                        }
                                    } else {
                                        Text("Selected")
                                            .font(.custom("Comic Lemon", size: 20))
                                            .foregroundStyle(.black)
                                            .padding(.bottom, 10)
                                    }
                                }
                            }
                        }
                        
                        ZStack {
                            Image("ShopCard")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 170)
                            
                            VStack (spacing: 12) {
                                Image("cat")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 100)
                                Text("Butler")
                                    .font(.custom("Comic Lemon", size: 18))
                                    .foregroundStyle(.black)
                                if !purchasedCostumes.contains("costume_butler") {
                                    Text("1000 Coins")
                                        .font(.custom("Comic Lemon", size: 12))
                                        .foregroundStyle(.black)
                                    Button(action: {
                                        scene.buyCostume(costume: "costume_butler", price: 1000)
                                    }){
                                        Image("BuyButton")
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 100)
                                    }
                                } else {
                                    Text("Owned")
                                        .font(.custom("Comic Lemon", size: 12))
                                        .foregroundStyle(.black)
                                        .padding(.bottom, 10)
                                    if selectedCostume != "costume_butler" {
                                        Button(action: {
                                            scene.selectCostume("costume_butler")
                                        }){
                                            Image("EquipButton")
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                                .frame(width: 100)
                                        }
                                    } else {
                                        Text("Selected")
                                            .font(.custom("Comic Lemon", size: 20))
                                            .foregroundStyle(.black)
                                            .padding(.bottom, 10)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.top, -30)
            }
            .padding(.top, 60)
        }
        .padding(.top, 20)
        .padding(.leading, 20)
        .onAppear{
            print("Opening ShopView")
            DispatchQueue.main.async {
                coins = SaveManager.shared.playerData.coins
                purchasedCostumes = SaveManager.shared.playerData.unlockedCostumes
                selectedCostume = SaveManager.shared.playerData.selectedCostume
            }
            scene.coinUpdateHandler = { self.coins = $0 }
            scene.selectedCostumeHandler = { self.selectedCostume = $0 }
            scene.costumePurchasedHandler = { self.purchasedCostumes = $0 }
        }
        .onDisappear{
            print("Closed ShopView")
            scene.savePlayerData()
            scene.coinUpdateHandler = nil
            scene.selectedCostumeHandler = nil
            scene.costumePurchasedHandler = nil
        }
    }
}

//#Preview {
//    ShopView(isShowing: .constant(true))
//}

