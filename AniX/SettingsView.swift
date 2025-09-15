import Foundation
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Account")) {
                    NavigationLink(destination: AccountView()) {
                        Label("Account", systemImage: "person.circle")
                    }
                }
                NavigationLink(destination: ThemeSettingsView()) {
                    Label("Theme", systemImage: "paintbrush")
                }
                NavigationLink(destination: Text("About AniX")) {
                    Label("About", systemImage: "info.circle")
                }
            }
            .navigationTitle("Settings")
        }
    }
}

struct ThemeSettingsView: View {
    @AppStorage("colorScheme") private var colorScheme: String = "system"
    var body: some View {
        Form {
            Picker("Appearance", selection: $colorScheme) {
                Text("System").tag("system")
                Text("Light").tag("light")
                Text("Dark").tag("dark")
            }
            .pickerStyle(.segmented)
        }
        .navigationTitle("Theme")
    }
}

struct AccountView: View {
    @AppStorage("anilistAccessToken") private var accessToken: String = ""
    @State private var isLoggingIn = false
    @State private var errorMessage: String? = nil
    @State private var userName: String? = nil
    
    var body: some View {
        VStack(spacing: 24) {
            if !accessToken.isEmpty {
                if let userName = userName {
                    Text("Logged in as \(userName)")
                        .font(.headline)
                } else {
                    ProgressView("Fetching profile...")
                        .onAppear(perform: fetchProfile)
                }
                Button("Logout") {
                    accessToken = ""
                    userName = nil
                }
                .buttonStyle(.borderedProminent)
            } else {
                if isLoggingIn {
                    ProgressView("Waiting for login...")
                } else {
                    Button("Login with AniList") {
                        startAniListLogin()
                    }
                    .buttonStyle(.borderedProminent)
                }
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .padding()
        .onOpenURL { url in
            handleRedirect(url: url)
        }
    }
    
    private func startAniListLogin() {
        errorMessage = nil
        isLoggingIn = true
        let clientId = "27916" // AniList client ID
        let redirectUri = "anix://auth"
        let urlString = "https://anilist.co/api/v2/oauth/authorize?client_id=\(clientId)&redirect_uri=\(redirectUri)&response_type=token"
        if let url = URL(string: urlString) {
#if canImport(UIKit)
            UIApplication.shared.open(url)
#endif
        } else {
            errorMessage = "Failed to create login URL."
            isLoggingIn = false
        }
    }
    
    private func handleRedirect(url: URL) {
        // Parse access_token from URL fragment
        guard let fragment = url.fragment else {
            errorMessage = "No token in redirect."
            isLoggingIn = false
            return
        }
        let params = fragment.components(separatedBy: "&").reduce(into: [String: String]()) { dict, pair in
            let parts = pair.components(separatedBy: "=")
            if parts.count == 2 {
                dict[parts[0]] = parts[1]
            }
        }
        if let token = params["access_token"] {
            accessToken = token
            isLoggingIn = false
            fetchProfile()
        } else {
            errorMessage = "Login failed: No access token."
            isLoggingIn = false
        }
    }
    
    private func fetchProfile() {
        guard !accessToken.isEmpty else { return }
        let url = URL(string: "https://graphql.anilist.co")!
        let query = """
        query { Viewer { name } }
        """
        let json: [String: Any] = [
            "query": query
        ]
        let body = try! JSONSerialization.data(withJSONObject: json)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.httpBody = body
        URLSession.shared.dataTask(with: request) { data, _, error in
            guard let data = data else {
                DispatchQueue.main.async {
                    errorMessage = "Failed to fetch profile."
                }
                return
            }
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let dataDict = json["data"] as? [String: Any],
                   let viewer = dataDict["Viewer"] as? [String: Any],
                   let name = viewer["name"] as? String {
                    DispatchQueue.main.async {
                        userName = name
                    }
                } else {
                    DispatchQueue.main.async {
                        errorMessage = "Failed to parse profile."
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    errorMessage = "Error parsing profile."
                }
            }
        }.resume()
    }
} 
