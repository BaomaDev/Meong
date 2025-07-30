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
            VStack{
                ZStack {
                    HStack {
                        Spacer()
                        Image("Achievements_Banner")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 300)
                            .padding(.bottom, 20)
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
                            }
                            .padding(2)
                            .padding(.bottom, 12)
                            
                            Spacer()
                            
                            Spacer()
                        }
                        .padding(.leading, 40)
                    }
                }
                .padding(.horizontal)
                .padding(.top, -70)
                
                ScrollView {
                    VStack(spacing: 20) {
                        ForEach(achievementManager.achievements.indices, id: \.self) { index in
                            let achievement = achievementManager.achievements[index]
                            ZStack {
                                Color.white.opacity(0.7)
                                    .cornerRadius(20)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color(CGColor(red: 242/255, green: 190/255, blue: 85/255, alpha: 1)), lineWidth: 5)
                                    )
                                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
//                                    .frame(maxWidth: .infinity)
                                HStack (spacing: 15) {
                                    if achievement.isHidden {
                                        Text("Run through the street to find something!")
                                            .font(.custom("Comic Lemon", size: 16))
                                            .foregroundColor(Color(CGColor(red: 150/255, green: 85/255, blue: 45/255, alpha: 1)))
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 35)
                                    } else {
                                        Image(achievement.image)
                                            .resizable()
                                            .frame(width: 80, height: 80)
                                            .overlay(
                                                Circle()
                                                    .stroke(Color(CGColor(red: 242/255, green: 190/255, blue: 85/255, alpha: 1)), lineWidth: 5)
                                            )
                                            .padding(.leading, -20)
                                            
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(achievement.title)
                                                .font(.custom("Comic Lemon", size: 16))
                                                .foregroundColor(Color(CGColor(red: 150/255, green: 85/255, blue: 45/255, alpha: 1)))

                                            Text(achievement.description)
                                                .font(.custom("Comic Lemon", size: 16))
                                                .foregroundColor(Color(CGColor(red: 200/255, green: 160/255, blue: 130/255, alpha: 1)))
                                        }

                                        Spacer()

                                        Button(action: {
                                            AchievementManager.shared.claimReward(for: index)
                                        }) {
                                            ZStack {
                                                Image(!achievement.isUnlocked ? "Achievements_ButtonClaimInactive" :
                                                        achievement.isClaimed ? "Achievements_ButtonClaimed" :
                                                        "Achievements_ButtonClaim")
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                                .frame(width: 100)
                                                Text(achievement.isClaimed ? "" :
                                                    "\(achievement.reward)"
                                                )
                                                .padding(.leading, 15)
                                            }
                                            .font(.custom("Comic Lemon", size: 20))
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 5)
                                            .cornerRadius(5)
                                            .foregroundStyle(.white)
                                        }
                                        .disabled(!achievement.isUnlocked || achievement.isClaimed)
                                        .padding(.trailing, -25)
                                    }
                                }
                                .padding(.horizontal, 25)
                                .padding(.vertical, -5)
                                .padding(.leading, -25)
                            }
                        }
                    }
                    .padding()
                    .padding(.horizontal, 20)
                }
                .frame(maxWidth: 650, maxHeight: 220)
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
