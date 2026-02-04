//
//  CategoryTag.swift
//  UpNews-iOS
//
//  Created by Valentin Colombat on 21/01/2026.
//
import SwiftUI

// MARK: - Badge avec texte (pour articles principaux)
struct CategoryTagView: View {
    let article: Article
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: article.categoryIcon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(
                    .white.shadow(.drop(color: .gray.opacity(0.5), radius: 3, x: 0, y: 0))
                )
            Text(article.category.capitalized)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(
                    .white.shadow(.drop(color: .gray.opacity(0.5), radius: 3, x: 0, y: 0))
                )
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            ZStack {
                // Fond glassmorphique
                RoundedRectangle(cornerRadius: 8)
                    .fill(.ultraThinMaterial)
                
                // Teinte colorée
                RoundedRectangle(cornerRadius: 8)
                    .fill(article.categoryColor)
                
                // Reflet lumineux en haut
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.4),
                                Color.white.opacity(0)
                            ],
                            startPoint: .top,
                            endPoint: .center
                        )
                    )
                
                // Bordure subtile
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            }
        )
        .shadow(color: article.categoryColor.opacity(0.3), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Badge icône seule (pour articles secondaires)
struct CategoryIconBadge: View {
    let article: Article
    
    var body: some View {
        Image(systemName: article.categoryIcon)
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(
                .white.shadow(.drop(color: .gray.opacity(0.5), radius: 3, x: 0, y: 0))
            )
            .frame(width: 40, height: 40)
            .background(
                ZStack {
                    // Fond glassmorphique
                    RoundedRectangle(cornerRadius: 10)
                        .fill(.ultraThinMaterial)
                    
                    // Teinte colorée
                    RoundedRectangle(cornerRadius: 10)
                        .fill(article.categoryColor)
                    
                    // Reflet lumineux en haut
                    RoundedRectangle(cornerRadius: 10)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.4),
                                    Color.white.opacity(0)
                                ],
                                startPoint: .top,
                                endPoint: .center
                            )
                        )
                    
                    // Bordure subtile
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                }
            )
            .shadow(color: article.categoryColor.opacity(0.3), radius: 4, x: 0, y: 2)
    }
}

