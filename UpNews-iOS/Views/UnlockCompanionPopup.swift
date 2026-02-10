//
//  UnlockCompanionPopup.swift
//  UpNews-iOS
//
//  Composant réutilisable pour afficher les compagnons débloqués

import SwiftUI

struct UnlockCompanionPopup: View {
    
    // MARK: - Properties
    
    let companions: [(name: String, imageName: String)]
    let onDismiss: () -> Void
    let onNavigateToCompanions: (() -> Void)? // Optional: pour rediriger vers la page Compagnons
    
    @State private var showContent = false
    @State private var selectedCompanionIndex = 0
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Fond flou avec overlay sombre
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .blur(radius: showContent ? 0 : 20)
            
            VStack(spacing: 0) {
                // Carte principale avec effet glass
                VStack(spacing: 0) {
                    // Header avec badge et bouton fermer
                    headerSection
                    
                    // Titre avec animation
                    titleSection
                        .padding(.top, 16)
                    
                    // Carrousel des compagnons
                    companionsCarousel
                        .padding(.vertical, 24)
                    
                    // Indicateurs de pages (si plusieurs compagnons)
                    if companions.count > 1 {
                        pageIndicators
                            .padding(.bottom, 20)
                    }
                    
                    // Bouton d'action
                    actionButton
                        .padding(.horizontal, 24)
                        .padding(.bottom, 24)
                }
                .background(
                    // Effet glassmorphique moderne
                    ZStack {
                        RoundedRectangle(cornerRadius: 32)
                            .fill(.ultraThinMaterial)
                        
                        RoundedRectangle(cornerRadius: 32)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.8),
                                        Color.white.opacity(0.6)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        // Bordure lumineuse
                        RoundedRectangle(cornerRadius: 32)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.8),
                                        Color.upNewsOrange.opacity(0.3)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    }
                )
                .shadow(color: .upNewsOrange.opacity(0.2), radius: 30, x: 0, y: 15)
                .padding(.horizontal, 32)
                .scaleEffect(showContent ? 1 : 0.8)
                .opacity(showContent ? 1 : 0)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                showContent = true
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        HStack {
            // Badge "NOUVEAU" à gauche
            HStack(spacing: 6) {
                Image(systemName: "star.fill")
                    .font(.system(size: 10, weight: .bold))
                Text("NOUVEAU")
                    .font(.system(size: 11, weight: .bold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color.upNewsOrange, Color.upNewsOrange.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
            .shadow(color: .upNewsOrange.opacity(0.3), radius: 8, x: 0, y: 4)
            
            Spacer()
            
            // Bouton fermer
            Button {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    showContent = false
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    onDismiss()
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.upNewsBlack.opacity(0.6))
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
    }
    
    // MARK: - Title Section
    
    private var titleSection: some View {
        VStack(spacing: 8) {
            // Emoji animé
            Text("🎉")
                .font(.system(size: 56))
                .scaleEffect(showContent ? 1 : 0)
                .animation(.spring(response: 0.6, dampingFraction: 0.5).delay(0.2), value: showContent)
            
            Text("Nouveau\(companions.count > 1 ? "x" : "") compagnon\(companions.count > 1 ? "s" : "") !")
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(.upNewsBlack)
                .multilineTextAlignment(.center)
            
            Text("Niveau \(getLevelForCompanion(companions.first?.name ?? "")) débloqué")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.upNewsBlack.opacity(0.6))
        }
        .padding(.horizontal, 6)
    }
    
    // MARK: - Companions Carousel
    
    private var companionsCarousel: some View {
        TabView(selection: $selectedCompanionIndex) {
            ForEach(Array(companions.enumerated()), id: \.offset) { index, companion in
                companionCard(companion)
                    .tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .frame(height: 280)
    }
    
    private func companionCard(_ companion: (name: String, imageName: String)) -> some View {
        VStack(spacing: 20) {
            // Image du compagnon avec effet d'ombre
            ZStack {
                // Ombre colorée
                Image(companion.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 180, height: 180)
                    .blur(radius: 20)
                    .opacity(0.4)
                    .offset(y: 10)
                
                // Image principale
                Image(companion.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 180, height: 180)
            }
            .scaleEffect(showContent ? 1 : 0.5)
            .animation(.spring(response: 0.7, dampingFraction: 0.6).delay(0.3), value: showContent)
            
            // Nom du compagnon
            Text(companion.name)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.upNewsBlack)
        }
        .padding(24)
    }
    
    // MARK: - Page Indicators
    
    private var pageIndicators: some View {
        HStack(spacing: 8) {
            ForEach(0..<companions.count, id: \.self) { index in
                Circle()
                    .fill(index == selectedCompanionIndex ? Color.upNewsOrange : Color.gray.opacity(0.3))
                    .frame(width: 8, height: 8)
                    .scaleEffect(index == selectedCompanionIndex ? 1.2 : 1)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: selectedCompanionIndex)
            }
        }
    }
    
    // MARK: - Action Button
    
    private var actionButton: some View {
        Button {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                showContent = false
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                if let navigate = onNavigateToCompanions {
                    navigate()
                } else {
                    onDismiss()
                }
            }
        } label: {
            HStack(spacing: 10) {
                Text(onNavigateToCompanions != nil ? "Voir mes compagnons" : "Super !")
                    .font(.system(size: 17, weight: .bold))
                
                if onNavigateToCompanions != nil {
                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .bold))
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                ZStack {
                    // Fond avec dégradé
                    LinearGradient(
                        colors: [Color.upNewsOrange, Color.upNewsOrange.opacity(0.85)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    
                    // Effet de brillance
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.3),
                            Color.white.opacity(0)
                        ],
                        startPoint: .top,
                        endPoint: .center
                    )
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color.upNewsOrange.opacity(0.4), radius: 12, x: 0, y: 6)
        }
    }
    
    // MARK: - Helper Functions
    
    private func getLevelForCompanion(_ name: String) -> Int {
        let levelMap: [String: Int] = [
            "Brume": 2, "Flocon": 2,
            "Vera": 3,
            "Jura": 4,
            "Caramel": 5, "Écorce": 5, "Luciole": 5,
            "Olga": 6,
            "Luka": 7,
            "Nina": 8,
            "Mochi": 10, "Sève": 10,
            "Pépite": 15,
            "Noisette": 20
        ]
        return levelMap[name] ?? 1
    }
}

// MARK: - Preview

#Preview {
    UnlockCompanionPopup(
        companions: [
            ("Brume", "brume"),
            ("Flocon", "flocon")
        ],
        onDismiss: {},
        onNavigateToCompanions: nil
    )
}
