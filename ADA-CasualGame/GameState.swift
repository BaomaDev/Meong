//
//  GameState.swift
//  GamePlayKitTest
//
//  Created by Jesse Robinson Junior Simanjuntak on 14/07/25.
//

class GameState {
    static let shared = GameState()
    private init() {}
    
    var score: Int = 0
    var playerDistance: Int = 3
    
    // ✅ Tambahkan method untuk reset game state
    func resetGame() {
        score = 0
        playerDistance = 3
    }
}
