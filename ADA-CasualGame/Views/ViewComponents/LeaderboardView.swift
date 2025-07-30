import SwiftUI

struct LeaderboardView: View {
    @Binding var isShowing: Bool
    @StateObject private var manager = GameCenterManager.shared
    
    var body: some View {
        ZStack {
            
            VStack {
                Text("High Scores")
                    .font(.custom("Comic Lemon", size: 36))
                    .bold()
                    .padding(.bottom, 20)
                
                ScrollView {
                    ForEach(manager.leaderboardEntries) { entry in
                        HStack {
                            Text("\(entry.rank).")
                                .font(.headline)
                                .frame(width: 40)
                            
                            Text(entry.playerName)
                                .font(.headline)
                            
                            Spacer()
                            
                            Text("\(entry.score)")
                                .font(.headline)
                                .bold()
                        }
                        .padding(.vertical, 8)
                        Divider()
                    }
                }
                
                Button("Back") {
                    isShowing = false
                }
                .font(.headline)
                .foregroundColor(.primary)
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(10)
            }
        }
        .padding()
        .onAppear {
            manager.fetchLeaderboard()
        }
    }
}

#Preview {
    LeaderboardView(isShowing: .constant(true))
}
