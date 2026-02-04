//
//  WaveformView.swift
//  UpNews-iOS

import SwiftUI

struct WaveformView: View {
    let isPlaying: Bool
    let barCount: Int = 30
    
    @State private var amplitudes: [CGFloat] = []
    @State private var timer: Timer?
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<barCount, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.upNewsBlueMid.opacity(0.8),
                                Color.upNewsBlueMid.opacity(0.4)
                            ],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .frame(width: 2, height: amplitudes.indices.contains(index) ? amplitudes[index] : 4)
            }
        }
        .frame(height: 40)
        .onAppear {
            generateAmplitudes()
        }
        .onChange(of: isPlaying) { oldValue, newValue in
            if newValue {
                startAnimation()
            } else {
                stopAnimation()
            }
        }
        .onDisappear {
            stopAnimation()
        }
    }
    
    private func generateAmplitudes() {
        amplitudes = (0..<barCount).map { _ in CGFloat(4) }
    }
    
    private func startAnimation() {
        // Arrêter le timer existant s'il y en a un
        timer?.invalidate()
        
        // Démarrer un nouveau timer
        timer = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.3)) {
                self.amplitudes = (0..<self.barCount).map { _ in
                    CGFloat.random(in: 8...40)
                }
            }
        }
    }
    
    private func stopAnimation() {
        // Arrêter le timer
        timer?.invalidate()
        timer = nil
        
        // Réinitialiser les barres à la hauteur minimale
        withAnimation(.easeOut(duration: 0.2)) {
            amplitudes = (0..<barCount).map { _ in CGFloat(4) }
        }
    }
}

// Preview
#Preview {
    VStack(spacing: 20) {
        Text("En lecture")
            .font(.caption)
        WaveformView(isPlaying: true)
            .padding()
            .background(Color.white)
            .cornerRadius(12)
        
        Text("En pause")
            .font(.caption)
        WaveformView(isPlaying: false)
            .padding()
            .background(Color.white)
            .cornerRadius(12)
    }
    .padding()
    .background(Color.gray.opacity(0.1))
}
