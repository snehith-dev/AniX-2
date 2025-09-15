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
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(
                    colorScheme == "light" ? .light :
                    colorScheme == "dark" ? .dark : nil
                )
        }
    }
}
