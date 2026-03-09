import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @EnvironmentObject var userDataService: UserDataService
    
    init() {
        if #unavailable(iOS 26) {
            // Désactive l'animation d'entrée du NavigationStack sur iOS 17
            UINavigationBar.appearance().isTranslucent = false
            
            // Personnalisation de la tab bar pour iOS 17 à 18
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor.systemBackground
            
            appearance.stackedLayoutAppearance.selected.iconColor = UIColor(named: "upNewsOrange") ?? .systemOrange
            appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
                .foregroundColor: UIColor(named: "upNewsOrange") ?? UIColor.systemOrange
            ]
            
            appearance.stackedLayoutAppearance.normal.iconColor = UIColor.secondaryLabel
            appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
                .foregroundColor: UIColor.secondaryLabel
            ]
            
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                HomeFeedView(selectedTab: $selectedTab)
                    .environmentObject(userDataService)
            }
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }
            .tag(0)
            
            NavigationStack {
                CompanionsView()
                    .environmentObject(userDataService)
            }
            .tabItem {
                Label("Compagnons", systemImage: "pawprint.fill")
            }
            .tag(1)
            
            NavigationStack {
                LibraryView()
                    .environmentObject(userDataService)
            }
            .tabItem {
                Label("Bibliothèque", systemImage: "books.vertical.fill")
            }
            .tag(2)
            
            NavigationStack {
                ProfileView()
                    .environmentObject(userDataService)
            }
            .tabItem {
                Label("Profil", systemImage: "person.fill")
            }
            .tag(3)
        }
    }
}

