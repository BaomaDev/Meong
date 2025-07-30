//
//  CutVerticalCapsule.swift
//  ADA-CasualGame
//
//  Created by Savio Enoson on 30/07/25.
//


import SwiftUI

/// A view that displays a vertical capsule shape cut to a specific height.
///
/// This view uses a `RoundedRectangle` to allow for an adjustable corner radius.
/// You can control its height, corner roundness, and color.
struct CutVerticalCapsule: View {
    /// The height to which the capsule shape will be cut.
    let height: CGFloat
    
    /// The corner radius of the capsule's ends.
    let cornerRadius: CGFloat
    
    /// The color of the capsule.
    let color: Color

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(color)
            .frame(height: height)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        RoundedRectangle(cornerRadius: 72)
            .fill(.white)
            .frame(width: 100, height: 200)
            .frame(height: 120, alignment: .top)
            .clipped()
    }
    .padding()
}
