// UpNews-iOSApp

import SwiftUI
import Supabase
import Auth
import GoogleSignIn

@main
struct UpNews_iOSApp: App {
    
   
    init() {
        configureGoogleSignIn()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    // Gère le callback Google
                    GIDSignIn.sharedInstance.handle(url)
                    
                    // Puis le callback Supabase
                    Task {
                        do {
                            try await SupabaseConfig.client.auth.session(from: url)
                            await MainActor.run {
                                AuthService.shared.isAuthenticated = true
                            }
                            print("Connexion Google réussie")
                        } catch {
                            print("Erreur callback Google: \(error)")
                        }
                    }
                }
        }
    }
    
    private func configureGoogleSignIn() {
        
        let clientID = GoogleSecrets.clientID
        
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
    }
}
