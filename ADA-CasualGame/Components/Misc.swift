//
//  Misc.swift
//  Test-SpriteKit
//
//  Created by Savio Enoson on 11/07/25.
//

extension Comparable {
    /// Returns the value clamped to the given closed range.
    func clamped(to limits: ClosedRange<Self>) -> Self {
        return min(max(self, limits.lowerBound), limits.upperBound)
    }
}
