//
//  NotificationPermissionView.swift
//  UpNews-iOS
//
//  Pop-up custom avant la demande système de notifications

import SwiftUI

struct NotificationPermissionView: View {
    
    @Environment(\.dismiss) var dismiss
    let onAllow: () -> Void
    let onLater: () -> Void
    
    var body: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    // Ne rien faire, empêche de fermer en cliquant dehors
                }
            
            // Card avec ScrollView pour éviter le contenu coupé
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Icon avec dégradé violet/bleu (comme NotificationBoostCard)
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.purple.opacity(0.3),
                                        Color.blue.opacity(0.2)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 100, height: 100)
                        
                        Image(systemName: "bell.badge.fill")
                            .font(.system(size: 44))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
                    }
                    .padding(.top, 40)
                    
                    // Title
                    Text("Reçois ta bonne nouvelle\nchaque jour")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.top, 24)
                        .padding(.horizontal, 24)
                    
                    // Description
                    Text("Active les notifications et reçois un rappel quotidien pour ne jamais manquer ton article.")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.top, 12)
                        .padding(.horizontal, 32)
                    
                    // Bonus XP avec style premium
                    HStack(spacing: 10) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.yellow)
                        
                        Text("Bonus : +80 d'XP offert !")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.15))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                    )
                    .padding(.top, 24)
                    .padding(.horizontal, 24)
                    
                    // Buttons
                    VStack(spacing: 14) {
                        // Activer (bouton blanc sur fond coloré)
                        Button {
                            onAllow()
                            dismiss()
                        } label: {
                            Text("Activer les notifications")
                                .font(.system(size: 17, weight: .bold))
                                .foregroundColor(Color(red: 0.4, green: 0.2, blue: 0.8))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.white)
                                        .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
                                )
                        }
                        
                        // Plus tard
                        Button {
                            onLater()
                            dismiss()
                        } label: {
                            Text("Plus tard")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                                .padding(.vertical, 12)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 28)
                    .padding(.bottom, 40)
                }
                .frame(maxWidth: 360)
                .background(
                    ZStack {
                        // Dégradé principal (violet → bleu)
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
                .cornerRadius(28)
                .overlay(
                    RoundedRectangle(cornerRadius: 28)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.4),
                                    Color.white.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
                .shadow(color: Color.purple.opacity(0.4), radius: 20, y: 10)
                .padding(.horizontal, 20)
            }
            .frame(maxHeight: .infinity)
        }
    }
}

// MARK: - Preview

#Preview {
    NotificationPermissionView(
        onAllow: { print("Allow") },
        onLater: { print("Later") }
    )
}
