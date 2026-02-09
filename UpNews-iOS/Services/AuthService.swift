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
            print(" Session restaurée:  \(session.user.email ??  "")")
        } catch {
            isAuthenticated = false
            currentUser = nil
            print(" Aucune session active")
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
            print(" Connexion réussie:  \(session.user.email ??  "")")
            
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
            print(" Erreur connexion: \(errorDesc)")
        }
        
        isLoading = false
    }
    
    // MARK: - Inscription
    
    @MainActor
    func signUp(email:  String, password: String, username: String) async {
        isLoading = true
        errorMessage = nil
        
        // Nettoyage
        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let cleanPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
        
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
        
        guard !cleanUsername.isEmpty, cleanUsername.count >= 2 else {
            errorMessage = "Le nom doit contenir au moins 2 caractères"
            isLoading = false
            return
        }
        
        do {
            let session = try await client.auth.signUp(
                email: cleanEmail,
                password: cleanPassword,
                data: ["display_name": . string(cleanUsername)]
            )
            
            isAuthenticated = true
            currentUser = session.user
            print(" Inscription réussie: \(session.user.email ?? "")")
            
        } catch {
            errorMessage = "Erreur d'inscription: \(error.localizedDescription)"
            isAuthenticated = false
            print(" Erreur inscription: \(error)")
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
            
            // Récupérer le nom de l'utilisateur Google
            let profile = result.user.profile
            let fullName = profile?.name
            let givenName = profile?.givenName
            let familyName = profile?.familyName
            
            let session = try await client.auth.signInWithIdToken(
                credentials: . init(
                    provider: .google,
                    idToken: idToken,
                    accessToken: accessToken
                )
            )
            
            isAuthenticated = true
            currentUser = session.user
            print("✅ Connexion Google réussie: \(session.user.email ?? "")")
            
            // Sauvegarder/mettre à jour le profil avec le nom Google
            if let fullName = fullName {
                await saveGoogleUserProfile(
                    userId: session.user.id.uuidString,
                    email: session.user.email ?? "",
                    fullName: fullName,
                    givenName: givenName,
                    familyName: familyName
                )
            }
            
        } catch {
            errorMessage = "Erreur connexion Google: \(error.localizedDescription)"
            isAuthenticated = false
            print("❌ Erreur Google: \(error)")
        }
        
        isLoading = false
    }
    
    /// Sauvegarde les informations de profil Google
    private func saveGoogleUserProfile(
        userId: String,
        email: String,
        fullName: String,
        givenName: String?,
        familyName: String?
    ) async {
        do {
            // Vérifier si l'utilisateur existe déjà avec un display_name correct
            struct UserCheck: Decodable {
                let id: String
                let display_name: String?
            }
            
            let existingUsers: [UserCheck] = try await client
                .from("users")
                .select("id, display_name")
                .eq("id", value: userId)
                .execute()
                .value
            
            // Si l'utilisateur existe déjà avec un nom différent de l'email, garder
            if let existingUser = existingUsers.first,
               let displayName = existingUser.display_name,
               !displayName.isEmpty,
               displayName != email.components(separatedBy: "@").first,
               displayName.lowercased() != email.components(separatedBy: "@").first?.lowercased() {
                print("✅ Utilisateur Google existant avec nom: \(displayName)")
                return
            }
            
            // Construire le display_name (prénom uniquement ou nom complet selon préférence)
            let displayName = givenName ?? fullName
            
            // Structure pour UPSERT
            struct UserUpsert: Encodable {
                let id: String
                let email: String
                let display_name: String
            }
            
            // UPSERT : Crée si n'existe pas, met à jour sinon
            try await client
                .from("users")
                .upsert(UserUpsert(
                    id: userId,
                    email: email,
                    display_name: displayName
                ))
                .execute()
            
            print("✅ Profil Google sauvegardé: \(displayName) (\(email))")
            
        } catch {
            print("⚠️ Erreur sauvegarde profil Google: \(error)")
            // On ne bloque pas la connexion si la sauvegarde échoue
        }
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
            
            print("🍎 Connexion Apple réussie: \(session.user.email ?? userIdentifier)")
            
            // Si c'est la première connexion et qu'on a le nom complet, le sauvegarder
            if let email = email, let fullName = fullName {
                await saveAppleUserProfile(
                    userId: session.user.id.uuidString,
                    email: email,
                    fullName: fullName
                )
            }
            
        } catch {
            errorMessage = "Erreur connexion Apple: \(error.localizedDescription)"
            isAuthenticated = false
            print("❌ Erreur Apple Sign In: \(error)")
        }
        
        isLoading = false
    }
    
    /// Sauvegarde les informations de profil Apple (première connexion uniquement)
    private func saveAppleUserProfile(
        userId: String,
        email: String,
        fullName: PersonNameComponents
    ) async {
        do {
            // Vérifier si l'utilisateur existe déjà avec un display_name correct
            struct UserCheck: Decodable {
                let id: String
                let display_name: String?
            }
            
            let existingUsers: [UserCheck] = try await client
                .from("users")
                .select("id, display_name")
                .eq("id", value: userId)
                .execute()
                .value
            
            // Si l'utilisateur existe déjà avec un nom différent de l'email, garder
            if let existingUser = existingUsers.first,
               let displayName = existingUser.display_name,
               !displayName.isEmpty,
               displayName != email.components(separatedBy: "@").first,
               displayName.lowercased() != email.components(separatedBy: "@").first?.lowercased() {
                print("✅ Utilisateur Apple existant avec nom: \(displayName)")
                return
            }
            
            // Construire le nom d'affichage (prénom uniquement ou nom complet selon préférence)
            let givenName = fullName.givenName ?? ""
            let familyName = fullName.familyName ?? ""
            
            // Utiliser le prénom uniquement (ou nom complet si vous préférez)
            let displayName = !givenName.isEmpty ? givenName : [givenName, familyName].filter { !$0.isEmpty }.joined(separator: " ")
            
            guard !displayName.isEmpty else {
                print("⚠️ Pas de nom fourni par Apple")
                return
            }
            
            // Structure pour UPSERT
            struct UserUpsert: Encodable {
                let id: String
                let email: String
                let display_name: String
            }
            
            // UPSERT : Crée si n'existe pas, met à jour sinon
            try await client
                .from("users")
                .upsert(UserUpsert(
                    id: userId,
                    email: email,
                    display_name: displayName
                ))
                .execute()
            
            print("✅ Profil Apple sauvegardé: \(displayName) (\(email))")
            
        } catch {
            print("⚠️ Erreur sauvegarde profil Apple: \(error)")
            // On ne bloque pas la connexion si la sauvegarde échoue
        }
    }
    
    // MARK: - Déconnexion
    
    @MainActor
    func signOut() async {
        do {
            try await client.auth.signOut()
            isAuthenticated = false
            currentUser = nil
            print(" Déconnexion réussie")
        } catch {
            print(" Erreur déconnexion: \(error)")
        }
    }
}
