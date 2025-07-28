//
//  AchievementManager.swift
//  ADA-CasualGame
//
//  Created by Syamsuddin Putra Riefli on 28/07/25.
//

import Foundation

struct Achievement: Codable {
    var image: String
    var title: String
    var description: String
    var reward: Int
    var isUnlocked: Bool
    var isClaimed: Bool
}

struct LiveStats {
    var catnipsEaten: Int
}

final class AchievementManager: ObservableObject {
    typealias UnlockCheck = (PlayerData) -> Bool

    let achievementConditions: [String: UnlockCheck] = [
        "Newbie": { $0.highScore >= 100 },
        "Pro": { $0.highScore >= 250 },
        "Legend": { $0.highScore >= 500 },
        "Stray": { $0.totalGamesPlayed >= 20 },
        "Bandit": { $0.totalGamesPlayed >= 50 },
        "Mafia": { $0.totalGamesPlayed >= 100 },
        "Bike Lessons": { $0.totalBikerKnockedOut >= 50 },
        "Grandmaster": { $0.totalChessKnockedOut >= 50 },
        "Why did the cat cross the road?": { $0.totalChickenKnockedOut >= 50 },
        "Monkey Business": { $0.totalBananaKnockedOut >= 50 },
        "Bullseye": { $0.totalHittedBySandal >= 50 },
        "Tycoon": { $0.totalCoinsGained >= 5000 },
    ]
    
    
    var onUnlock: ((Achievement) -> Void)?

    static let shared = AchievementManager()

    @Published private(set) var achievements: [Achievement] = []

    private init() {
        loadAchievements()
    }
    
    private func loadAchievements() {
        if let data = UserDefaults.standard.data(forKey: "achievements"),
           let decoded = try? JSONDecoder().decode([Achievement].self, from: data) {
            self.achievements = decoded
        } else {
            // default list (editable later)
            self.achievements = [
                Achievement(image: "achv_highcore_100", title: "Newbie", description: "Get High Score of 100", reward: 50, isUnlocked: false, isClaimed: false),
                Achievement(image: "achv_highcore_250", title: "Pro", description: "Get High Score of 250", reward: 75, isUnlocked: false, isClaimed: false),
                Achievement(image: "achv_highcore_500", title: "Legend", description: "Get High Score of 500", reward: 100, isUnlocked: false, isClaimed: false),
                Achievement(image: "achv_games_20", title: "Stray", description: "Play 20 games", reward: 50, isUnlocked: false, isClaimed: false),
                Achievement(image: "achv_games_50", title: "Bandit", description: "Play 50 games", reward: 75, isUnlocked: false, isClaimed: false),
                Achievement(image: "achv_games_100", title: "Mafia", description: "Play 100 games", reward: 100, isUnlocked: false, isClaimed: false),
                Achievement(image: "achv_bikes_50", title: "Bike Lessons", description: "Knock Syam 50 times", reward: 50, isUnlocked: false, isClaimed: false),
                Achievement(image: "achv_chess_50", title: "Grandmaster", description: "Knock Derend 50 times", reward: 50, isUnlocked: false, isClaimed: false),
                Achievement(image: "achv_chicken_50", title: "Why did the cat cross the road?", description: "Knock Chicken 50 times", reward: 50, isUnlocked: false, isClaimed: false),
                Achievement(image: "achv_banana_50", title: "Monkey Business", description: "Knock Banana 50 times", reward: 50, isUnlocked: false, isClaimed: false),
                Achievement(image: "achv_sandal_50", title: "Bullseye", description: "Get hit by Sandal 50 times", reward: 50, isUnlocked: false, isClaimed: false),
                Achievement(image: "achv_catnip_10", title: "Tweaker", description: "Get catnip 10 times in a single run", reward: 100, isUnlocked: false, isClaimed: false),
                Achievement(image: "achv_totalcoin_5000", title: "Tycoon", description: "Get 5000 coins total", reward: 100, isUnlocked: false, isClaimed: false)
            ]
            saveAchievements()
        }
    }
    
    func saveAchievements() {
        if let encoded = try? JSONEncoder().encode(achievements) {
            UserDefaults.standard.set(encoded, forKey: "achievements")
        }
    }

    func claimReward(for index: Int) {
        guard achievements.indices.contains(index) else { return }
        if achievements[index].isUnlocked && !achievements[index].isClaimed {
            achievements[index].isClaimed = true
            var playerData = SaveManager.shared.load()
            playerData.coins += achievements[index].reward
            SaveManager.shared.save(playerData)
            saveAchievements()
        }
    }
    
    //MARK: - Check on Game Over state
    func checkForUnlocks(with playerData: PlayerData) {
        for i in achievements.indices {
            let title = achievements[i].title
            if !achievements[i].isUnlocked,
               let condition = achievementConditions[title],
                condition(playerData) {
                achievements[i].isUnlocked = true
                onUnlock?(achievements[i])
            }
        }
        saveAchievements()
    }
    
    //MARK: - Check on Playing state
    func unlockIf(_ title: String, condition: () -> Bool) {
        if let index = achievements.firstIndex(where: { $0.title == title }),
           !achievements[index].isUnlocked,
           condition() {
            achievements[index].isUnlocked = true
            saveAchievements()
            print("Unlocked: \(achievements[index].title)")
            onUnlock?(achievements[index])
        }
    }
    
    func updateProgress(_ stats: LiveStats) {
        unlockIf("Tweaker") {
            stats.catnipsEaten >= 10
        }
    }
}
