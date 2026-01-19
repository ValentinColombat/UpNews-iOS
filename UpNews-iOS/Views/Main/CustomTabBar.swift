//
//  CustomTabBar.swift
//  UpNews-iOS
//
//  Created by Valentin Colombat on 11/01/2026.
//
//
//  CustomTabBar.swift
//  UpNews-iOS

import SwiftUI

// MARK: - Tab Items

enum TabItem: String, CaseIterable {
    case home = "Home"
    case companions = "Compagnons"
    case alarm = "Réveil"
    case profile = "Profil"
    
    var icon: String {
        switch self {
        case .home:
            return "house.fill"
        case .companions:
            return "pawprint.fill"
        case .alarm:
            return "bell.fill"
        case .profile:
            return "person.fill"
        }
    }
    
    var iconOutline: String {
        switch self {
        case .home:
            return "house"
        case .companions:
            return "pawprint"
        case .alarm:
            return "bell"
        case .profile:
            return "person"
        }
    }
}

// MARK: - Custom Tab Bar

struct CustomTabBar: View {
    @Binding var selectedTab: TabItem
    @Binding var isVisible: Bool
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(TabItem.allCases, id: \.self) { tab in
                TabBarButton(
                    tab: tab,
                    isSelected: selectedTab == tab
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = tab
                    }
                }
            }
        }
        .frame(height: 60)
        .background(
            ZStack {
                // Fond blanc avec blur
                Rectangle()
                    .fill(.ultraThinMaterial)
                
                // Ligne du haut
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 0.5)
                    .frame(maxHeight: .infinity, alignment: .top)
            }
        )
        .offset(y: isVisible ? 0 : 100)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isVisible)
    }
}

// MARK: - Tab Bar Button

struct TabBarButton: View {
    let tab: TabItem
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: isSelected ? tab.icon : tab.iconOutline)
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? .upNewsOrange : .gray)
                    .frame(height: 28)
                
                Text(tab.rawValue)
                    .font(.system(size: 10, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .upNewsOrange : .gray)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(TabBarButtonStyle())
    }
}

// MARK: - Button Style (Remove default effects)

struct TabBarButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview {
    VStack {
        Spacer()
        CustomTabBar(
            selectedTab: .constant(.home),
            isVisible: .constant(true)
        )
    }
    .background(Color.upNewsBackground)
}
