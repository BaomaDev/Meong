//
//  WorldNoiseMap.swift
//  ADA-CasualGame
//
//  Created by Syamsuddin Putra Riefli on 17/07/25.
//

import GameplayKit

enum NoiseShapingMethod {
    case none
    case squared(Double)
    case inverseValley(baseNoise: Double)
    case custom((_ value: Double) -> Double)
}

class WorldNoiseMap {
    private let noiseMap: GKNoiseMap
    private let width: Int
    private let height: Int

    init(seed: Int32 = 1337, chunkCount: Int = 1000, layerCount: Int = 10, noiseType: String = "Perlin") {
        self.width = chunkCount
        self.height = layerCount
        
        print("Seed: \(seed)")
        
        let source: GKNoiseSource
        switch noiseType {
        case "Perlin" :
            source = GKPerlinNoiseSource(
                frequency: 10,         
                octaveCount: 2,         
                persistence: 0.2,      
                lacunarity: 5,
                seed: seed)
        case "Ridged" :
            source = GKRidgedNoiseSource(
                frequency: 3.0,
                octaveCount: 4,
                lacunarity: 2.0,
                seed: seed
            )
        default :
            fatalError("Unsupported noise type: \(noiseType)")
        }

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
    
    func adjustNoiseValue(_ value: Double, method: NoiseShapingMethod = .none) -> Double {
        let clamped = max(0.0, min(1.0, value))
        
        switch method {
        case .none:
            return clamped
        case .squared(let power):
            return pow(clamped, power) // High values become rarer
        case .inverseValley(let baseNoise):
            return clamped * (1.0 - abs(baseNoise)) // Creates valleys
        case .custom(let transform):
            return transform(clamped)
        }
    }
}

// MARK: - Clamp Helper
extension Comparable {
    func clamped(to range: Range<Self>) -> Self {
        return min(max(self, range.lowerBound), range.upperBound)
    }
}
