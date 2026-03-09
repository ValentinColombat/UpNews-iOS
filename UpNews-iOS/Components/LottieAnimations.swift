//
//  LottieAnimations.swift
//  UpNews-iOS
//
//  Created by Valentin Colombat on 18/01/2026.
//
import SwiftUI
import DotLottie

// MARK: - Animation for locked companions
struct LockLottieView: View {
    var body: some View {
        DotLottieAnimation(
            fileName: "Gift",
            config: AnimationConfig(autoplay: true, loop: true)
        )
        .view()
        .frame(width: 40, height: 40)
    }
}

// MARK: - Flame Animation

struct FlameLottieView: View {
    var body: some View {
        if #available(iOS 18, *) {
            DotLottieAnimation(
                fileName: "Fire",
                config: AnimationConfig(autoplay: true, loop: true)
            )
            .view()
            .frame(width: 40, height: 40)
        } else {
            // iOS 17 : icône statique pour éviter le redraw au premier rendu
            Image(systemName: "flame.fill")
                .foregroundColor(.upNewsOrange)
                .font(.system(size: 24))
                .frame(width: 40, height: 40)
        }
    }
}
