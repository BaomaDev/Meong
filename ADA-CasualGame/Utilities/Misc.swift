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

extension String {
    /// Truncates the string to a specific length and appends an ellipsis if needed.
    func truncated(to length: Int) -> String {
        // Check if the string's length is greater than the desired limit.
        if self.count > length {
            // If so, take a prefix of the appropriate length and add "..."
            return String(self.prefix(length - 3)) + "..."
        } else {
            // Otherwise, return the original string.
            return self
        }
    }
}
