//
//  CompanionSelectionView.swift
//  UpNews-iOS
//
//  Created on 22/12/2025.
//

import SwiftUI
import Supabase

struct CompanionSelectionView: View {
    
    // MARK: - State
    
    @State private var selectedCompanionId: String?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var displayName: String = ""
    
    @StateObject private var authService = AuthService.shared
    
    // Callback quand la sélection est terminée
    var onCompanionSelected: () -> Void
    
    // MARK: - Companions Data
    
    let companions = [
        Companion(
            id: "givre_et_plume",
            name: "Givre & Plume",
            imageName: "givre_et_plume",
            color: Color(red: 0.4, green: 1, blue: 0.4)
        ),
        Companion(
            id: "cannelle",
            name: "Cannelle",
            imageName: "cannelle",
            color: Color(red: 0.4, green: 1, blue: 0.4)
        ),
        Companion(
            id: "mousse",
            name: "Mousse",
            imageName: "mousse",
            color: Color(red: 0.4, green: 1, blue: 0.4)
        )
    ]
    
    // MARK: - Body
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.upNewsBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 26) {
                        
                        // Header moderne
                        VStack(spacing: 16) {
                            // Titre avec style moderne
                            VStack(spacing: 8) {
                                Text("Choisis ton premier")
                                    .font(.system(size: 28, weight: .semibold))
                                    .foregroundColor(.upNewsBlack.opacity(0.7))
                                
                                Text("Compagnon")
                                    .font(.system(size: 42, weight: .bold))
                                    .foregroundColor(.upNewsBlack)
                            }
                            .multilineTextAlignment(.center)
                            .padding(.top, 40)
                            
                            // Sous-titre
                            Text("Il t'accompagnera dans ta lecture quotidienne")
                                .font(.system(size: 16, weight: .regular))
                                .foregroundColor(.upNewsBlack.opacity(0.6))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        }
                        .padding(.bottom, 8)
                        
                        // Companions cards
                        HStack(spacing: 8) {
                            ForEach(companions) { companion in
                                CompanionCard(
                                    companion: companion,
                                    isSelected: selectedCompanionId == companion.id
                                ) {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                        selectedCompanionId = companion.id
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Display Name Field centré
                        VStack(spacing: 16) {
                            Text("Ton pseudo")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.upNewsBlack)
                                .frame(maxWidth: .infinity, alignment: .center)
                            
                            VStack(spacing: 8) {
                                TextField("Ex: Alex", text: $displayName)
                                    .textInputAutocapitalization(.words)
                                    .disableAutocorrection(true)
                                    .font(.system(size: 17))
                                    .padding(16)
                                    .background(Color.white)
                                    .cornerRadius(16)
                                    .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(
                                                isDisplayNameValid && !displayName.isEmpty
                                                ? Color.upNewsPrimary.opacity(0.4)
                                                : Color.clear,
                                                lineWidth: 2
                                            )
                                    )
                                    .onChange(of: displayName) { oldValue, newValue in
                                        if newValue.count > 10 {
                                            displayName = String(newValue.prefix(10))
                                        }
                                    }
                                
                                // Compteur de caractères
                                Text("\(displayName.count)/10")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(displayName.count > 10 ? .red : Color.upNewsBlack.opacity(0.4))
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                                
                                // Message d'erreur ou validation
                                if !displayNameErrorMessage.isEmpty {
                                    HStack(spacing: 6) {
                                        Image(systemName: "exclamationmark.circle.fill")
                                            .font(.system(size: 14))
                                        Text(displayNameErrorMessage)
                                            .font(.system(size: 14))
                                    }
                                    .foregroundColor(.gray)
                                    .transition(.opacity)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                } else if isDisplayNameValid {
                                    HStack(spacing: 6) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 14))
                                        Text("Parfait !")
                                            .font(.system(size: 14))
                                    }
                                    .foregroundColor(.upNewsPrimary)
                                    .transition(.opacity)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        // Info box moderne
                        VStack(spacing: 12) {
                            
                            Text("Chaque jour, des milliers d'événements positifs se produisent dans le monde. Nous les trouvons pour vous.")
                                .font(.system(size: 15, weight: .regular))
                                .foregroundColor(.upNewsBlack.opacity(0.8))
                                .multilineTextAlignment(.center)
                                .lineSpacing(4)
                            
                            Image(systemName: "sparkles")
                                .font(.system(size: 32))
                                .foregroundColor(.upNewsPrimary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 28)
                        .padding(.horizontal, 20)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.upNewsPrimary.opacity(0.08))
                        )
                        .padding(.horizontal, 24)
                        
                        // Error Message
                        if let error = errorMessage {
                            HStack(spacing: 8) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 16))
                                Text(error)
                                    .font(.system(size: 14))
                            }
                            .foregroundColor(.gray)
                            .padding(.horizontal, 24)
                            .multilineTextAlignment(.center)
                        }
                        
                        // Confirm Button moderne
                        Button(action: confirmSelection) {
                            HStack(spacing: 12) {
                                if isLoading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text("Commencer l'aventure")
                                        .font(.system(size: 17, weight: .semibold))
                                        .foregroundColor(.white)
                                    
                                    Image(systemName: "arrow.right")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.white)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(selectedCompanionId != nil && isDisplayNameValid
                                          ? Color.upNewsPrimary
                                          : Color.gray.opacity(0.4))
                            )
                            .shadow(
                                color: (selectedCompanionId != nil && isDisplayNameValid
                                        ? Color.upNewsPrimary.opacity(0.3)
                                        : Color.clear),
                                radius: 12,
                                x: 0,
                                y: 6
                            )
                        }
                        .disabled(selectedCompanionId == nil || !isDisplayNameValid || isLoading)
                        .padding(.horizontal, 24)
                        .padding(.top, 8)
                        .padding(.bottom, 40)
                    }
                    .frame(width: geometry.size.width)
                }
                .scrollIndicators(.hidden)
            }
        }
    }
    
    // MARK: - Functions
    
    // Display name validation
    private var isDisplayNameValid: Bool {
        let trimmed = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.count >= 2 && trimmed.count <= 10
    }
    
    private var displayNameErrorMessage: String {
        let trimmed = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return ""
        } else if trimmed.count < 2 {
            return "Le pseudo doit contenir au moins 2 caractères"
        } else if trimmed.count > 10 {
            return "Le pseudo ne peut pas dépasser 10 caractères"
        }
        return ""
    }
    
    private func confirmSelection() {
        guard let companionId = selectedCompanionId else { return }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let session = try await SupabaseConfig.client.auth.session
                
                struct CompanionUpdate: Encodable {
                    let display_name: String
                    let selected_companion_id: String
                }
                
                let trimmedDisplayName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
                
                let update = CompanionUpdate(
                    display_name: trimmedDisplayName,
                    selected_companion_id: companionId
                )
                
                try await SupabaseConfig.client
                    .from("users")
                    .update(update)
                    .eq("id", value: session.user.id.uuidString)
                    .execute()
                
                await MainActor.run {
                    isLoading = false
                    onCompanionSelected()
                }
                
            } catch {
                await MainActor.run {
                    errorMessage = "Erreur lors de la sélection : \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }
    
    // MARK: - Companion Model
    
    struct Companion: Identifiable {
        let id: String
        let name: String
        let imageName: String
        let color: Color
    }
    
    // MARK: - Companion Card
    
    struct CompanionCard: View {
        let companion: Companion
        let isSelected: Bool
        let onTap: () -> Void
        
        var body: some View {
            Button(action: onTap) {
                VStack(spacing: 8) {
                    ZStack {
                        // Background avec effet de profondeur
                        RoundedRectangle(cornerRadius: 20)
                            .fill(
                                LinearGradient(
                                    colors: isSelected
                                    ? [Color.upNewsPrimary.opacity(0.15), Color.upNewsPrimary.opacity(0.08)]
                                    : [Color.gray.opacity(0.08), Color.gray.opacity(0.05)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 100, height: 140)
                        
                        // Border pour la sélection
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                isSelected ? Color.upNewsPrimary : Color.clear,
                                lineWidth: 3
                            )
                            .frame(width: 100, height: 140)
                        
                        // Image avec ombre
                        VStack {
                            Image(companion.imageName)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 80, height: 120)
                                .shadow(
                                    color: isSelected
                                    ? Color.upNewsPrimary.opacity(0.3)
                                    : Color.black.opacity(0.1),
                                    radius: isSelected ? 12 : 6,
                                    x: 0,
                                    y: 4
                                )
                        }
                    }
                    
                    // Nom du compagnon
                    Text(companion.name)
                        .font(.system(size: 13, weight: isSelected ? .semibold : .medium))
                        .foregroundColor(isSelected ? .upNewsBlack : .upNewsBlack.opacity(0.6))
                }
                .padding(6)
            }
            .buttonStyle(.plain)
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(.spring(response: 0.35, dampingFraction: 0.7), value: isSelected)
        }
    }
}

