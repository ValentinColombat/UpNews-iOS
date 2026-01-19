// ContentView.swift

import SwiftUI
import Supabase

struct ContentView: View {
    
    // MARK: - App Storage
    
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    // MARK: - State
    
    @StateObject private var authService = AuthService.shared
    @State private var hasSelectedCompanion = false
    @State private var isCheckingCompanion = true
    
    // MARK: - Body
    
    var body: some View {
        let _ = print("🔍 hasOnboarding: \(hasCompletedOnboarding), isAuth: \(authService.isAuthenticated), hasCompanion: \(hasSelectedCompanion)")
        
        return Group {
            if !hasCompletedOnboarding {
                // 1. Onboarding (première ouverture)
                OnboardingView {
                    hasCompletedOnboarding = true
                }
            } else if !authService.isAuthenticated {
                // 2. Authentification (après onboarding)
                AuthView()
            } else if isCheckingCompanion {
                // 3. Vérification du compagnon en cours
                ProgressView("Chargement...")
                    .tint(.upNewsPrimary)
            } else if !hasSelectedCompanion {
                // 4. Sélection du compagnon (première connexion)
                CompanionSelectionView {
                    hasSelectedCompanion = true
                }
            } else {
                // 5. App principale (tout est OK)
                MainTabView()
            }
        }
        .animation(.easeInOut, value: hasCompletedOnboarding)
        .animation(.easeInOut, value: authService.isAuthenticated)
        .animation(.easeInOut, value: hasSelectedCompanion)
        .task {
            await authService.checkAuthStatus()
        }
        .onAppear {
            if authService.isAuthenticated && isCheckingCompanion {
                Task {
                    await checkCompanionSelection()
                }
            }
        }
        .onChange(of: authService.isAuthenticated) { _, isAuth in
            if isAuth {
                // Petit délai pour laisser l'auth se stabiliser
                Task {
                    try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconde
                    await checkCompanionSelection()
                }
            } else {
                // Reset si déconnexion
                hasSelectedCompanion = false
                isCheckingCompanion = true
            }
        }
    }
    
    // MARK: - Functions
    
    private func checkCompanionSelection() async {
        await MainActor.run {
            isCheckingCompanion = true
        }
        
        do {
            let session = try await SupabaseConfig.client.auth.session
            
            // Vérifier si l'utilisateur a un compagnon
            struct UserCompanion: Decodable {
                let selected_companion_id: String?
            }
            
            let response = try await SupabaseConfig.client
                .from("users")
                .select("selected_companion_id")
                .eq("id", value: session.user.id.uuidString)
                .execute()
            
            // Décoder manuellement
            let users = try JSONDecoder().decode([UserCompanion].self, from: response.data)
            
            await MainActor.run {
                if let user = users.first {
                    hasSelectedCompanion = user.selected_companion_id != nil && !(user.selected_companion_id?.isEmpty ?? true)
                } else {
                    // Aucun utilisateur trouvé, forcer la sélection
                    hasSelectedCompanion = false
                }
                isCheckingCompanion = false
            }
            
            print("✅ Compagnon check: \(users.first?.selected_companion_id ?? "nil")")
            
        } catch {
            print("❌ Erreur vérification compagnon: \(error)")
            await MainActor.run {
                // En cas d'erreur, on force la sélection pour être sûr
                hasSelectedCompanion = false
                isCheckingCompanion = false
            }
        }
    }
}

#Preview {
    ContentView()
}
