//
//  SaveManager.swift
//  ADA-CasualGame
//
//  Created by Syamsuddin Putra Riefli on 22/07/25.
//

import Foundation

struct PlayerData: Codable {
    var isFirstTimeInstall: Bool = true
    var highScore: Int
    var coins: Int
    var selectedCostume: String
    var unlockedCostumes: [String] // Example: ["skin_red", "skin_blue"]
    var bgmVolume: Float = 1.0
    var sfxVolume: Float = 1.0
}

final class SaveManager {
    static let shared = SaveManager()
    
    private let fileName = "player_data.json"

    private var fileURL: URL {
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return directory.appendingPathComponent(fileName)
    }

    private init() {}

    // Load saved data or return default
    func load() -> PlayerData {
        do {
            let data = try Data(contentsOf: fileURL)
            let decoded = try JSONDecoder().decode(PlayerData.self, from: data)
            return decoded
        } catch {
            print("⚠️ Load failed: \(error.localizedDescription), using default values.")
            return PlayerData(isFirstTimeInstall: true,highScore: 0, coins: 0, selectedCostume: "costume_default", unlockedCostumes: ["costume_default"])
        }
    }

    // Save current data
    func save(_ data: PlayerData) {
        do {
            let encoded = try JSONEncoder().encode(data)
            try encoded.write(to: fileURL, options: .atomic)
        } catch {
            print("❌ Save failed: \(error.localizedDescription)")
        }
    }

    // Optional: Reset the save file
    func reset() {
        do {
            try FileManager.default.removeItem(at: fileURL)
            print("🗑 Save data reset.")
        } catch {
            print("❌ Failed to delete save: \(error.localizedDescription)")
        }
    }
}
