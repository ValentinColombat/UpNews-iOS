//
//  AuthView.swift
//  UpNews-iOS
//
//  Created on 18/12/2025.
//

import SwiftUI
import AuthenticationServices

struct AuthView: View {
    
    // MARK: - State
    
    @StateObject private var authService = AuthService.shared
    @State private var isSignUpMode = false
    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false
    
    // Pour réinitialiser l'onboarding
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = true
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Background
            Color.upNewsBackground
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    
                    // Logo / Header
                    VStack(spacing: 12) {
                        Image("mousse")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                        
                        Text("UpNews")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.upNewsBlack)
                        
                        Text(isSignUpMode ? "Créez votre compte" : "Bienvenue !")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 40)
                    
                    // Form
                    VStack(spacing: 16) {
                        
                        // Email
                        CustomTextField(
                            icon: "envelope.fill",
                            placeholder: "Email",
                            text: $email,
                            keyboardType: .emailAddress,
                            autocapitalization: .never
                        )
                        
                        // Password
                        CustomSecureField(
                            icon: "lock.fill",
                            placeholder: "Mot de passe",
                            text: $password,
                            showPassword: $showPassword
                        )
                        
                        // Password strength indicator (uniquement pour l'inscription)
                        if isSignUpMode {
                            PasswordStrengthView(password: password)
                        }
                        
                        // Error message
                        if let error = authService.errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        
                        // Submit Button
                        Button(action: handleAuthAction) {
                            if authService.isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text(isSignUpMode ? "S'inscrire" : "Se connecter")
                                    .font(.headline)
                                    .foregroundColor(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(isFormValid ? Color.upNewsPrimary : Color.gray)
                        .cornerRadius(12)
                        .disabled(!isFormValid || authService.isLoading)
                        .padding(.top, 8)
                        
                        // Toggle Sign Up / Sign In
                        Button(action: {
                            withAnimation {
                                isSignUpMode.toggle()
                                authService.errorMessage = nil
                            }
                        }) {
                            HStack(spacing: 4) {
                                Text(isSignUpMode ? "Déjà un compte ?" : "Pas encore de compte ?")
                                    .foregroundColor(.secondary)
                                Text(isSignUpMode ? "Se connecter" : "S'inscrire")
                                    .foregroundColor(.upNewsPrimary)
                                    .fontWeight(.semibold)
                            }
                            .font(.subheadline)
                        }
                        .padding(.top, 8)
                    }
                    .padding(.horizontal, 24)
                    
                    // Divider
                    HStack {
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(.gray.opacity(0.3))
                        Text("ou")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 8)
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(.gray.opacity(0.3))
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 8)
                    
                    // Social Login
                    VStack(spacing: 12) {
                        
                        // Apple Sign In (✅ NATIF - Conforme aux guidelines)
                        SignInWithAppleButton(
                            onRequest: { request in
                                request.requestedScopes = [.fullName, .email]
                            },
                            onCompletion: { result in
                                Task {
                                    await handleAppleSignIn(result: result)
                                }
                            }
                        )
                        .signInWithAppleButtonStyle(.black) // Style noir sur fond clair
                        .frame(height: 50)
                        .cornerRadius(12)
                        
                        // Google Sign In
                        SocialLoginButton(
                            icon: "g.circle.fill",
                            title: "Continuer avec Google",
                            backgroundColor: .white,
                            foregroundColor: .black
                        ) {
                            Task {
                                await authService.signInWithGoogle()
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var isFormValid: Bool {
        return !email.isEmpty && 
               !password.isEmpty && 
               (isSignUpMode ? password.count >= 6 : true)
    }
    
    // MARK: - Functions
    
    private func handleAuthAction() {
        Task {
            if isSignUpMode {
                await authService.signUp(email: email, password: password)
            } else {
                await authService.signIn(email: email, password: password)
            }
        }
    }
    
    /// Gère le résultat de Sign in with Apple
    private func handleAppleSignIn(result: Result<ASAuthorization, Error>) async {
        switch result {
        case .success(let authorization):
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                // Extraire les informations
                let userIdentifier = appleIDCredential.user
                let email = appleIDCredential.email
                let fullName = appleIDCredential.fullName
                let identityToken = appleIDCredential.identityToken
                
                // Convertir le token en string
                guard let tokenData = identityToken,
                      let tokenString = String(data: tokenData, encoding: .utf8) else {
                    await MainActor.run {
                        authService.errorMessage = "Erreur lors de la récupération du token"
                    }
                    return
                }
                
                // Appeler le service d'authentification
                await authService.signInWithApple(
                    userIdentifier: userIdentifier,
                    email: email,
                    fullName: fullName,
                    identityToken: tokenString
                )
            }
            
        case .failure(let error):
            // Gérer les erreurs
            if let authError = error as? ASAuthorizationError {
                switch authError.code {
                case .canceled:
                    // L'utilisateur a annulé, pas besoin d'afficher d'erreur
                    break
                case .unknown:
                    await MainActor.run {
                        authService.errorMessage = "Erreur inconnue lors de la connexion"
                    }
                default:
                    await MainActor.run {
                        authService.errorMessage = "Erreur: \(error.localizedDescription)"
                    }
                }
            } else {
                await MainActor.run {
                    authService.errorMessage = "Erreur: \(error.localizedDescription)"
                }
            }
        }
    }
}

// MARK: - Password Strength View

struct PasswordStrengthView: View {
    let password: String
    
    private var strength: Int {
        let length = password.count
        let hasNumbers = password.rangeOfCharacter(from: .decimalDigits) != nil
        let hasLetters = password.rangeOfCharacter(from: .letters) != nil
        let hasSpecial = password.rangeOfCharacter(from: CharacterSet(charactersIn: "!@#$%^&*()_+-=[]{}|;:,.<>?")) != nil
        
        if length < 6 { return 0 }
        if length < 8 { return 1 }
        if hasNumbers && hasLetters && length >= 8 { return 2 }
        if hasNumbers && hasLetters && hasSpecial && length >= 10 { return 3 }
        return 1
    }
    
    private var strengthColor: Color {
        switch strength {
        case 0: return .UpNewsRed
        case 1: return .upNewsOrange
        case 2: return .upNewsGreen
        default: return .gray
        }
    }
    
    private var strengthText: String {
        switch strength {
        case 0: return "Faible"
        case 1: return "Correct"
        case 2: return "Fort"
        default: return ""
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Barre de progression
            HStack(spacing: 4) {
                ForEach(0..<3) { index in
                    Rectangle()
                        .fill(index <= strength ? strengthColor : Color.gray.opacity(0.3))
                        .frame(height: 4)
                        .cornerRadius(2)
                }
            }
            
            // Texte
            if !password.isEmpty {
                Text(strengthText)
                    .font(.system(size: 12))
                    .foregroundColor(strengthColor)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: password)
    }
}

// MARK: - Custom TextField

struct CustomTextField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var autocapitalization: TextInputAutocapitalization = .sentences
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.gray)
                .frame(width: 20)
            
            TextField(placeholder, text: $text)
                .keyboardType(keyboardType)
                .textInputAutocapitalization(autocapitalization)
                .autocorrectionDisabled()
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Custom Secure Field

struct CustomSecureField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    @Binding var showPassword: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.gray)
                .frame(width: 20)
            
            if showPassword {
                TextField(placeholder, text: $text)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            } else {
                SecureField(placeholder, text: $text)
                    .textInputAutocapitalization(.never)
            }
            
            Button(action: { showPassword.toggle() }) {
                Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Social Login Button

struct SocialLoginButton: View {
    let icon: String
    let title: String
    let backgroundColor: Color
    var foregroundColor: Color = .white
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .foregroundColor(foregroundColor)
            .background(backgroundColor)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
        }
    }
}

// MARK: - Preview

#Preview {
    AuthView()
}
