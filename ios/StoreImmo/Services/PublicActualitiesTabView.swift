import SwiftUI

/// Public tab displaying real estate news and updates.
/// REFONTE VISUELLE — Design minimaliste blanc Apple moderne
struct PublicActualitiesTabView: View {
    @Environment(AppViewModel.self) private var viewModel
    @State private var selectedActuality: ActualityItem?
    
    private let actualities = ActualityDataFactory.makeMockActualities()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Hero Store Immo
                    StoreImmoHeroSection()
                        .padding(.horizontal, 24)
                        .padding(.top, 24)
                        .padding(.bottom, 32)
                    
                    // Section Actualité immobilière
                    PublicActualitiesContentSection(
                        actualities: actualities,
                        selectedActuality: $selectedActuality
                    )
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
                    
                    // Bloc "Un projet immobilier ?"
                    PublicActualitiesProjectSection()
                        .padding(.horizontal, 24)
                        .padding(.bottom, 40)
                }
            }
            .background(Color(.systemBackground))
            .navigationTitle("Actualités")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $selectedActuality) { actuality in
                ActualityDetailView(actuality: actuality)
            }
        }
    }
}

// MARK: - Content Section (Actualité immobilière)

private struct PublicActualitiesContentSection: View {
    let actualities: [ActualityItem]
    @Binding var selectedActuality: ActualityItem?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Titre de section avec icône
            HStack(spacing: 12) {
                Image(systemName: "newspaper.fill")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(StoreImmoTheme.navy)
                
                Text("Actualité immobilière")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(StoreImmoTheme.navy)
            }
            
            // Sous-titre
            if actualities.isEmpty {
                Text("Les actualités du marché immobilier seront bientôt\ndisponibles.")
                    .font(.system(size: 20, weight: .regular))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 4)
            } else {
                // Scroll horizontal des cartes d'actualités
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(actualities) { actuality in
                            ActualityMinimalCard(actuality: actuality)
                                .onTapGesture {
                                    selectedActuality = actuality
                                }
                        }
                    }
                }
                .padding(.top, 8)
            }
        }
    }
}

// MARK: - Minimal Actuality Card (Carte d'actualité minimaliste)

private struct ActualityMinimalCard: View {
    let actuality: ActualityItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Badge catégorie
            HStack(spacing: 6) {
                Image(systemName: actuality.category.symbolName)
                    .font(.system(size: 11, weight: .semibold))
                Text(actuality.category.rawValue)
                    .font(.system(size: 11, weight: .semibold))
                    .textCase(.uppercase)
            }
            .foregroundStyle(.secondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color(.systemGray6), in: .capsule)
            
            // Titre
            Text(actuality.title)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.primary)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
            
            // Excerpt
            Text(actuality.excerpt)
                .font(.system(size: 17, weight: .regular))
                .foregroundStyle(.secondary)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
            
            // Date
            HStack(spacing: 6) {
                Image(systemName: "calendar")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                Text(actuality.date, style: .date)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 300, height: 260)
        .padding(20)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
    }
}

// MARK: - Project Section (Un projet immobilier ?)

private struct PublicActualitiesProjectSection: View {
    @Environment(AppViewModel.self) private var viewModel
    
    var body: some View {
        VStack(spacing: 12) {
            // Message pour les utilisateurs
            VStack(spacing: 4) {
                Text("Un projet immobilier ?")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                
                Text("Vendre un bien ou développer votre\nactivité avec Store Immo.")
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Bouton Commencer
            Button(action: {
                // Navigation vers la page Compte pour choisir un rôle
                // L'utilisateur sera redirigé via la TabView
            }) {
                HStack(spacing: 6) {
                    Text("Commencer")
                        .font(.system(size: 16, weight: .semibold))
                    
                    Image(systemName: "arrow.right")
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 46)
                .background(StoreImmoTheme.navy)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.03), radius: 6, y: 2)
    }
}

// MARK: - Actuality Detail View (Vue détail d'actualité)

private struct ActualityDetailView: View {
    let actuality: ActualityItem
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Badge catégorie
                    HStack(spacing: 6) {
                        Image(systemName: actuality.category.symbolName)
                            .font(.subheadline.weight(.semibold))
                        Text(actuality.category.rawValue)
                            .font(.subheadline.weight(.semibold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(categoryColor(for: actuality.category), in: .capsule)
                    
                    // Titre
                    Text(actuality.title)
                        .font(.title.weight(.bold))
                    
                    // Date
                    HStack {
                        Image(systemName: "calendar")
                            .font(.subheadline)
                        Text(actuality.date, style: .date)
                            .font(.subheadline)
                    }
                    .foregroundStyle(.secondary)
                    
                    Divider()
                    
                    // Excerpt
                    Text(actuality.excerpt)
                        .font(.body.weight(.medium))
                        .foregroundStyle(.secondary)
                    
                    // Contenu complet
                    Text(actuality.content)
                        .font(.body)
                        .lineSpacing(4)
                    
                    Spacer(minLength: 40)
                }
                .padding(20)
            }
            .navigationTitle("Actualité")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fermer") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func categoryColor(for category: ActualityCategory) -> Color {
        switch category {
        case .market:
            return .blue
        case .regulation:
            return .purple
        case .dpe:
            return .green
        case .investment:
            return .orange
        case .local:
            return .cyan
        case .national:
            return .indigo
        }
    }
}

// MARK: - Store Immo Hero Section

/// Hero section "Store Immo" — Bloc de storytelling centré
private struct StoreImmoHeroSection: View {
    var body: some View {
        VStack(spacing: 8) {
            // Titre principal
            Text("Store Immo")
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
            
            // Sous-titre
            Text("Votre projet immobilier, au\u{00A0}même endroit.")
                .font(.system(size: 17, weight: .regular))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
}

#Preview {
    PublicActualitiesTabView()
        .environment(AppViewModel())
}
