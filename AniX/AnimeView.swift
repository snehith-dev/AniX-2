import SwiftUI
import Foundation

struct AnimeView: View {
    @State private var searchText = ""
    @State private var results: [AniListMedia] = []
    @State private var isSearching = false
    @State private var showSearchBar = false
    @AppStorage("anilistAccessToken") private var accessToken: String = ""
    @State private var userList: [AniListMedia] = []
    @State private var userListLoaded = false
    @State private var errorMessage: String? = nil
    var body: some View {
        NavigationStack {
            VStack {
                if !accessToken.isEmpty {
                    if !userListLoaded {
                        ProgressView("Loading your anime list...")
                            .onAppear {
                                AniListAPI.fetchUserAnimeList(accessToken: accessToken) { list in
                                    self.userList = list
                                    self.userListLoaded = true
                                }
                            }
                    } else {
                        if userList.isEmpty {
                            Text("No anime found in your list.")
                        } else {
                            List(userList) { media in
                                HStack(spacing: 16) {
                                    if let url = media.imageUrl, let imageUrl = URL(string: url) {
                                        AsyncImage(url: imageUrl) { image in
                                            image.resizable().aspectRatio(contentMode: .fill)
                                        } placeholder: {
                                            Color.gray.opacity(0.2)
                                        }
                                        .frame(width: 60, height: 80)
                                        .cornerRadius(8)
                                    }
                                    Text(media.title)
                                        .font(.headline)
                                }
                            }
                            .listStyle(.plain)
                        }
                    }
                } else {
                    if showSearchBar {
                        TextField("Search Anime", text: $searchText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding([.horizontal, .top])
                            .onChange(of: searchText) { newValue in
                                if !newValue.isEmpty {
                                    isSearching = true
                                    AniListAPI.searchAnime(query: newValue) { found in
                                        self.results = found
                                        self.isSearching = false
                                    }
                                } else {
                                    results = []
                                }
                            }
                    }
                    if isSearching {
                        ProgressView()
                    }
                    List(results) { media in
                        HStack(spacing: 16) {
                            if let url = media.imageUrl, let imageUrl = URL(string: url) {
                                AsyncImage(url: imageUrl) { image in
                                    image.resizable().aspectRatio(contentMode: .fill)
                                } placeholder: {
                                    Color.gray.opacity(0.2)
                                }
                                .frame(width: 60, height: 80)
                                .cornerRadius(8)
                            }
                            Text(media.title)
                                .font(.headline)
                        }
                    }
                    .listStyle(.plain)
                    if errorMessage != nil {
                        Text(errorMessage!)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Anime")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        withAnimation { showSearchBar.toggle() }
                        if !showSearchBar {
                            searchText = ""
                            results = []
                        }
                    }) {
                        Image(systemName: "magnifyingglass")
                    }
                }
            }
        }
    }
}

#Preview {
    AnimeView()
} 