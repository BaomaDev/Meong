import SwiftUI

struct LeaderboardView: View {
    @Binding var isShowing: Bool
    @StateObject private var manager = GameCenterManager.shared
    
    // This placeholder is used if the leaderboard has fewer than 3 players.
    let placeholderEntry = LeaderboardEntry(rank: 0, playerName: "Player", score: 0, profilePicture: nil)
    
    // MARK: - State for Scroll Tracking
    @State private var scrollOffset: CGFloat = 0
    @State private var contentHeight: CGFloat = 0
    
    // Constants for podium styling
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
            
            // Main UI Content VStack
            VStack {
                Image("leaderboard_banner")
                    .resizable()
                    .scaledToFit()
                    .frame(width: UIBoxWidth/2, height: UIBoxHeight/4)
                    .padding(.top, 50)

                ScrollView {
                    // This VStack contains all the scrollable content
                    VStack {
                        // --- Top 3 Podiums ---
                        HStack {
                            // 2nd Place
                            PodiumView(
                                entry: manager.leaderboardEntries.indices.contains(1) ? manager.leaderboardEntries[1] : placeholderEntry,
                                podiumImage: "podium_2",
                                trophyHeight: trophyHeight,
                                profileSize: podiumProfileSize,
                                maxNameLength: podiumMaxPlayerName
                            )
                            
                            Spacer()
                            
                            // 1st Place
                            PodiumView(
                                entry: manager.leaderboardEntries.indices.contains(0) ? manager.leaderboardEntries[0] : placeholderEntry,
                                podiumImage: "podium_1",
                                trophyHeight: trophyHeight * 1.35,
                                profileSize: podiumProfileSize,
                                maxNameLength: podiumMaxPlayerName
                            )
                            
                            Spacer()
                            
                            // 3rd Place
                            PodiumView(
                                entry: manager.leaderboardEntries.indices.contains(2) ? manager.leaderboardEntries[2] : placeholderEntry,
                                podiumImage: "podium_3",
                                trophyHeight: trophyHeight,
                                profileSize: podiumProfileSize,
                                maxNameLength: podiumMaxPlayerName
                            )
                        }
                        .padding(.horizontal, 100)
                        .frame(width: UIBoxWidth, height: UIBoxHeight * 0.75)
                        
                        // --- Ranks 4 and below ---
                        VStack(spacing: 40) {
                            ForEach(manager.leaderboardEntries.dropFirst(3)) { entry in
                                HStack {
                                    Text("\(entry.rank)")
                                        .font(.custom("Comic Lemon", size: 16))
                                        .foregroundColor(.white)
                                        .frame(width: 30, height: 30)
                                        .background(
                                            Circle().fill(Color("CustomOrange"))
                                        )
                                        .frame(width: 40)
                                    
                                    if let picture = entry.profilePicture {
                                        picture
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 40, height: 40)
                                            .clipShape(Circle())
                                    } else {
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
                    .background(
                        GeometryReader { contentProxy in
                            Color.clear
                                .onAppear { self.contentHeight = contentProxy.size.height }
                        }
                    )
                    .background(
                        GeometryReader { proxy in
                            Color.clear
                                .onChange(of: proxy.frame(in: .named("scroll")).minY) { _, newMinY in
                                    self.scrollOffset = -newMinY
                                }
                        }
                    )
                }
                .scrollIndicators(.hidden)
                .coordinateSpace(name: "scroll")
                .customScrollIndicator(
                    scrollOffset: $scrollOffset,
                    contentHeight: $contentHeight,
                    positionXoffset: -30.0
                )
            }
            .frame(width: UIBoxWidth, height: UIBoxHeight*1.3)
            .padding(.top, -60)
            .padding(.leading, 10)
            .clipped()
            
            // Close Button
            Button(action: {
                isShowing = false
            }){
                Image("CloseButton")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 50)
            }
            .position(x: 60, y: 50)
        }
        .task {
            await manager.fetchLeaderboard()
        }
        .padding(.top, 20)
        .padding(.leading, 20)
    }
}

/// A reusable view for the top 3 player podiums.
struct PodiumView: View {
    let entry: LeaderboardEntry
    let podiumImage: String
    let trophyHeight: CGFloat
    let profileSize: CGFloat
    let maxNameLength: Int
    
    var body: some View {
        ZStack {
            Image(podiumImage)
                .resizable()
                .scaledToFit()
                .frame(height: trophyHeight)
            
            VStack {
                Text(entry.playerName.truncated(to: maxNameLength))
                    .font(.custom("Comic Lemon", size: 16))
                    .foregroundColor(Color("CustomLightBrown"))
                Text("\(entry.score)")
                    .font(.custom("Comic Lemon", size: 24))
                    .foregroundColor(Color("CustomLightBrown"))
                    .padding(.bottom, entry.rank == 1 ? 16 : 0) // Extra padding for 1st place
                
                if let picture = entry.profilePicture {
                    picture
                        .resizable()
                        .scaledToFit()
                        .frame(width: profileSize, height: profileSize)
                        .clipShape(Circle())
                } else {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: profileSize, height: profileSize)
                        .foregroundColor(.gray)
                }
            }
            .offset(y: entry.rank == 1 ? -44 : -38)
        }
        .frame(width: UIBoxWidth/5)
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
        LeaderboardEntry(rank: 6, playerName: "joel", score: 250, profilePicture: Image(systemName: "person.circle.fill")),
        LeaderboardEntry(rank: 7, playerName: "joel", score: 250, profilePicture: Image(systemName: "person.circle.fill")),
        LeaderboardEntry(rank: 8, playerName: "joel", score: 250, profilePicture: Image(systemName: "person.circle.fill")),
        LeaderboardEntry(rank: 9, playerName: "joel", score: 250, profilePicture: Image(systemName: "person.circle.fill"))
    ]
    
    // 3. Assign the mock data to the manager's published property.
    previewManager.leaderboardEntries = mockEntries
    
    // 4. Return the LeaderboardView. It will now use the manager with the mock data.
    return LeaderboardView(isShowing: .constant(true))
}
