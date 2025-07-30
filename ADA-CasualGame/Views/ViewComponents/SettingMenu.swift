//
//  ShopView.swift
//  ADA-CasualGame
//
//  Created by Syamsuddin Putra Riefli on 23/07/25.
//

import SwiftUI
import SpriteKit

struct SettingMenu: View {
    @Binding var isShowing: Bool
    @Binding var bgmVolume: Float
    @State private var isBGMEditing: Bool = false
    @Binding var sfxVolume: Float
    @State private var isSFXEditing: Bool = false
    @Binding var scene: GameScene
    var body: some View {
        ZStack {
            Image("UI_Box")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: UIBoxWidth)
            
            VStack (spacing: 40){
                ZStack {
                    HStack {
                        Spacer()
                        Text("Setting")
                            .font(.custom("Comic Lemon", size: 30))
                            .foregroundStyle(.black)
                        Spacer()
                    }
                    
                    HStack {
                        HStack {
                            Button(action: {
                                isShowing = false
                            }){
                                Image("CloseButton")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 50)
                                    .padding(.leading, 15)
                            }
                            .padding(2)
                            
                            Spacer()
                            
                            Spacer()
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, -90)
                
                ZStack {
                    VStack {
                        Text("BGM Volume")
                            .font(.custom("Comic Lemon", size: 16))
                            .foregroundStyle(.black)
                        
                        Slider(value: $bgmVolume, in: 0...1, step: 0.1) {
                            Text("BGM Volume")
                        } minimumValueLabel: {
                            Text("0")
                                .font(.custom("Comic Lemon", size: 14))
                                .foregroundStyle(.black)
                        } maximumValueLabel: {
                            Text("10")
                                .font(.custom("Comic Lemon", size: 14))
                                .foregroundStyle(.black)
                        } onEditingChanged: { editing in
                            scene.setBgmVolume(bgmVolume)
                        }
                        .frame(width: 300)
                        
                        Text("SFX Volume")
                            .font(.custom("Comic Lemon", size: 16))
                            .foregroundStyle(.black)
                        
                        Slider(value: $sfxVolume, in: 0...1, step: 0.1) {
                            Text("SFX Volume")
                        } minimumValueLabel: {
                            Text("0")
                                .font(.custom("Comic Lemon", size: 14))
                                .foregroundStyle(.black)
                        } maximumValueLabel: {
                            Text("10")
                                .font(.custom("Comic Lemon", size: 14))
                                .foregroundStyle(.black)
                        } onEditingChanged: { editing in
                            scene.setSfxVolume(sfxVolume)
                        }
                        .frame(width: 300)
                    }
                }
                .padding(.bottom, 40)
            }
            .padding(.top, 60)
        }
        .padding(.top, 20)
        .padding(.leading, 20)
    }
}

//#Preview {
//    ShopView(isShowing: .constant(true))
//}

