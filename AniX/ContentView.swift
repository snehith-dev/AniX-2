//
//  ContentView.swift
//  AniX
//
//  Created by Snehith Kothakota on 25/06/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            AnimeView()
                .tabItem {
                    Label("Anime", systemImage: "film")
                }
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house")
                }
            MangaView()
                .tabItem {
                    Label("Manga", systemImage: "book")
                }
        }
    }
}

#Preview {
    ContentView()
}
