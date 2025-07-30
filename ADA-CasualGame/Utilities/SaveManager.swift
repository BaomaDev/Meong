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
    var totalCoinsGained: Int
    var totalCoinsSpent: Int
    var totalGamesPlayed: Int
    var totalBikerKnockedOut: Int
    var totalChessKnockedOut: Int
    var totalChickenKnockedOut: Int
    var totalBananaKnockedOut: Int
    var totalHittedBySandal: Int
    var totalCatnipEaten: Int
    var selectedCostume: String
    var unlockedCostumes: [String] // Example: ["skin_red", "skin_blue"]
    var bgmVolume: Float
    var sfxVolume: Float
    var unlockedAchievements: [String]
}

final class SaveManager {
    static let shared = SaveManager()

    @Published private(set) var playerData: PlayerData

    private let fileName = "player_data.json"

    private let fileURL: URL

    private init() {
        let fileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            .appendingPathComponent("player_data.json")
        self.fileURL = fileURL
        self.playerData = Self.loadFromDisk(from: fileURL)
    }

    static private func loadFromDisk(from url: URL) -> PlayerData {
        do {
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode(PlayerData.self, from: data)
            return decoded
        } catch {
//            print("⚠️ Load failed: \(error.localizedDescription), using default values.")
            return PlayerData(
                isFirstTimeInstall: true, highScore: 0, coins: 0,
                totalCoinsGained: 0, totalCoinsSpent: 0, totalGamesPlayed: 0,
                totalBikerKnockedOut: 0, totalChessKnockedOut: 0,
                totalChickenKnockedOut: 0, totalBananaKnockedOut: 0,
                totalHittedBySandal: 0, totalCatnipEaten: 0,
                selectedCostume: "costume_default", unlockedCostumes: ["costume_default"],
                bgmVolume: 1.0, sfxVolume: 1.0, unlockedAchievements: []
            )
        }
    }

    func save() {
        do {
            let encoded = try JSONEncoder().encode(playerData)
            try encoded.write(to: fileURL, options: .atomic)
//            print("✅ Saved PlayerData: \(playerData)")
        } catch {
//            print("❌ Save failed: \(error.localizedDescription)")
        }
    }

    func reset() {
        do {
            try FileManager.default.removeItem(at: fileURL)
//            print("🗑 Save data reset.")
            playerData = Self.loadFromDisk(from: fileURL)
        } catch {
//            print("❌ Failed to delete save: \(error.localizedDescription)")
        }
    }
    
    func modify(_ block: (inout PlayerData) -> Void) {
        block(&playerData)
        save()
    }
}

