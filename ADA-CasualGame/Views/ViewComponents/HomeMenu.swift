//
//  HomeMenu.swift
//  ADA-CasualGame
//
//  Created by Derend Marvel Hanson Prionggo on 26/07/25.
//

import SwiftUI

struct HomeMenu: View {
    var openShop: () -> Void
    var openSettings: () -> Void
    var openLeaderboard: ()-> Void
    var openAchievements: ()-> Void

    var body: some View {
        ZStack {
            VStack {
                HStack(alignment: .top) {
                    // Top-left settings button
                    Button(action: {
                        openSettings()
                    }) {
                        Image("UI_Setting")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 60)
                    }

                    Spacer()

                    // Top-right stacked buttons
                    VStack {
                        Button(action: {
                            openShop()
                        }) {
                            Image("UI_Customize")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 60)
                        }
                        Button(action: {
                            openLeaderboard()
                        }) {
                            Image("UI_Leaderboard")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 60)
                        }
                        
                        Button(action: {
                            openAchievements()
                        }) {
                            Image("UI_Achievements")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 60)
                        }
                    }
                }

                Spacer()
            }
            .padding(24)
        }
    }
}

#Preview {
    HomeMenu(openShop: {}, openSettings: {}, openLeaderboard: {}, openAchievements: {})
}
