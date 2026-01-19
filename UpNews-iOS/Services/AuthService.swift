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

/// Service pour gérer l'authentification utilisateur
class AuthService: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = AuthService()
    
    // MARK: - Published Properties
    
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let client: SupabaseClient
    
    // MARK: - Initialisation
    
    private init() {
        self.client = SupabaseConfig.client
        // Ne pas vérifier automatiquement, laisser false par défaut
        // checkAuthStatus()
    }
    
    // MARK: - Auth Methods
    
    /// Vérifie si l'utilisateur est déjà connecté
    @MainActor
    func checkAuthStatus() {
        Task {
            do {
                let session = try await client.auth.session
                isAuthenticated = true
                currentUser = session.user
            } catch {
                isAuthenticated = false
                currentUser = nil
            }
        }
    }
    
    /// Connexion avec email/mot de passe
    @MainActor
    func signIn(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let session = try await client.auth.signIn(
                email: email,
                password: password
            )
            
            isAuthenticated = true
            currentUser = session.user
        } catch {
            errorMessage = "Erreur de connexion : \(error.localizedDescription)"
            isAuthenticated = false
        }
        
        isLoading = false
    }
    
    /// Inscription avec email/mot de passe
    @MainActor
    func signUp(email: String, password: String, username: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Étape 1 : Créer le compte auth
            let session = try await client.auth.signUp(
                email: email,
                password: password,
                data: ["username": .string(username)]
            )
            
            // Étape 2 : Créer l'entrée users manuellement
            struct NewUser: Encodable {
                let id: String
                let email: String
                let display_name: String
                let total_points: Int
                let current_streak: Int
            }
            
            let newUser = NewUser(
                id: session.user.id.uuidString, 
                email: email,
                display_name: username,
                total_points: 0,
                current_streak: 0,
            )
            
            try await client
                .from("users")
                .insert(newUser)
                .execute()
            
            isAuthenticated = true
            currentUser = session.user
            
        } catch {
            errorMessage = "Erreur d'inscription : \(error.localizedDescription)"
            isAuthenticated = false
        }
        
        isLoading = false
    }
    
    // MARK : - Google Sign In (Native iOS)
    
    /// Connexion native avec Google puis Supabase

    @MainActor
    func signInWithGoogle() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Étape 1 : Obtenir le root view controller
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let rootViewController = windowScene.windows.first?.rootViewController else {
                throw NSError(domain: "AuthService", code: -1,
                            userInfo: [NSLocalizedDescriptionKey: "Cannot find root view controller"])
            }
            
            // Étape 2 : Sign in avec Google nativement
            let result = try await GIDSignIn.sharedInstance.signIn(
                withPresenting: rootViewController
            )
            
            guard let idToken = result.user.idToken?.tokenString else {
                throw NSError(domain: "AuthService", code: -2,
                            userInfo: [NSLocalizedDescriptionKey: "No ID token from Google"])
            }
            
            let accessToken = result.user.accessToken.tokenString
            
            // Étape 3 : Authentifier avec Supabase
            try await client.auth.signInWithIdToken(
                credentials: .init(
                    provider: .google,
                    idToken: idToken,
                    accessToken: accessToken
                )
            )
            
            // Étape 4 : Récupérer la session
            let session = try await client.auth.session
            isAuthenticated = true
            currentUser = session.user
            
            print("✅ Google Sign In réussi : \(session.user.email ?? "")")
            
        } catch {
            errorMessage = "Erreur de connexion Google : \(error.localizedDescription)"
            print("❌ Google Sign In error: \(error)")
            isAuthenticated = false
        }
        
        isLoading = false
    }
    
    /// Déconnexion
    @MainActor
    func signOut() async {
        do {
            try await client.auth.signOut()
            isAuthenticated = false
            currentUser = nil
        } catch {
            errorMessage = "Erreur de déconnexion : \(error.localizedDescription)"
        }
    }
}
