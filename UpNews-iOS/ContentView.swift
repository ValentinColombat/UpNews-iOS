//
//  ContentView.swift
//  UpNews-iOS

import SwiftUI
import Supabase
import Auth

struct ContentView: View {
    
    // MARK: - State
    
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @StateObject private var authService = AuthService.shared
    @ObservedObject private var userDataService = UserDataService.shared
    
    @State private var isLoading = true
    @State private var needsCompanionSelection = false
    @State private var hasInitialized = false
    
    // MARK: - Body
    
    var body: some View {
        Group {
            if !hasCompletedOnboarding {
                // Cas 1 : Première ouverture → Onboarding
                OnboardingView {
                    hasCompletedOnboarding = true
                }
            } else if isLoading {
                // Cas 2 : Chargement en cours
                LoadingView(message: "")
            } else if !authService.isAuthenticated {
                // Cas 3 :  Pas connecté → AuthView
                AuthView()
            } else if needsCompanionSelection {
                // Cas 4 :  Premier compagnon à sélectionner
                CompanionSelectionView {
                    needsCompanionSelection = false
                    // Recharger après sélection
                    Task {
                        isLoading = true
                        await loadUserData()
                        isLoading = false
                    }
                }
            } else {
                // Cas 5 : App principale
                MainTabView()
                    .environmentObject(userDataService)
            }
        }
        .task {
            await initialize()
            hasInitialized = true
        }
        .onChange(of: authService.isAuthenticated) { oldValue, isAuth in
            if !isAuth {
                // Déconnexion
                userDataService.reset()
                needsCompanionSelection = false
                isLoading = false
            } else if oldValue == false && isAuth == true {
                //  Connexion réussie (Email OU Google)
                Task {
                    isLoading = true
                    
                    //  Petit délai UNIQUEMENT pour Google OAuth
                    try? await Task.sleep(nanoseconds: 200_000_000)  // 0.2s
                    
                    await initialize()  //  Relance pour charger les données
                }
            }
        }
    }
    
    // MARK: - Initialization
    
    private func initialize() async {
        guard hasCompletedOnboarding else {
            isLoading = false
            return
        }
        
        isLoading = true
        
        // 1. Vérifier l'authentification
        await authService.checkAuthStatus()
        
        guard authService.isAuthenticated else {
            isLoading = false
            return
        }
        
        // 2. Vérifier si l'utilisateur a un compagnon
        let hasCompanion = await checkCompanion()
        
        if !hasCompanion {
            // Première connexion → sélection obligatoire
            needsCompanionSelection = true
            isLoading = false
            return
        }
        
        // 3. Charger les données
        await loadUserData()
        
        isLoading = false
    }
    
    /// Retourne true si l'utilisateur a un compagnon, false sinon
    private func checkCompanion() async -> Bool {
        do {
            let session = try await SupabaseConfig.client.auth.session
            
            struct UserCompanion: Decodable {
                let selected_companion_id: String?
            }
            
            let response = try await SupabaseConfig.client
                .from("users")
                .select("selected_companion_id")
                .eq("id", value: session.user.id.uuidString)
                .execute()
            
            let users = try JSONDecoder().decode([UserCompanion].self, from: response.data)
            
            if let companion = users.first?.selected_companion_id, !companion.isEmpty {
                print(" Compagnon trouvé : \(companion)")
                return true
            } else {
                print(" Pas de compagnon → sélection nécessaire")
                return false
            }
        } catch {
            print(" Erreur vérification compagnon : \(error)")
            return false
        }
    }
    
    private func loadUserData() async {
        do {
            try await userDataService.loadAllData()
            print("✅ Données chargées dans ContentView")
        } catch {
            print("❌ Erreur chargement :  \(error)")
        }
    }
}
