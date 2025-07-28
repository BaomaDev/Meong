import GameKit
import SwiftUI

// A struct to hold the leaderboard data in a clean format for SwiftUI.
struct LeaderboardEntry: Identifiable {
    let id = UUID()
    let rank: Int
    let playerName: String
    let score: Int
}

/// A singleton class to manage all Game Center interactions.
class GameCenterManager: ObservableObject {
    
    @Published var leaderboardEntries: [LeaderboardEntry] = []
    
    static let shared = GameCenterManager()
    
    private let leaderboardID = "meong_high_score"
    
    private init() {}
    
    /// Authenticates the local player with Game Center.
    func authenticatePlayer() {
        print("attempting authentication")
        GKLocalPlayer.local.authenticateHandler = { viewController, error in
            if let vc = viewController {
                let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
                windowScene?.windows.first?.rootViewController?.present(vc, animated: true)
                return
            }
            if let error = error {
                print("Error authenticating player: \(error.localizedDescription)")
                return
            }
            print("Game Center Player Authenticated: \(GKLocalPlayer.local.displayName)")
        }
    }
    
    /// Submits the player's high score to the leaderboard.
    func submitScore(_ score: Int) {
        GKLeaderboard.submitScore(score, context: 0, player: GKLocalPlayer.local, leaderboardIDs: [leaderboardID]) { error in
            if let error = error {
                print("Error submitting score: \(error.localizedDescription)")
            } else {
                print("Score of \(score) submitted successfully to leaderboard \(self.leaderboardID)")
            }
        }
    }
    
    /// Fetches the top scores from the leaderboard.
    func fetchLeaderboard() {
        GKLeaderboard.loadLeaderboards(IDs: [leaderboardID]) { [weak self] (leaderboards, error) in
            guard let self = self, let leaderboard = leaderboards?.first else {
                print("Error fetching leaderboards: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            // **THE FIX**: The parameter names in the completion handler have been corrected.
            // The second parameter is the array of entries.
            leaderboard.loadEntries(for: .global, timeScope: .allTime, range: NSRange(location: 1, length: 100)) { (localPlayerEntry, entries, totalPlayerCount, error) in
                guard let entries = entries else {
                    print("Error fetching leaderboard entries: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                
                // Now that 'entries' is correctly identified as an array, .map will work.
                let leaderboardData = entries.map { (entry: GKLeaderboard.Entry) -> LeaderboardEntry in
                    return LeaderboardEntry(rank: entry.rank,
                                            playerName: entry.player.displayName,
                                            score: entry.score)
                }
                
                DispatchQueue.main.async {
                    self.leaderboardEntries = leaderboardData
                }
            }
        }
    }
}
