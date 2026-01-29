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
        
        currentScreen = .loading
        
        // 1. Onboarding non terminé
        guard hasCompletedOnboarding else {
            
            currentScreen = .onboarding
            return
        }
        
        // 2. Vérifier authentification
        await authService.checkAuthStatus()
        
        guard authService.isAuthenticated else {
           
            currentScreen = .auth
            return
        }
        
        // 3. Vérifier compagnon
        let hasCompanion = await userDataService.checkCompanion()
        
        guard hasCompanion else {
            
            currentScreen = . companionSelection
            return
        }
        
        // 4. Charger données
        do {
            try await userDataService.loadAllData()
            
            currentScreen = .main
        } catch {
            print(" AppState:  Erreur chargement données:  \(error)")
            currentScreen = .auth
        }
    }
    
    /// Appelé après connexion (Email ou Google)
    func handleAuthentication() async {
        
        
        // Petit délai pour stabiliser la session (surtout pour Google OAuth)
        try?  await Task.sleep(nanoseconds: 300_000_000) // 0.3s
        
        await initialize(hasCompletedOnboarding: true)
    }
    
    /// Appelé après sélection du compagnon
    func handleCompanionSelected() async {
        
        currentScreen = .loading
        
        do {
            try await userDataService.loadAllData()
            
            currentScreen = .main
        } catch {
            print(" AppState: Erreur chargement après compagnon: \(error)")
            currentScreen = .auth
        }
    }
    
    /// Appelé lors de la déconnexion
    func handleSignOut() {
        
        userDataService.reset()
        currentScreen = .auth
    }
}
