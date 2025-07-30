//
//  AchieveLiveCard.swift
//  ADA-CasualGame
//
//  Created by Syamsuddin Putra Riefli on 28/07/25.
//

import SwiftUI

struct AchieveLiveCard: View {
    let achievement: Achievement
    var body: some View {
        VStack {
            ZStack {
                Color(CGColor(red: 252/255, green: 239/255, blue: 207/255, alpha: 1))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color(CGColor(red: 242/255, green: 190/255, blue: 85/255, alpha: 1)), lineWidth: 2.5)
                    )
                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)

                HStack {
                    Image(achievement.image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 45, height: 45)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(achievement.title)
                            .font(.custom("Comic Lemon", size: 12))
                            .foregroundStyle(.black)
                            .lineLimit(1)
                        Text(achievement.description)
                            .font(.custom("Comic Lemon", size: 12))
                            .foregroundColor(.gray)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                }
                .padding(.horizontal, 10)
            }
            .frame(width: 300, height: 60)
            .padding(.top, 20)
            
            Spacer()
        }
    }
}

//#Preview {
//    AchieveLiveCard(achievement: Achievement)
//}
