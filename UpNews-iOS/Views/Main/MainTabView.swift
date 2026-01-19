import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeFeedView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)
            
            CompanionsView()
                .tabItem {
                    Label("Compagnons", systemImage: "pawprint.fill")
                }
                .tag(1)
            
            LibraryView()
                .tabItem {
                    Label("Bibliothèque", systemImage: "books.vertical.fill")
                }
                .tag(2)
            
            ProfileView()
                .tabItem {
                    Label("Profil", systemImage: "person.fill")
                }
                .tag(3)
        }
    }
}

#Preview {
    MainTabView()
}
