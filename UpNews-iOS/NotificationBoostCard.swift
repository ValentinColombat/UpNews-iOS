//
//  NotificationBoostCard.swift
//  UpNews-iOS
//
//  Carte réutilisable pour inciter à activer les notifications

import SwiftUI

struct NotificationBoostCard: View {
    
    let onActivate: () -> Void
    
    var body: some View {
        Button(action: onActivate) {
            HStack(spacing: 12) {
                // Icon avec dégradé
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.purple.opacity(0.8),
                                    Color.blue.opacity(0.6)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: "bell.badge.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                }
                
                // Content compact
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.yellow)
                        
                        Text("+200 XP")
                            .font(.system(size: 15, weight: .black))
                            .foregroundColor(.white)
                    }
                    
                    Text("Active les notifications")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                }
                
                Spacer()
                
                // Arrow
                Image(systemName: "arrow.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                ZStack {
                    // Dégradé sombre premium
                    LinearGradient(
                        colors: [
                            Color(red: 0.4, green: 0.2, blue: 0.8),  // Violet foncé
                            Color(red: 0.2, green: 0.4, blue: 0.9),  // Bleu profond
                            Color(red: 0.1, green: 0.6, blue: 0.6)   // Turquoise
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    
                    // Overlay brillant
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.15),
                            Color.clear,
                            Color.white.opacity(0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.3),
                                Color.white.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            )
            .shadow(color: Color.purple.opacity(0.4), radius: 12, x: 0, y: 6)
            .shadow(color: Color.blue.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    NotificationBoostCard(onActivate: {
        print("Activate tapped")
    })
    .padding()
    .background(Color.upNewsBackground)
}
