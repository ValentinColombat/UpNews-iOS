//
//  AppStateService.swift
//  UpNews-iOS
//
//  Created by Valentin Colombat on 21/01/2026.

import SwiftUI
import Combine

@MainActor
class AppStateService:  ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = AppStateService()
    
    // MARK: - Published State
    
    @Published var currentScreen: AppScreen = .loading
    
    // MARK: - Dependencies
    
    private let authService = AuthService.shared
    private let userDataService = UserDataService.shared
    
    // MARK: - App Screen Enum
    
    enum AppScreen {
        case loading
        case onboarding
        case auth
        case companionSelection
        case main
    }
    
    // MARK: - Init
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Point d'entrée unique pour initialiser l'app
    func initialize(hasCompletedOnboarding: Bool) async {
        print(" AppState:  initialize()")
        currentScreen = .loading
        
        // 1. Onboarding non terminé
        guard hasCompletedOnboarding else {
            print(" AppState: Onboarding non terminé")
            currentScreen = .onboarding
            return
        }
        
        // 2. Vérifier authentification
        await authService.checkAuthStatus()
        
        guard authService.isAuthenticated else {
            print(" AppState: Non authentifié")
            currentScreen = .auth
            return
        }
        
        // 3. Vérifier compagnon
        let hasCompanion = await userDataService.checkCompanion()
        
        guard hasCompanion else {
            print(" AppState: Pas de compagnon")
            currentScreen = . companionSelection
            return
        }
        
        // 4. Charger données
        do {
            try await userDataService.loadAllData()
            print(" AppState: Données chargées, navigation vers main")
            currentScreen = .main
        } catch {
            print(" AppState:  Erreur chargement données:  \(error)")
            currentScreen = .auth
        }
    }
    
    /// Appelé après connexion (Email ou Google)
    func handleAuthentication() async {
        print(" AppState: handleAuthentication()")
        
        // Petit délai pour stabiliser la session (surtout pour Google OAuth)
        try?  await Task.sleep(nanoseconds: 300_000_000) // 0.3s
        
        await initialize(hasCompletedOnboarding: true)
    }
    
    /// Appelé après sélection du compagnon
    func handleCompanionSelected() async {
        print(" AppState: handleCompanionSelected()")
        currentScreen = .loading
        
        do {
            try await userDataService.loadAllData()
            print(" AppState: Données chargées après sélection compagnon")
            currentScreen = .main
        } catch {
            print(" AppState: Erreur chargement après compagnon: \(error)")
            currentScreen = .auth
        }
    }
    
    /// Appelé lors de la déconnexion
    func handleSignOut() {
        print(" AppState: handleSignOut()")
        userDataService.reset()
        currentScreen = .auth
    }
}
