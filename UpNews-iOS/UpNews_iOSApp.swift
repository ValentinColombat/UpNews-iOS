// UpNews-iOSApp

import SwiftUI
import Supabase
import Auth
import GoogleSignIn
import UserNotifications

@main
struct UpNews_iOSApp: App {
    
    @Environment(\.scenePhase) private var scenePhase
   
    init() {
        configureGoogleSignIn()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.light) // ✅ Force le Light Mode partout
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
                            
                        } catch {
                            print("Erreur session Supabase depuis URL: \(error)")
                        }
                    }
                }
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .active {
                // L'app devient active → effacer le badge des notifications
                clearNotificationBadge()
            }
        }
    }
    
    private func configureGoogleSignIn() {
        
        let clientID = GoogleSecrets.clientID
        
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
    }
    
    // MARK: - Notification Badge Management
    
    /// Efface le badge de notification quand l'app est ouverte
    private func clearNotificationBadge() {
        Task {
            do {
                // Effacer le badge (pastille rouge)
                try await UNUserNotificationCenter.current().setBadgeCount(0)
                
                // Effacer aussi les notifications du centre de notifications
                UNUserNotificationCenter.current().removeAllDeliveredNotifications()
                
                
            } catch {
                print("Erreur effacement badge notification: \(error)")
            }
        }
    }
}
