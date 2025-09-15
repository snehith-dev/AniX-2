//
//  AniXApp.swift
//  AniX
//
//  Created by Snehith Kothakota on 25/06/25.
//

import SwiftUI

@main
struct AniXApp: App {
    @AppStorage("colorScheme") private var colorScheme: String = "system"
    @AppStorage("anilistAccessToken") private var accessToken: String = ""
    @State private var isLoggingIn = false
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(
                    colorScheme == "light" ? .light :
                    colorScheme == "dark" ? .dark : nil
                )
        }
        .onOpenURL { url in
            handleAniListRedirect(url: url)
        }
    }
    
    private func handleAniListRedirect(url: URL) {
        // Check if this is an AniList auth redirect
        guard url.scheme == "anix", url.host == "auth" else { return }
        
        // Parse access_token from URL fragment
        guard let fragment = url.fragment else { return }
        
        let params = fragment.components(separatedBy: "&").reduce(into: [String: String]()) { dict, pair in
            let parts = pair.components(separatedBy: "=")
            if parts.count == 2 {
                dict[parts[0]] = parts[1]
            }
        }
        
        if let token = params["access_token"] {
            accessToken = token
        }
    }
}
