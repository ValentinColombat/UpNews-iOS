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
    
    @State private var displayName: String = ""
    @State private var selectedCompanionId: String?
    @State private var isLoading = false
    @State private var errorMessage: String?
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
        ZStack {
            Color.upNewsBackground
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                
                // Header
                VStack(spacing: 24) {
                    Text("Choisis ton nom\net ton\nCompagnon")
                        .font(.system(size: 36, weight: .bold))
                        .multilineTextAlignment(.center)
                        .foregroundColor(.upNewsBlack)
                        .padding(.top, 60)
                        .padding(.bottom, 20)
                    
                    // Display Name TextField
                    CustomTextField(
                        icon: "person.fill",
                        placeholder: "Ton nom ou pseudo",
                        text: $displayName
                    )
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20)
                    
                    // Companions en ligne
                    HStack(spacing: 20) {
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
                    . padding(.horizontal, 24)
                }
                
                Spacer()
                
                // Info box
                VStack(spacing: 16) {
                    Text("Chaque jour, des milliers d'événements positifs se produisent dans le monde.  Nous les trouvons pour vous.")
                        .font(. body)
                        .foregroundColor(.upNewsBlack)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 40)
                }
                .frame(maxWidth: .infinity)
                .background(Color.upNewsGreen.opacity(0.05))
                .cornerRadius(16)
                .padding(.horizontal, 24)
                
                Spacer()
                
                // Error Message
                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                }
                
                // Confirm Button
                Button(action: confirmSelection) {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("SUIVANT")
                            .font(.system(size: 16, weight:  .bold))
                            .foregroundColor(.white)
                    }
                }
                .frame(width: 140, height: 50)
                .background((selectedCompanionId != nil && !displayName.isEmpty) ? Color.upNewsPrimary : Color.gray)
                .cornerRadius(8)
                .disabled(selectedCompanionId == nil || displayName.isEmpty || isLoading)
                .padding(.bottom, 40)
            }
        }
    }
    
    // MARK: - Functions
    
    private func confirmSelection() {
        guard let companionId = selectedCompanionId else { return }
        
        // Validate display name
        let cleanDisplayName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanDisplayName.isEmpty, cleanDisplayName.count >= 2 else {
            errorMessage = "Le nom doit contenir au moins 2 caractères"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                // UPSERT both display_name and companion_id together
                try await SupabaseConfig.client
                    .from("users")
                    .upsert([
                        "id": authService.currentUser?.id.uuidString,
                        "display_name": cleanDisplayName,
                        "companion_id": companionId
                    ])
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
        let companion:  Companion
        let isSelected:  Bool
        let onTap:  () -> Void
        
        var body: some View {
            Button(action: onTap) {
                VStack(spacing:  0) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.gray.opacity(0.15))
                            .frame(width: 100, height: 140)
                        
                        Image(companion.imageName)
                            .resizable()
                            .scaledToFit()
                            .blur(radius: 30)
                            .opacity(1)
                            .offset(y: -5)
                            .offset(x: -5)
                        
                        Image(companion.imageName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 90, height: 130)
                    }
                    
                    RoundedRectangle(cornerRadius: 4)
                        . fill(isSelected ? companion.color : Color.gray.opacity(0.3))
                        .frame(width: 60, height:  8)
                        .padding(.top, 12)
                    
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.upNewsBlack)
                            .padding(.top, 8)
                    } else {
                        Color.clear
                            . frame(height: 28)
                            .padding(.top, 8)
                    }
                }
            }
            .buttonStyle(.plain)
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(.spring(response: 0.3), value: isSelected)
        }
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

// MARK: - Preview

#Preview {
    CompanionSelectionView {
        print("Compagnon sélectionné !")
    }
}
