import SwiftUI

struct HomeView: View {
    @State private var showSettings = false
    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                HStack(spacing: 24) {
                    NavigationLink(destination: AnimeView()) {
                        ZStack(alignment: .bottom) {
                            Image("anime_bg")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 170, height: 70)
                                .clipped()
                                .cornerRadius(28)
                                .overlay(Color.black.opacity(0.35).cornerRadius(28))
                            VStack(spacing: 8) {
                                Text("ANIME LIST")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(.white)
                                Rectangle()
                                    .fill(Color.purple)
                                    .frame(width: 80, height: 4)
                                    .cornerRadius(2)
                            }
                            .padding(.bottom, 18)
                        }
                    }
                    NavigationLink(destination: MangaView()) {
                        ZStack(alignment: .bottom) {
                            Image("manga_bg")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 170, height: 70)
                                .clipped()
                                .cornerRadius(28)
                                .overlay(Color.black.opacity(0.35).cornerRadius(28))
                            VStack(spacing: 8) {
                                Text("MANGA LIST")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(.white)
                                Rectangle()
                                    .fill(Color.purple)
                                    .frame(width: 80, height: 4)
                                    .cornerRadius(2)
                            }
                            .padding(.bottom, 18)
                        }
                    }
                }
                Spacer()
            }
            .padding(.top, 60)
            .navigationTitle("Home")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showSettings = true
                    }) {
                        Image(systemName: "gearshape")
                    }
                }
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
    }
}

#Preview {
    HomeView()
} 