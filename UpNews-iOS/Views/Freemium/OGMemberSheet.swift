//
//  OGMemberSheet.swift
//  UpNews-iOS

import SwiftUI

struct OGMemberSheet: View {
    
    let onDismiss: () -> Void
    @State private var showContent = false
    @State private var showConfetti = false
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    dismissView()
                }
            
            VStack(spacing: 0) {
                VStack(spacing: 24) {
                    // Header avec badge OG
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 0.55, green: 0.35, blue: 0.2), // Marron chaud
                                            Color(red: 0.82, green: 0.71, blue: 0.55)  // Beige doré
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 80, height: 80)
                            
                            Text("OG")
                                .font(.system(size: 36, weight: .black))
                                .foregroundColor(.white)
                        }
                        .shadow(color: Color(red: 0.55, green: 0.35, blue: 0.2).opacity(0.4), radius: 20, y: 10)
                        
                        VStack(spacing: 8) {
                            Text("Merci !")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.upNewsBlack)
                            
                            Text("Tu fais partie des 50 premiers membres")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Color(red: 0.55, green: 0.35, blue: 0.2))
                        }
                    }
                    .padding(.top, 24)
                    
                    // Message de remerciement
                    VStack(spacing: 12) {
                        Text("Tu as cru en nous dès le début")
                            .font(.system(size: 17))
                            .foregroundColor(.upNewsBlack)
                            .multilineTextAlignment(.center)
                        
                        Text("Pour te remercier de ton soutien lors des premiers moments d'UpNews, tu as accès à toutes les fonctionnalités de l'application à vie, gratuitement.")
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                    }
                    .padding(.horizontal, 24)
                    
                    // Avantages OG
                    VStack(spacing: 16) {
                        HStack(spacing: 12) {
                            Image(systemName: "infinity")
                                .font(.system(size: 24))
                                .foregroundColor(Color(red: 0.55, green: 0.35, blue: 0.2))
                                .frame(width: 44, height: 44)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(red: 0.82, green: 0.71, blue: 0.55).opacity(0.2))
                                )
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Accès Premium à vie")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.upNewsBlack)
                                
                                Text("Toutes les fonctionnalités, pour toujours")
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                        
                        HStack(spacing: 12) {
                            Image(systemName: "medal.fill")
                                .font(.system(size: 24))
                                .foregroundColor(Color(red: 0.55, green: 0.35, blue: 0.2))
                                .frame(width: 44, height: 44)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(red: 0.55, green: 0.35, blue: 0.2).opacity(0.2))
                                )
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Badge exclusif OG")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.upNewsBlack)
                                
                                Text("Visible uniquement par les pionniers")
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    // Bouton de fermeture
                    Button {
                        dismissView()
                    } label: {
                        Text("Merci !")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.55, green: 0.35, blue: 0.2),
                                        Color(red: 0.82, green: 0.71, blue: 0.55)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(16)
                            .shadow(color: Color(red: 0.55, green: 0.35, blue: 0.2).opacity(0.3), radius: 10, y: 4)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }
                .background(
                    RoundedRectangle(cornerRadius: 28)
                        .fill(Color.white)
                        .shadow(color: .black.opacity(0.15), radius: 20, y: 10)
                )
                .padding(.horizontal, 20)
                .scaleEffect(showContent ? 1 : 0.9)
                .opacity(showContent ? 1 : 0)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                showContent = true
            }
        }
    }
    
    private func dismissView() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            showContent = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            onDismiss()
        }
    }
}

#Preview {
    OGMemberSheet(onDismiss: {})
}
