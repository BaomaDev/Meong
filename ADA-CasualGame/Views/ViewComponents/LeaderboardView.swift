import SwiftUI

struct LeaderboardView: View {
    @Binding var isShowing: Bool
    @StateObject private var manager = GameCenterManager.shared
    let placeholderEntry = LeaderboardEntry(rank: 0, playerName: "Placeholder", score: 0, profilePicture: nil)

    let trophyHeight = 100.0
    let podiumProfileSize = 62.0
    let podiumMaxPlayerName = 10

    var body: some View {
        ZStack {
            // Background
            Image("UI_Box")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: UIBoxWidth)
            
            RoundedRectangle(cornerRadius: 36)
                .fill(Color.white)
                .frame(width: UIBoxWidth-20, height: UIBoxHeight-30)
                .padding(.top, 60)
            
            Button(action: {
                isShowing = false
            }){
                Image("CloseButton")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 50)
            }
            .position(x: 60, y: 90)
            
            VStack {
                Image("leaderboard_banner")
                    .resizable()
                    .scaledToFit()
                    .frame(width: UIBoxWidth/2, height: UIBoxHeight/4)
                    .padding(.top, 50)

                ScrollView {
                    HStack(spacing: 40) {
                        ZStack {
                            let entry = manager.leaderboardEntries.indices.contains(1) ? manager.leaderboardEntries[1] : placeholderEntry

                            Image("podium_2")
                                .resizable()
                                .scaledToFit()
                                .frame(height: trophyHeight)
                            
                            VStack {
                                Text(entry.playerName.truncated(to: podiumMaxPlayerName))
                                    .font(.custom("Comic Lemon", size: 16))
                                    .foregroundColor(Color("CustomLightBrown"))
                                Text("\(entry.score)")
                                    .font(.custom("Comic Lemon", size: 24))
                                    .foregroundColor(Color("CustomLightBrown"))
                                
                                if let picture = entry.profilePicture {
                                    picture
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: podiumProfileSize, height: podiumProfileSize)
                                        .clipShape(Circle())
                                } else {
                                    // Provide a default placeholder image.
                                    Image(systemName: "person.circle.fill")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: podiumProfileSize, height: podiumProfileSize)
                                        .foregroundColor(.gray)
                                }
                            }
                            .offset(y: -38)
                        }

                        Spacer()
                        
                        ZStack {
                            let entry = manager.leaderboardEntries.indices.contains(0) ? manager.leaderboardEntries[0] : placeholderEntry

                            Image("podium_1")
                                .resizable()
                                .scaledToFit()
                                .frame(height: trophyHeight*1.35)
                            
                            VStack {
                                Text(entry.playerName.truncated(to: podiumMaxPlayerName))
                                    .font(.custom("Comic Lemon", size: 16))
                                    .foregroundColor(Color("CustomLightBrown"))
                                Text("\(entry.score)")
                                    .font(.custom("Comic Lemon", size: 24))
                                    .foregroundColor(Color("CustomLightBrown"))
                                    .padding(.bottom)
                                
                                if let picture = entry.profilePicture {
                                    picture
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: podiumProfileSize, height: podiumProfileSize)
                                        .clipShape(Circle())
                                } else {
                                    // Provide a default placeholder image.
                                    Image(systemName: "person.circle.fill")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: podiumProfileSize, height: podiumProfileSize)
                                        .foregroundColor(.gray)
                                }
                            }
                            .offset(y: -44)
                        }
                        
                        Spacer()
                        
                        ZStack {
                            let entry = manager.leaderboardEntries.indices.contains(2) ? manager.leaderboardEntries[2] : placeholderEntry

                            Image("podium_3")
                                .resizable()
                                .scaledToFit()
                                .frame(height: trophyHeight)
                            
                            VStack {
                                Text(entry.playerName.truncated(to: podiumMaxPlayerName))
                                    .font(.custom("Comic Lemon", size: 16))
                                    .foregroundColor(Color("CustomLightBrown"))
                                Text("\(entry.score)")
                                    .font(.custom("Comic Lemon", size: 24))
                                    .foregroundColor(Color("CustomLightBrown"))
                                
                                if let picture = entry.profilePicture {
                                    picture
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: podiumProfileSize, height: podiumProfileSize)
                                        .clipShape(Circle())
                                } else {
                                    // Provide a default placeholder image.
                                    Image(systemName: "person.circle.fill")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: podiumProfileSize, height: podiumProfileSize)
                                        .foregroundColor(.gray)
                                }
                            }
                            .offset(y: -38)
                        }
                    }
                    .padding(.horizontal, 100)
                    .frame(width: UIBoxWidth,height: UIBoxHeight*0.75)
                    
                    VStack(spacing: 40) {
                        ForEach(manager.leaderboardEntries.dropFirst(3)) { entry in
                            HStack {
                                Text("\(entry.rank)")
                                    .font(.custom("Comic Lemon", size: 16))
                                    .foregroundColor(.white) // White text for contrast
                                    .frame(width: 30, height: 30) // Fixed size for the circle
                                    .background(
                                        Circle()
                                            .fill(Color("CustomOrange")) // Use your custom color from assets
                                    )
                                    .frame(width: 40) // Keep the outer frame for alignment
                                
                                if let picture = entry.profilePicture {
                                    picture
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 40, height: 40)
                                        .clipShape(Circle())
                                } else {
                                    // Provide a default placeholder image.
                                    Image(systemName: "person.circle.fill")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 40, height: 40)
                                        .foregroundColor(.gray)
                                }
                                
                                Text(entry.playerName)
                                    .font(.custom("Comic Lemon", size: 18))
                                    .foregroundColor(Color("CustomLightBrown"))

                                Spacer()
                                
                                Text("\(entry.score)")
                                    .font(.custom("Comic Lemon", size: 25))
                                    .foregroundColor(Color("CustomLightBrown"))
                            }
                            .background {
                                Image("leaderboard_bar")
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 600.0)
                            }
                        }
                    }
                    .padding(.horizontal, 80)
                    .offset(y: -20)
                }
                .frame(width: UIBoxWidth*0.9, height: UIBoxHeight*0.85)
                .clipped()
            }
            .padding(.top, -60)
        }
        .task {
            await manager.fetchLeaderboard()
        }
        .padding(.top, 20)
        .padding(.leading, 20)
    }
}

#Preview {
    // 1. Create a temporary instance of the manager for the preview.
    let previewManager = GameCenterManager.shared
    
    // 2. Create an array of 6 mock LeaderboardEntry objects.
    let mockEntries = [
        LeaderboardEntry(rank: 1, playerName: "JesseBoy", score: 1000, profilePicture: Image(systemName: "person.circle.fill")),
        LeaderboardEntry(rank: 2, playerName: "Derend", score: 850, profilePicture: Image(systemName: "person.circle.fill")),
        LeaderboardEntry(rank: 3, playerName: "babi_ngepet18", score: 700, profilePicture: Image(systemName: "person.circle.fill")),
        LeaderboardEntry(rank: 4, playerName: "trash_player", score: 550, profilePicture: Image(systemName: "person.circle.fill")),
        LeaderboardEntry(rank: 5, playerName: "rererere", score: 400, profilePicture: Image(systemName: "person.circle.fill")),
        LeaderboardEntry(rank: 6, playerName: "joel", score: 250, profilePicture: Image(systemName: "person.circle.fill"))
    ]
    
    // 3. Assign the mock data to the manager's published property.
    previewManager.leaderboardEntries = mockEntries
    
    // 4. Return the LeaderboardView. It will now use the manager with the mock data.
    return LeaderboardView(isShowing: .constant(true))
}
