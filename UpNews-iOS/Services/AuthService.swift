//
//  AuthService.swift
//  UpNews-iOS
//
//  Created on 18/12/2025.
//

import Foundation
import Combine
import Supabase
import GoogleSignIn
import UIKit

/// Service pour gérer l'authentification utilisateur
class AuthService: ObservableObject {
    
    // MARK:  - Singleton
    
    static let shared = AuthService()
    
    // MARK: - Published Properties
    
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let client:  SupabaseClient
    
    // MARK: - Initialisation
    
    private init() {
        self.client = SupabaseConfig.client
    }
    
    // MARK: - Auth Methods
    
    /// Vérifie si l'utilisateur est déjà connecté
    @MainActor
    func checkAuthStatus() async {
        do {
            let session = try await client.auth.session
            isAuthenticated = true
            currentUser = session.user
        } catch {
            isAuthenticated = false
            currentUser = nil
        }
    }
    
    // MARK: - Connexion
    
    @MainActor
    func signIn(email: String, password:  String) async {
        isLoading = true
        errorMessage = nil
        
        // Nettoyage
        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let cleanPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Validation
        guard !cleanEmail.isEmpty, !cleanPassword.isEmpty else {
            errorMessage = "Email et mot de passe requis"
            isLoading = false
            return
        }
        
        do {
            let session = try await client.auth.signIn(
                email: cleanEmail,
                password: cleanPassword
            )
            
            isAuthenticated = true
            currentUser = session.user
            
            // Naviguer vers l'écran principal
            Task {
                await AppStateService.shared.handleAuthentication()
            }
            
        } catch {
            let errorDesc = error.localizedDescription
            
            if errorDesc.contains("Invalid login credentials") {
                errorMessage = "Email ou mot de passe incorrect.  Si tu t'es inscrit avec Google, utilise le bouton Google."
            } else if errorDesc.contains("Email not confirmed") {
                errorMessage = "Vérifie ton email pour confirmer ton compte."
            } else {
                errorMessage = "Erreur de connexion:  \(errorDesc)"
            }
            
            isAuthenticated = false
        }
        
        isLoading = false
    }
    
    // MARK: - Inscription
    
    @MainActor
    func signUp(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        
        // Nettoyage
        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let cleanPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Validation
        guard !cleanEmail.isEmpty else {
            errorMessage = "Email requis"
            isLoading = false
            return
        }
        
        guard cleanPassword.count >= 6 else {
            errorMessage = "Le mot de passe doit contenir au moins 6 caractères"
            isLoading = false
            return
        }
        
        do {
            let session = try await client.auth.signUp(
                email: cleanEmail,
                password: cleanPassword
            )
            
            isAuthenticated = true
            currentUser = session.user
            
            // Naviguer vers l'écran principal
            Task {
                await AppStateService.shared.handleAuthentication()
            }
            
        } catch {
            errorMessage = "Erreur d'inscription: \(error.localizedDescription)"
            isAuthenticated = false
        }
        
        isLoading = false
    }
    
    // MARK: - Google Sign In
    
    @MainActor
    func signInWithGoogle() async {
        isLoading = true
        errorMessage = nil
        
        do {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                          let presentingVC = windowScene.windows.first?.rootViewController else {
                        errorMessage = "Impossible d'accéder au contrôleur de présentation"
                        isLoading = false
                        return
                
            }
            
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presentingVC)
            
            guard let idToken = result.user.idToken?.tokenString else {
                errorMessage = "Impossible de récupérer le token Google"
                isLoading = false
                return
            }
            
            let accessToken = result.user.accessToken.tokenString
            
            let session = try await client.auth.signInWithIdToken(
                credentials: . init(
                    provider: .google,
                    idToken: idToken,
                    accessToken: accessToken
                )
            )
            
            isAuthenticated = true
            currentUser = session.user
            
            // Naviguer vers l'écran principal
            Task {
                await AppStateService.shared.handleAuthentication()
            }
            
            // Note: Le display_name sera demandé lors de la sélection du compagnon
            
        } catch {
            errorMessage = "Erreur connexion Google: \(error.localizedDescription)"
            isAuthenticated = false
        }
        
        isLoading = false
    }
    
    // MARK: - Apple Sign In
    
    @MainActor
    func signInWithApple(
        userIdentifier: String,
        email: String?,
        fullName: PersonNameComponents?,
        identityToken: String
    ) async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Authentification avec Supabase via le token Apple
            let session = try await client.auth.signInWithIdToken(
                credentials: .init(
                    provider: .apple,
                    idToken: identityToken
                )
            )
            
            isAuthenticated = true
            currentUser = session.user
            
            // Naviguer vers l'écran principal
            Task {
                await AppStateService.shared.handleAuthentication()
            }
            
        } catch {
            errorMessage = "Erreur connexion Apple: \(error.localizedDescription)"
            isAuthenticated = false
        }
        
        isLoading = false
    }
    
    // MARK: - Déconnexion
    
    @MainActor
    func signOut() async {
        do {
            try await client.auth.signOut()
            isAuthenticated = false
            currentUser = nil
            AppStateService.shared.handleSignOut()
        } catch {
            // Erreur silencieuse lors de la déconnexion
        }
    }
}
