//
//  HealthIndicator.swift
//  ADA-CasualGame
//
//  Created by Derend Marvel Hanson Prionggo on 16/07/25.
//

import SwiftUI

struct HealthBar: View {
    var health: Int
    
    var body: some View {
        VStack {
            HStack {
                ZStack(alignment: .topLeading) { // align content to top-leading
                    Image("HealthBarBackground")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 180)
                    
                    HStack(spacing: 2) {
                        ForEach(0..<health) { _ in
                            Image("HealthBar")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 11)
                        }
                    }
                    .padding(.top, 29) // only top padding, no leading
                    .padding(.leading, 50) // optional fine adjustment
                }
                Spacer()
            }
            Spacer()
        }
        .padding(.top, 20)
    }
}

#Preview {
    HealthBar(health: 3)
}
