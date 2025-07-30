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
                .frame(width: UIBoxWidth)
            
            VStack {
                ZStack {
                    HStack {
                        Spacer()
                        Image("ShopBanner")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 200)
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
                            
                            ZStack {
                                Image("UI_Coins")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(maxWidth: 120)
                                Text("\(coins)")
                                    .font(.custom("Comic Lemon", size: 18))
                                    .foregroundColor(.white)
                                    .padding(.top, 5)
                                    .padding(.leading, 50)
                                    .frame(maxWidth: 110, alignment: .leading)
                            }
                            .padding(.top, 20)
                            .padding(.trailing, 15)
                        }
                        .padding(.top, 10)
                    }
                }
                .padding(.horizontal)
                .padding(.top, -90)
                
                HStack(spacing: 20) {
                    ZStack {
                        Image("ShopCard")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 150)
                        
                        VStack (spacing: 12) {
                            Text("Oyen")
                                .font(.custom("Comic Lemon", size: 18))
                                .foregroundColor(Color(CGColor(red: 150/255, green: 85/255, blue: 45/255, alpha: 1)))
                            Spacer()
                            Image("cat")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 100)
                            Spacer()
                            if selectedCostume != "costume_default" {
                                Button(action: {
                                    scene.selectCostume("costume_default")
                                }){
                                    Image("Shop_ButtonEquip")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 100)
                                }
                            } else {
                                Image("Shop_ButtonEquipped")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 100)
                            }
                        }
                        .frame(maxWidth: 150, maxHeight: 170)
                    }
                    
                    ZStack {
                        Image("ShopCard")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 150)
                        
                        VStack (spacing: 12) {
                            Text("Si Putih")
                                .font(.custom("Comic Lemon", size: 18))
                                .foregroundColor(Color(CGColor(red: 150/255, green: 85/255, blue: 45/255, alpha: 1)))
                            Spacer()
                            Image("Shop_SkinPutih")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 100)
                            Spacer()
                            if !purchasedCostumes.contains("costume_siputih") {
                                if coins >= 250 {
                                    Button(action: {
                                        scene.buyCostume(costume: "costume_siputih", price: 250)
                                    }){
                                        ZStack {
                                            Image("Shop_ButtonBuy")
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                                .frame(width: 100)
                                            Text("250")
                                                .font(.custom("Comic Lemon", size: 18))
                                                .foregroundStyle(.white)
                                                .padding(.leading, 10)
                                        }
                                    }
                                } else {
                                    Button(action: {
                                        
                                    }){
                                        ZStack {
                                            Image("Shop_ButtonBuyInactive")
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                                .frame(width: 100)
                                            Text("250")
                                                .font(.custom("Comic Lemon", size: 18))
                                                .foregroundStyle(.white)
                                                .padding(.leading, 10)
                                        }
                                    }.disabled(true)
                                }
                            } else {
                                if selectedCostume != "costume_siputih" {
                                    Button(action: {
                                        scene.selectCostume("costume_siputih")
                                    }){
                                        Image("Shop_ButtonEquip")
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 100)
                                    }
                                } else {
                                    Image("Shop_ButtonEquipped")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 100)
                                }
                            }
                        }
                        .frame(maxWidth: 150, maxHeight: 170)
                        
                        Color(.black).opacity(0.5)
                            .cornerRadius(20)
                            .frame(maxWidth: 145, maxHeight: 205)
                        
                        Text("Coming Soon")
                            .font(.custom("Comic Lemon", size: 14))
                            .foregroundColor(.white)
                    }
                    
                    ZStack {
                        Image("ShopCard")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 150)
                        
                        VStack (spacing: 12) {
                            Text("Abu")
                                .font(.custom("Comic Lemon", size: 18))
                                .foregroundColor(Color(CGColor(red: 150/255, green: 85/255, blue: 45/255, alpha: 1)))
                            Spacer()
                            Image("Shop_SkinAbu")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 100)
                            Spacer()
                            if !purchasedCostumes.contains("costume_abu") {
                                if coins >= 500 {
                                    Button(action: {
                                        scene.buyCostume(costume: "costume_abu", price: 500)
                                    }){
                                        ZStack {
                                            Image("Shop_ButtonBuy")
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                                .frame(width: 100)
                                            Text("500")
                                                .font(.custom("Comic Lemon", size: 18))
                                                .foregroundStyle(.white)
                                                .padding(.leading, 10)
                                        }
                                    }
                                } else {
                                    Button(action: {
                                        
                                    }){
                                        ZStack {
                                            Image("Shop_ButtonBuyInactive")
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                                .frame(width: 100)
                                            Text("500")
                                                .font(.custom("Comic Lemon", size: 18))
                                                .foregroundStyle(.white)
                                                .padding(.leading, 10)
                                        }
                                    }.disabled(true)
                                }
                            } else {
                                if selectedCostume != "costume_abu" {
                                    Button(action: {
                                        scene.selectCostume("costume_abu")
                                    }){
                                        Image("Shop_ButtonEquip")
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 100)
                                    }
                                } else {
                                    Image("Shop_ButtonEquipped")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 100)
                                }
                            }
                        }
                        .frame(maxWidth: 150, maxHeight: 170)
                        
                        Color(.black).opacity(0.5)
                            .cornerRadius(20)
                            .frame(maxWidth: 145, maxHeight: 205)
                        
                        Text("Coming Soon")
                            .font(.custom("Comic Lemon", size: 14))
                            .foregroundColor(.white)
                    }
                    
                    ZStack {
                        Image("ShopCard")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 150)
                        
                        VStack (spacing: 12) {
                            Text("Garronk")
                                .font(.custom("Comic Lemon", size: 18))
                                .foregroundColor(Color(CGColor(red: 150/255, green: 85/255, blue: 45/255, alpha: 1)))
                            Spacer()
                            Image("Shop_SkinGarronk")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 100)
                            Spacer()
                            if !purchasedCostumes.contains("costume_garronk") {
                                if coins >= 1000 {
                                    Button(action: {
                                        scene.buyCostume(costume: "costume_garronk", price: 1000)
                                    }){
                                        ZStack {
                                            Image("Shop_ButtonBuy")
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                                .frame(width: 100)
                                            Text("1000")
                                                .font(.custom("Comic Lemon", size: 18))
                                                .foregroundStyle(.white)
                                                .padding(.leading, 10)
                                        }
                                    }
                                } else {
                                    Button(action: {
                                        
                                    }){
                                        ZStack {
                                            Image("Shop_ButtonBuyInactive")
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                                .frame(width: 100)
                                            Text("1000")
                                                .font(.custom("Comic Lemon", size: 18))
                                                .foregroundStyle(.white)
                                                .padding(.leading, 10)
                                        }
                                    }.disabled(true)
                                }
                            } else {
                                if selectedCostume != "costume_garronk" {
                                    Button(action: {
                                        scene.selectCostume("costume_garronk")
                                    }){
                                        Image("Shop_ButtonEquip")
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 100)
                                    }
                                } else {
                                    Image("Shop_ButtonEquipped")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 100)
                                }
                            }
                        }
                        .frame(maxWidth: 150, maxHeight: 170)
                        
                        Color(.black).opacity(0.5)
                            .cornerRadius(20)
                            .frame(maxWidth: 145, maxHeight: 205)
                        
                        Text("Coming Soon")
                            .font(.custom("Comic Lemon", size: 14))
                            .foregroundColor(.white)
                    }
                }
                .padding(.bottom, 30)
                .frame(width: UIBoxWidth - 60)
            }
            .padding(.top, 60)
        }
        .padding(.top, 20)
        .padding(.leading, 20)
        .onAppear{
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

