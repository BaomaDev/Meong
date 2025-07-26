//
//  CoinIndicator.swift
//  ADA-CasualGame
//
//  Created by Derend Marvel Hanson Prionggo on 16/07/25.
//

import SwiftUI

struct CoinIndicator: View {
    let coinCount: Int
    
    var body: some View {
        ZStack{
            Image("CoinIndicator")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 90)
            Text("\(coinCount)")
                .font(.custom("Comic Lemon", size: 18))
                .foregroundColor(.white)
                .shadow(radius: 2)
                .padding(.leading, 40)
                .padding(.top, 2)
        }
    }
}

#Preview {
    CoinIndicator(coinCount: 0)
}

