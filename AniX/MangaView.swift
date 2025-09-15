import SwiftUI
import Foundation

struct MangaView: View {
    @State private var searchText = ""
    @State private var results: [AniListMedia] = []
    @State private var isSearching = false
    @State private var showSearchBar = false
    var body: some View {
        NavigationStack {
            VStack {
                if showSearchBar {
                    TextField("Search Manga", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding([.horizontal, .top])
                        .onChange(of: searchText) { newValue in
                            if !newValue.isEmpty {
                                isSearching = true
                                AniListAPI.searchManga(query: newValue) { found in
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
            }
            .navigationTitle("Manga")
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
    MangaView()
} 