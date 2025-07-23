//
//  ShopScene.swift
//  ADA-CasualGame
//
//  Created by Syamsuddin Putra Riefli on 23/07/25.
//

import Foundation
import SpriteKit

class ShopScene: SKScene {
    private var playerData: PlayerData!
    var coinUpdateHandler: ((Int) -> Void)?
    var costumePurchasedHandler:  (([String]) -> Void)?
    var selectedCostumeHandler:  ((String) -> Void)?
    
    override func didMove(to view: SKView) {
        setupPlayerData()
    }
    
    private func setupPlayerData() {
        playerData = SaveManager.shared.load()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(savePlayerData),
            name: UIApplication.willTerminateNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(savePlayerData),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        coinUpdateHandler?(playerData.coins)
    }
    
    func buyCostume(costume: String, price coin:Int) {
        guard playerData.coins >= coin else { return }
        guard !playerData.unlockedCostumes.contains(costume) else { return }
        
        playerData.coins -= coin
        playerData.unlockedCostumes.append(costume)
        coinUpdateHandler?(playerData.coins)
        costumePurchasedHandler?(playerData.unlockedCostumes)
        savePlayerData()
    }
    
    func selectCostume(_ costume: String) {
        guard playerData.unlockedCostumes.contains(costume) else { return }
        playerData.selectedCostume = costume
        selectedCostumeHandler?(costume)
        savePlayerData()
    }
    
    @objc private func savePlayerData() {
        SaveManager.shared.save(playerData)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        savePlayerData()
    }
}
