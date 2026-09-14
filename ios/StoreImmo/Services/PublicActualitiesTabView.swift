import SwiftUI

/// Public tab displaying real estate news and updates.
/// REFONTE VISUELLE — Design Store Immo moderne avec identité navy/slate
struct PublicActualitiesTabView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Hero section avec gradient Store Immo
                    PublicHeroSection()
                    
                    // News section
                    ActualitySectionView()
                        .padding(.top, 28)
                        .padding(.bottom, 32)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Actualités")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

/// Hero section moderne avec gradient navy Store Immo
private struct PublicHeroSection: View {
    @Environment(AppViewModel.self) private var viewModel
    
    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 12) {
                // Store Immo branding avec icône
                HStack(spacing: 10) {
                    Image(systemName: "building.2.fill")
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundStyle(.white)
                    
                    Text("Store Immo")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(.white)
                }
                
                // Baseline
                Text("La plateforme qui connecte vendeurs et agents immobiliers partout en France")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 24)
            }
            
            // Trust badges
            HStack(spacing: 12) {
                TrustBadge(icon: "checkmark.seal.fill", text: "Agents vérifiés")
                TrustBadge(icon: "map.fill", text: "France entière")
                TrustBadge(icon: "shield.checkered", text: "Sécurisé")
            }
            .padding(.horizontal, 16)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(StoreImmoTheme.heroGradient)
    }
}

private struct TrustBadge: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption.weight(.semibold))
            Text(text)
                .font(.caption.weight(.semibold))
                .lineLimit(1)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.white.opacity(0.16), in: .capsule)
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    PublicActualitiesTabView()
        .environment(AppViewModel())
}
