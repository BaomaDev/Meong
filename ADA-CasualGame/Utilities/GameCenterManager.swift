import GameKit
import SwiftUI

// A struct to hold the leaderboard data in a clean format for SwiftUI.
struct LeaderboardEntry: Identifiable {
    let id = UUID()
    let rank: Int
    let playerName: String
    let score: Int
    let profilePicture: Image?
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
    @MainActor // Ensures UI updates happen on the main thread
    func fetchLeaderboard() async {
        let leaderboardID = "meong_high_score"
        
        do {
            // 1. Load the specific leaderboard.
            let leaderboards = try await GKLeaderboard.loadLeaderboards(IDs: [leaderboardID])
            guard let leaderboard = leaderboards.first else {
                print("Leaderboard not found.")
                return
            }

            // 2. Fetch the top 100 entries from the leaderboard.
            let (localPlayerEntry, allEntries, totalPlayerCount) = try await leaderboard.loadEntries(for: .global, timeScope: .allTime, range: NSRange(location: 1, length: 100))
            
            // 3. Asynchronously load the photo for each entry.
            var leaderboardData: [LeaderboardEntry] = []
            for entry in allEntries {
                var profileImage: Image? = nil
                
                // loadPhoto is an async function, so we must 'await' its result.
                if let uiImage = try? await entry.player.loadPhoto(for: .normal) {
                    profileImage = Image(uiImage: uiImage)
                }
                
                let newEntry = LeaderboardEntry(rank: entry.rank,
                                                playerName: entry.player.displayName,
                                                score: entry.score,
                                                profilePicture: profileImage)
                leaderboardData.append(newEntry)
            }
            
            // 4. Update the @Published property to refresh the SwiftUI view.
            self.leaderboardEntries = leaderboardData
            
        } catch {
            print("Error fetching leaderboard data: \(error.localizedDescription)")
        }
    }
}
