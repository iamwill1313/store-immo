import SwiftUI

/// Root view for the public (unauthenticated) part of the app.
/// Displays a TabView with 4 tabs: Actualités, Biens, Professionnels, Compte.
struct PublicRootView: View {
    @Environment(AppViewModel.self) private var viewModel
    @State private var selectedTab: PublicTab = .actualites
    
    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Actualités", systemImage: "newspaper.fill", value: .actualites) {
                PublicActualitiesTabView()
            }
            
            Tab("Biens", systemImage: "house.fill", value: .biens) {
                PublicPropertiesTabView()
            }
            
            Tab("Professionnels", systemImage: "person.2.fill", value: .professionnels) {
                PublicProfessionalsTabView()
            }
            
            Tab("Compte", systemImage: "person.crop.circle.fill", value: .compte) {
                PublicAccountTabView()
            }
        }
        .tint(StoreImmoTheme.navy)
    }
}

/// Enum representing the public tabs
enum PublicTab: Hashable {
    case actualites
    case biens
    case professionnels
    case compte
}

#Preview {
    PublicRootView()
        .environment(AppViewModel())
}
