//
//  WorldNoiseMap.swift
//  ADA-CasualGame
//
//  Created by Syamsuddin Putra Riefli on 17/07/25.
//

import GameplayKit

class WorldNoiseMap {
    private let noiseMap: GKNoiseMap
    private let width: Int
    private let height: Int

    init(seed: Int32 = 1337, chunkCount: Int = 1000, layerCount: Int = 10) {
        self.width = chunkCount
        self.height = layerCount

        let source = GKPerlinNoiseSource(
            frequency: 10,         // increase frequency to add more variation between chunks
            octaveCount: 2,         // more detail
            persistence: 0.2,      // controls amplitude of each octave (higher = bolder noise)
            lacunarity: 5,        // controls frequency change between octaves
            seed: seed
        )

        let noise = GKNoise(source)
        
        self.noiseMap = GKNoiseMap(
            noise,
            size: vector_double2(20, 10),       // Horizontal & vertical scale of the noise
            origin: vector_double2(0, 0),
            sampleCount: vector_int2(Int32(chunkCount), Int32(layerCount)),
            seamless: false
        )
    }

    func rawValueAt(atChunk x: Int, layer y: Int) -> Float {
        let vector = vector_int2(Int32(x), Int32(y))
        return noiseMap.value(at: vector) // Returns -1...1
    }

    func valueAt(atChunk x: Int, layer y: Int) -> Float {
        return (rawValueAt(atChunk: x, layer: y) + 1.0) / 2.0 // Normalize to 0...1
    }

    // Return true if value exceeds threshold (default = 0.3)
    func isActive(atChunk x: Int, layer y: Int, threshold: Float = 0.3) -> Bool {
        return valueAt(atChunk: x, layer: y) > threshold
    }

    // Map noise value [-1, 1] into type index [0..<maxTypes]
    func typeIndex(atChunk x: Int, layer y: Int, maxTypes: Int) -> Int {
        let raw = valueAt(atChunk: x, layer: y)
        let normalized = (raw + 1) / 2 // now in [0, 1]
        return Int(normalized * Float(maxTypes)).clamped(to: 0..<(maxTypes))
    }
}

// MARK: - Clamp Helper
extension Comparable {
    func clamped(to range: Range<Self>) -> Self {
        return min(max(self, range.lowerBound), range.upperBound)
    }
}
