import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @EnvironmentObject var userDataService: UserDataService // ✅ AJOUTÉ
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeFeedView()
                .environmentObject(userDataService) // ✅ AJOUTÉ
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)
            
            CompanionsView()
                .environmentObject(userDataService) // ✅ AJOUTÉ
                .tabItem {
                    Label("Compagnons", systemImage: "pawprint.fill")
                }
                .tag(1)
            
            LibraryView()
                .environmentObject(userDataService) // ✅ AJOUTÉ
                .tabItem {
                    Label("Bibliothèque", systemImage: "books.vertical.fill")
                }
                .tag(2)
            
            ProfileView()
                .environmentObject(userDataService) // ✅ AJOUTÉ
                .tabItem {
                    Label("Profil", systemImage: "person.fill")
                }
                .tag(3)
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(UserDataService.shared)
}
