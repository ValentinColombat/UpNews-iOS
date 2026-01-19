//
//  ProgressBar.swift
//  UpNews-iOS
//
//  Created by Valentin Colombat on 19/01/2026.
//
import SwiftUI

// MARK: - XP Progress Bar (Horizontal & Vertical)

struct ProgressBar: View {
    let progress: CGFloat
    let orientation: Orientation
    
    enum Orientation {
        case horizontal
        case vertical
    }
    
    @State private var currentProgress: CGFloat = 0
    @State private var particles: [Particle] = []
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: orientation == .horizontal ? .leading : .bottom) {
                // Background
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.15))
                
                // Progress bar avec particules
                ZStack(alignment: orientation == .horizontal ? .leading : .bottom) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.upNewsOrange.opacity(0.6),
                                    Color.upNewsOrange,
                                    Color.upNewsOrange.opacity(0.8),
                                    Color.upNewsOrange
                                ],
                                startPoint: orientation == .horizontal ? .leading : .bottom,
                                endPoint: orientation == .horizontal ? .trailing : .top
                            )
                        )
                    
                    // Particules
                    ForEach(particles) { particle in
                        Circle()
                            .fill(Color.white)
                            .frame(width: particle.size, height: particle.size)
                            .offset(
                                x: orientation == .horizontal ? particle.x : particle.y,
                                y: orientation == .horizontal ? particle.y : -particle.x
                            )
                            .opacity(particle.opacity * 0.6)
                            .blur(radius: 2)
                    }
                }
                .frame(
                    width: orientation == .horizontal ? geometry.size.width * currentProgress : geometry.size.width,
                    height: orientation == .horizontal ? geometry.size.height : geometry.size.height * currentProgress
                )
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .shadow(color: Color.upNewsOrange.opacity(0.8), radius: 4, x: 0, y: 0)
            }
            .onAppear {
                withAnimation(.spring(response: 5, dampingFraction: 0.7)) {
                    currentProgress = progress
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    generateParticles(size: orientation == .horizontal ? geometry.size.width : geometry.size.height)
                }
            }
        }
        .frame(
            width: orientation == .horizontal ? nil : 12,
            height: orientation == .horizontal ? 12 : nil
        )
    }
    
    private func generateParticles(size: CGFloat) {
        for _ in 0..<8 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 0...3.0)) {
                particles.append(Particle(
                    x: CGFloat.random(in: 0...20),
                    y: CGFloat.random(in: -3...3),
                    size: CGFloat.random(in: 3...5),
                    opacity: 0.6
                ))
                animateParticle(at: particles.count - 1, maxSize: size * progress)
            }
        }
    }
    
    private func animateParticle(at index: Int, maxSize: CGFloat) {
        let target = maxSize * 0.85
        
        withAnimation(
            .linear(duration: Double.random(in: 6.0...10.0))
            .repeatForever(autoreverses: false)
        ) {
            particles[index].x = target
        }
    }
}

// Modèle pour les particules
struct Particle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var size: CGFloat
    var opacity: Double
}
