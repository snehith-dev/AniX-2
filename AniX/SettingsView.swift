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
                    VStack {
                        ProgressView("Opening AniList...")
                        Text("Please complete login in Safari and return to the app")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        Button("Cancel") {
                            isLoggingIn = false
                        }
                        .buttonStyle(.bordered)
                    }
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
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            // Reset loading state when app becomes active (user returns from Safari)
            if isLoggingIn && !accessToken.isEmpty {
                isLoggingIn = false
                fetchProfile()
            } else if isLoggingIn {
                // Check if we've been waiting too long
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    if accessToken.isEmpty {
                        errorMessage = "Login was cancelled or failed. Please try again."
                        isLoggingIn = false
                    }
                }
            }
        }
    }
    
    private func startAniListLogin() {
        errorMessage = nil
        isLoggingIn = true
        let clientId = "27916" // AniList client ID
        let redirectUri = "anix://auth"
        
        // Properly encode the redirect URI
        guard let encodedRedirectUri = redirectUri.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            errorMessage = "Failed to encode redirect URI."
            isLoggingIn = false
            return
        }
        
        let urlString = "https://anilist.co/api/v2/oauth/authorize?client_id=\(clientId)&redirect_uri=\(encodedRedirectUri)&response_type=token"
        
        guard let url = URL(string: urlString) else {
            errorMessage = "Failed to create login URL."
            isLoggingIn = false
            return
        }
        
#if canImport(UIKit)
        DispatchQueue.main.async {
            UIApplication.shared.open(url) { success in
                DispatchQueue.main.async {
                    if !success {
                        self.errorMessage = "Failed to open Safari for login."
                        self.isLoggingIn = false
                    }
                }
            }
        }
#else
        errorMessage = "Login is only available on iOS devices."
        isLoggingIn = false
#endif
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
        
        do {
            let body = try JSONSerialization.data(withJSONObject: json)
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            request.httpBody = body
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                DispatchQueue.main.async {
                    if let error = error {
                        self.errorMessage = "Network error: \(error.localizedDescription)"
                        return
                    }
                    
                    guard let data = data else {
                        self.errorMessage = "No data received from AniList."
                        return
                    }
                    
                    do {
                        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                            if let errors = json["errors"] as? [[String: Any]] {
                                let errorMessages = errors.compactMap { $0["message"] as? String }
                                self.errorMessage = "AniList error: \(errorMessages.joined(separator: ", "))"
                                // Clear invalid token
                                self.accessToken = ""
                                return
                            }
                            
                            if let dataDict = json["data"] as? [String: Any],
                               let viewer = dataDict["Viewer"] as? [String: Any],
                               let name = viewer["name"] as? String {
                                self.userName = name
                                self.errorMessage = nil
                            } else {
                                self.errorMessage = "Failed to parse profile data."
                            }
                        } else {
                            self.errorMessage = "Invalid response format."
                        }
                    } catch {
                        self.errorMessage = "Failed to parse response: \(error.localizedDescription)"
                    }
                }
            }.resume()
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to create request: \(error.localizedDescription)"
            }
        }
    }
} 
