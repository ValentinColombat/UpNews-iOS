//
//  PremiumBadge.swift
//  UpNews-iOS

import SwiftUI

// MARK: - Premium Badge (Petit badge "Premium")

struct PremiumBadge: View {
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "crown.fill")
                .font(.system(size: 10))
            Text("Premium")
                .font(.system(size: 12, weight: .bold))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            LinearGradient(
                colors: [Color.upNewsOrange, Color.upNewsOrange.opacity(0.8)],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(8)
        .shadow(color: Color.upNewsOrange.opacity(0.3), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Premium Lock Overlay (Grand overlay avec cadenas)

struct PremiumLockOverlay: View {
    let onTap: () -> Void
    
    var body: some View {
        ZStack {
            // Fond flouté
            Color.black.opacity(0.6)
            
            VStack(spacing: 16) {
                // Icône cadenas
                ZStack {
                    Circle()
                        .fill(Color.upNewsOrange.opacity(0.2))
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "lock.fill")
                        .font(.system(size: 36))
                        .foregroundColor(.upNewsOrange)
                }
                
                // Texte
                VStack(spacing: 8) {
                    Text("Contenu Premium")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Passe Premium pour débloquer tous les articles")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                
                // Bouton CTA
                Button {
                    onTap()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 14))
                        Text("Débloquer")
                            .font(.system(size: 16, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            colors: [Color.upNewsOrange, Color.upNewsOrange.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                    .shadow(color: Color.upNewsOrange.opacity(0.4), radius: 8, x: 0, y: 4)
                }
            }
        }
    }
}

// MARK: - Premium Card Blur (Carte article avec flou)

struct PremiumCardBlur: View {
    let article: Article
    let onTap: () -> Void
    
    var body: some View {
        Button {
            onTap()
        } label: {
            // Contenu de la carte (SANS flou)
            HStack(spacing: 12) {
                CategoryIconBadge(article: article)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(article.categoryDisplayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(article.title)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.upNewsBlack)
                        .lineLimit(2)
                }
                
                Spacer()
                
                // Zone chevron + couronne
                VStack(spacing: 0) {
                    // Couronne en haut
                    Image(systemName: "crown.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.upNewsOrange)
                    
                    Spacer()
                    
                    // Chevron centré verticalement
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Spacer()
                }
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(radius: 1, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Previews

#Preview("Premium Badge") {
    PremiumBadge()
        .padding()
        .background(Color.upNewsBackground)
}

#Preview("Premium Lock Overlay") {
    ZStack {
        Color.upNewsBackground
            .ignoresSafeArea()
        
        PremiumLockOverlay {
            print("Tap on unlock")
        }
    }
}
