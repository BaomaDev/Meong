//
//  ShopView.swift
//  ADA-CasualGame
//
//  Created by Syamsuddin Putra Riefli on 23/07/25.
//

import SwiftUI
import SpriteKit

struct AchievementView: View {
    @Binding var isShowing: Bool
    @ObservedObject var achievementManager: AchievementManager = .shared
    var body: some View {
        ZStack {
            Image("UI_Box")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: UIBoxWidth)
            
            VStack (spacing: 20){
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
                                isShowing = false
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
                            
                            Spacer()
                        }
                        .padding(.top, 10)
                    }
                }
                .padding(.horizontal)
                .padding(.top, -90)
                
                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(achievementManager.achievements.indices, id: \.self) { index in
                            let achievement = achievementManager.achievements[index]
                            HStack(spacing: 15) {
                                if achievement.isHidden {
                                    Text("Run through the street to find something!")
                                        .font(.custom("Comic Lemon", size: 16))
                                        .foregroundStyle(.black)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 20)
                                } else {
                                    Image(achievement.image)
                                        .resizable()
                                        .frame(width: 50, height: 50)
                                        .cornerRadius(8)

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(achievement.title)
                                            .font(.custom("Comic Lemon", size: 16))
                                            .foregroundColor(.black)

                                        Text(achievement.description)
                                            .font(.custom("Comic Lemon", size: 12))
                                            .foregroundColor(.gray)

                                        if achievement.isUnlocked {
                                            Text(achievement.isClaimed ? "Claimed" : "Unlocked")
                                                .font(.custom("Comic Lemon", size: 12))
                                                .font(.caption)
                                                .foregroundColor(.green)
                                        } else {
                                            Text("Locked")
                                                .font(.custom("Comic Lemon", size: 12))
                                                .font(.caption)
                                                .foregroundColor(.red)
                                        }
                                    }

                                    Spacer()

                                    Button(action: {
                                        AchievementManager.shared.claimReward(for: index)
                                    }) {
                                        HStack {
                                            Text(
                                                !achievement.isUnlocked ? "Claim \(achievement.reward)" :
                                                achievement.isClaimed ? "Claimed" :
                                                "Claim \(achievement.reward)"
                                            )
                                            if !achievement.isClaimed {
                                                Image("Coin")
                                                    .resizable()
                                                    .frame(width: 25, height: 25)
                                            }
                                        }
                                        .font(.custom("Comic Lemon", size: 16))
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(
                                            achievement.isUnlocked && !achievement.isClaimed
                                                ? Color.yellow
                                                : Color.gray.opacity(0.5)
                                        )
                                        .cornerRadius(5)
                                        .foregroundStyle(.black)
                                    }
                                    .disabled(!achievement.isUnlocked || achievement.isClaimed)
                                }
                            }
                            .padding()
                            .background(Color.white.opacity(0.7))
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color(CGColor(red: 242/255, green: 190/255, blue: 85/255, alpha: 1)), lineWidth: 2.5)
                            )
                            .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                        }
                    }
                    .padding()
                    .padding(.horizontal, 20)
                }
                .frame(maxHeight: 220)
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
