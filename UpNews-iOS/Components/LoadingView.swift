//
//  LoadingView.swift
//  UpNews-iOS
//
//  Created by Valentin Colombat on 20/01/2026.


import SwiftUI

struct LoadingView: View {
    var message: String = "Chargement..."
    
    var body: some View {
        ZStack {
            Color.upNewsBackground
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Icône soleil qui pulse
                Image(systemName: "sun.horizon.fill")
                    .font(. system(size: 70))
                    .foregroundColor(.upNewsOrange)
                    . symbolEffect(.pulse, options: . repeating)
                
                // Texte
                VStack(spacing: 8) {
                    Text("UpNews")
                        . font(.system(size: 36, weight: .bold))
                        .foregroundColor(.upNewsBlack)
                    
                    if !message.isEmpty {
                        Text(message)
                            . font(.system(size: 16))
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("Avec message") {
    LoadingView(message: "Chargement de tes bonnes nouvelles...")
}

#Preview("Sans message") {
    LoadingView(message: "")
}
