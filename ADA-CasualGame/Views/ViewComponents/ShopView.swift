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
                                Text("Cat")
                                    .font(.custom("Comic Lemon", size: 18))
                                    .foregroundStyle(.black)
                                Text("1000 Coins")
                                    .font(.custom("Comic Lemon", size: 12))
                                    .foregroundStyle(.black)
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
                                .frame(width: 170)
                            
                            VStack (spacing: 12) {
                                Image("cat")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 100)
                                Text("Cat")
                                    .font(.custom("Comic Lemon", size: 18))
                                    .foregroundStyle(.black)
                                Text("Purchashed")
                                    .font(.custom("Comic Lemon", size: 12))
                                    .foregroundStyle(.black)
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
                                .frame(width: 170)
                            
                            VStack (spacing: 12) {
                                Image("cat")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 100)
                                Text("Cat")
                                    .font(.custom("Comic Lemon", size: 18))
                                    .foregroundStyle(.black)
                                Text("1000 Coins")
                                    .font(.custom("Comic Lemon", size: 12))
                                    .foregroundStyle(.black)
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
                .padding(.top, -30)
//                .padding(.trailing, 30)
            }
            .padding(.top, 60)
        }
//        .ignoresSafeArea()
        .padding(.top, 20)
        .padding(.leading, 20)
    }
}

#Preview {
    ShopView(isShowing: .constant(true))
}

