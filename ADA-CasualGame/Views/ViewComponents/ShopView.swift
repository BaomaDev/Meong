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
    @State private var selectedCostume: String? = "default"
    @State private var purchasedCostumes: [String] = []
    var body: some View {
        ZStack {
            ZStack {
                Image("UI_Box")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 800)
                VStack {
                    ZStack {
                        HStack {
                            Spacer()
                            Image("ShopBanner")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 200)
                                .padding(.top, -50)
                                .padding(.trailing, 20)
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
                                        .padding(.leading, 60)
                                }
                                .padding(2)
                                
                                Spacer()
                                
                                CoinIndicator(coinCount: coins)
                                    .padding(.trailing, 100)
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
                                    .frame(width: 150)
                                
                                VStack (spacing: 12) {
                                    Image("cat")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 100)
                                    Text("Cat")
                                        .font(.custom("Comic Lemon", size: 18))
                                    Text("1000 Coins")
                                        .font(.custom("Comic Lemon", size: 12))
                                    Button(action: {
                                        
                                    }){
                                        Image("BuyButton")
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 100)
                                    }
                                }
                            }
                            ZStack {
                                Image("ShopCard")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 150)
                                
                                VStack (spacing: 12) {
                                    Image("cat")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 100)
                                    Text("Cat")
                                        .font(.custom("Comic Lemon", size: 18))
                                    Text("Purchashed")
                                        .font(.custom("Comic Lemon", size: 12))
                                    Button(action: {
                                        
                                    }){
                                        Image("EquipButton")
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 100)
                                    }
                                }
                            }
                            ZStack {
                                Image("ShopCard")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 150)
                                
                                VStack (spacing: 12) {
                                    Image("cat")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 100)
                                    Text("Cat")
                                        .font(.custom("Comic Lemon", size: 18))
                                    Text("1000 Coins")
                                        .font(.custom("Comic Lemon", size: 12))
                                    Button(action: {
                                        
                                    }){
                                        Image("BuyButton")
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 100)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.bottom, -30)
                    .padding(.trailing, 30)
                }
            }
            
        }
        .padding(.top, 50)
        .padding(.leading, 50)
    }
}

#Preview {
    ShopView(isShowing: .constant(true))
}

