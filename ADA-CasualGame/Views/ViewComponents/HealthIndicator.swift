//
//  HealthIndicator.swift
//  ADA-CasualGame
//
//  Created by Derend Marvel Hanson Prionggo on 16/07/25.
//

import SwiftUI

struct HealthBar: View {
//    var health: Int
//    
//    var body: some View {
//        VStack {
//            HStack {
//                ZStack(alignment: .leading) { // align content to top-leading
//                    Image("HealthBarBackground")
//                        .resizable()
//                        .aspectRatio(contentMode: .fit)
//                        .frame(width: 180)
//                    
//                    HStack(spacing: 2) {
//                        ForEach(0..<health) { _ in
//                            Image("HealthBar")
//                                .resizable()
//                                .aspectRatio(contentMode: .fit)
//                                .frame(width: 10)
//                        }
//                    }
//                    .padding(.top, 18) // only top padding, no leading
//                    .padding(.leading, 48) // optional fine adjustment
//                }
//            }
//        }
//    }
    
    let health: Int
    
    var body: some View {
        ZStack{
            Image("HealthIndicator")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 90)
            Text("\(health)")
                .font(.custom("Comic Lemon", size: 20))
                .bold()
                .foregroundColor(.white)
                .shadow(radius: 2)
                .padding(.leading, 40)
                .padding(.top, 2)
        }
    }
}

#Preview {
    HealthBar(health: 9)
}
