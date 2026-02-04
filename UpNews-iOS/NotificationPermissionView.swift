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
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    // Ne rien faire, empêche de fermer en cliquant dehors
                }
            
            // Card
            VStack(spacing: 0) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Color.upNewsOrange.opacity(0.2))
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "bell.badge.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.upNewsOrange)
                }
                .padding(.top, 32)
                
                // Title
                Text("Reçois ta bonne nouvelle chaque jour")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.upNewsBlack)
                    .multilineTextAlignment(.center)
                    .padding(.top, 24)
                    .padding(.horizontal, 24)
                
                // Description
                Text("Active les notifications et reçois un rappel quotidien pour lire ton article du jour.")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 12)
                    .padding(.horizontal, 24)
                
                // Bonus XP
                HStack(spacing: 8) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.upNewsOrange)
                    
                    Text("Bonus : +200 XP offerts !")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.upNewsOrange)
                }
                .padding(.top, 20)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.upNewsOrange.opacity(0.1))
                )
                .padding(.top, 16)
                
                // Buttons
                VStack(spacing: 12) {
                    // Activer
                    Button {
                        onAllow()
                        dismiss()
                    } label: {
                        Text("Activer")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.upNewsOrange)
                            .cornerRadius(14)
                    }
                    
                    // Plus tard
                    Button {
                        onLater()
                        dismiss()
                    } label: {
                        Text("Plus tard")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 32)
            }
            .frame(maxWidth: 340)
            .background(Color.white)
            .cornerRadius(24)
            .shadow(color: .black.opacity(0.2), radius: 20, y: 10)
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
