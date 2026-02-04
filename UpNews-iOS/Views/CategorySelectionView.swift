//
//  CategorySelectionView.swift
//  UpNews-iOS
//
//  Created by Valentin Colombat on 31/01/2026.
//

import SwiftUI
import Supabase

struct CategorySelectionView: View {
    
    // MARK: - State
    
    @State private var selectedCategories: Set<String> = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    // Callback quand la sélection est terminée
    var onCategoriesSelected: () -> Void
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            Color.upNewsBackground
                .ignoresSafeArea()
            
            // ScrollView avec TOUT le contenu (header + grille + textes)
            ScrollView {
                VStack(spacing: 20) {
                    
                    // Header dans le scroll
                    VStack(spacing: 16) {
                        Text("Tes thématiques\npréférées")
                            .font(.system(size: 36, weight: .bold))
                            .multilineTextAlignment(.center)
                            .foregroundColor(.upNewsBlack)
                            .padding(.top, 60)
                        
                        Text("Choisis au moins une catégorie pour personnaliser ton fil d'actualité")
                            .font(.system(size: 15))
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 40)
                    }
                    .padding(.bottom, 4)
                    
                    // Categories Grid
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 16),
                        GridItem(.flexible(), spacing: 16)
                    ], spacing: 16) {
                        ForEach(CategoryItem.allCategories) { category in
                            CategoryCard(
                                category: category,
                                isSelected: selectedCategories.contains(category.id)
                            ) {
                                toggleCategory(category.id)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    // Info text dans le scroll
                    VStack(spacing: 8) {
                        if selectedCategories.isEmpty {
                            Text("Sélectionne au moins une catégorie")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            Text("\(selectedCategories.count) catégorie\(selectedCategories.count > 1 ? "s" : "") sélectionnée\(selectedCategories.count > 1 ? "s" : "")")
                                .font(.caption)
                                .foregroundColor(.upNewsGreen)
                        }
                        
                        // Error Message
                        if let error = errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                    }
                    .padding(.vertical, 16)
                }
                .padding(.bottom, 120) // Espace pour le bouton flottant
            }
            
            // Bouton flottant en bas avec dégradé
            VStack {
                Spacer()
                
                VStack(spacing: 0) {
                    // Dégradé subtil pour indiquer qu'on peut scroller
                    LinearGradient(
                        colors: [
                            Color.upNewsBackground.opacity(0),
                            Color.upNewsBackground.opacity(0.95),
                            Color.upNewsBackground
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 40)
                    
                    // Zone du bouton
                    VStack {
                        Button(action: confirmSelection) {
                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("SUIVANT")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                        .frame(width: 140, height: 50)
                        .background(selectedCategories.isEmpty ? Color.gray : Color.upNewsPrimary)
                        .cornerRadius(8)
                        .disabled(selectedCategories.isEmpty || isLoading)
                        .shadow(color: selectedCategories.isEmpty ? .clear : Color.upNewsPrimary.opacity(0.3), radius: 12, y: 4)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 40)
                    .background(Color.upNewsBackground)
                }
            }
            .ignoresSafeArea(edges: .bottom)
        }
    }
    
    // MARK: - Functions
    
    private func toggleCategory(_ categoryId: String) {
        withAnimation(.spring(response: 0.3)) {
            if selectedCategories.contains(categoryId) {
                selectedCategories.remove(categoryId)
            } else {
                selectedCategories.insert(categoryId)
            }
        }
    }
    
    private func confirmSelection() {
        guard !selectedCategories.isEmpty else { return }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                // Sauvegarder les catégories préférées
                try await UserDataService.shared.savePreferredCategories(Array(selectedCategories))
                
                await MainActor.run {
                    isLoading = false
                    onCategoriesSelected()
                }
                
            } catch {
                await MainActor.run {
                    errorMessage = "Erreur lors de la sauvegarde : \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }
}

// MARK: - Category Model (removed - now in CategoryItem.swift)

// MARK: - Category Card

struct CategoryCard: View {
    let category: CategoryItem
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                // Icon
                ZStack {
                    Circle()
                        .fill(category.color.opacity(isSelected ? 1.0 : 0.2))
                        .frame(width: 70, height: 70)
                    
                    Image(systemName: category.icon)
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundColor(isSelected ? .white : category.color)
                    
                    // Checkmark overlay
                    if isSelected {
                        Circle()
                            .strokeBorder(Color.white, lineWidth: 3)
                            .frame(width: 70, height: 70)
                        
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                            .background(
                                Circle()
                                    .fill(category.color)
                                    .frame(width: 22, height: 22)
                            )
                            .offset(x: 25, y: -25)
                    }
                }
                
                // Name
                Text(category.name)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.upNewsBlack)
                
                // Description
                Text(category.description)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(height: 32)
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .frame(height: 180)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .shadow(
                        color: isSelected ? category.color.opacity(0.3) : Color.black.opacity(0.05),
                        radius: isSelected ? 8 : 2,
                        x: 0,
                        y: 2
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? category.color : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - Preview

#Preview {
    CategorySelectionView {
        print("Catégories sélectionnées !")
    }
}
