import SwiftUI

struct OnboardingView: View {
    @State private var currentPage = 0
    let onFinished: (() -> Void)?

    var body: some View {
        VStack {
            TabView(selection: $currentPage) {
                ForEach(OnboardingPage.pages) { page in
                    OnboardingPageView(page: page)
                        .tag(page.id)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))

            // Page indicators
            HStack(spacing: 8) {
                ForEach(0..<OnboardingPage.pages.count, id: \.self) { index in
                    Capsule()
                        .fill(index == currentPage ? Color.black : Color.gray.opacity(0.3))
                        .frame(width: index == currentPage ? 24 : 8, height: 8)
                        .animation(.easeInOut, value: currentPage)
                }
            }
            .padding(.top, 16)

            Spacer(minLength: 24)

            // CTA Button
            Button(action: onButtonTapped) {
                Text(currentPage == OnboardingPage.pages.count - 1 ? "GO" : "NEXT")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: currentPage == OnboardingPage.pages.count - 1 ? 120 : 90, height: 44)
                    .background(currentPage == OnboardingPage.pages.count - 1 ? Color.orange : Color.black)
                    .cornerRadius(8)
            }
            .padding(.bottom, 24)
        }
    }

    private func onButtonTapped() {
        if currentPage < OnboardingPage.pages.count - 1 {
            withAnimation {
                currentPage += 1
            }
        } else {
            onFinished?()
        }
    }
}

// MARK: - Page View

struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: 24) {
            Spacer(minLength: 20)

            ZStack {
                // Ombre floue basée sur la forme exacte de l'image
                Image(page.imageName)
                    .resizable()
                    .scaledToFit()
                    .blur(radius: 30)
                    .opacity(1)
                    .offset(y: -10)
                    .offset(x: -10)

                // Image principale nette
                Image(page.imageName)
                    .resizable()
                    .scaledToFit()
            }
            .frame(height: 280)  // ✅ FIX : Une seule frame

            VStack(spacing: 16) {
                Text(page.title)
                    .font(.system(size: 28, weight: .bold))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.black)

                Text(page.description)
                    .font(.system(size: 16))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.gray)
            }

            Spacer()
        }
        .padding(.horizontal, 24)
    }
}

#Preview("OnboardingView") {
    OnboardingView(onFinished: {})
}
