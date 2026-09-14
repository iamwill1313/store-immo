import SwiftUI

// MARK: - Public Home View
// Main entry point for non-authenticated users

struct PublicHomeView: View {
    @Environment(AppViewModel.self) private var viewModel
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // Hero section
                    PublicHeroView()
                    
                    // Actualité immobilière
                    ActualitySectionView()
                    
                    // Biens disponibles
                    PublicPropertiesSectionView()
                    
                    // Nos agents
                    PublicAgentsSectionView()
                    
                    // Choix du parcours (réutilise la logique existante)
                    PublicRoleChoiceView()
                }
                .padding(.vertical, 20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarHidden(true)
        }
        .task {
            // Load public data when the view appears
            // This uses existing data without modifying queries
            await viewModel.loadSellerProjectsFromSupabase()
        }
    }
}

// MARK: - Public Hero View

private struct PublicHeroView: View {
    var body: some View {
        VStack(spacing: 0) {
            Color(red: 0.08, green: 0.18, blue: 0.32)
                .frame(height: 300)
                .overlay {
                    // Background artwork
                    PublicHeroBackgroundArtwork()
                        .allowsHitTesting(false)
                }
                .overlay {
                    // Gradient overlay
                    LinearGradient(
                        colors: [
                            Color(red: 0.08, green: 0.18, blue: 0.32).opacity(0.2),
                            Color(red: 0.08, green: 0.18, blue: 0.32).opacity(0.6),
                            Color(red: 0.08, green: 0.18, blue: 0.32).opacity(0.95),
                            Color.black.opacity(0.9)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .allowsHitTesting(false)
                }
                .overlay {
                    // Content
                    VStack(spacing: 16) {
                        Spacer(minLength: 40)
                        
                        // Logo/Title
                        VStack(spacing: 10) {
                            Text("Store Immo")
                                .font(.system(size: 38, weight: .bold, design: .default).width(.expanded))
                                .tracking(1.2)
                                .foregroundStyle(.white)
                                .multilineTextAlignment(.center)
                            
                            Text("L'immobilier autrement.")
                                .font(.title2.weight(.semibold))
                                .foregroundStyle(.white)
                                .multilineTextAlignment(.center)
                            
                            Text("Trouvez votre agent ou vendez en toute sérénité.")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.white.opacity(0.88))
                                .multilineTextAlignment(.center)
                        }
                        
                        // Trust badges
                        HStack(spacing: 8) {
                            PublicTrustBadge(icon: "map", text: "France")
                            PublicTrustBadge(icon: "checkmark.seal", text: "Vérifiés")
                            PublicTrustBadge(icon: "shield.checkered", text: "Sécurisé")
                        }
                        
                        Spacer(minLength: 24)
                    }
                    .padding(.horizontal, 24)
                }
                .clipShape(RoundedRectangle(cornerRadius: 28))
                .shadow(color: .black.opacity(0.15), radius: 20, y: 10)
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - Public Hero Background Artwork

private struct PublicHeroBackgroundArtwork: View {
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                // Gradient base
                LinearGradient(
                    colors: [Color.white.opacity(0.25), .clear, Color.black.opacity(0.2)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                // Building cards
                VStack(spacing: 0) {
                    Spacer(minLength: 0)
                    HStack(alignment: .bottom, spacing: 12) {
                        Spacer(minLength: 0)
                        PublicHeroBuildingCard(
                            icon: "building.2",
                            accent: "sun.max",
                            width: proxy.size.width * 0.28,
                            height: 140
                        )
                        PublicHeroBuildingCard(
                            icon: "house",
                            accent: "tree",
                            width: proxy.size.width * 0.36,
                            height: 190
                        )
                        PublicHeroBuildingCard(
                            icon: "building.columns",
                            accent: "sparkles",
                            width: proxy.size.width * 0.22,
                            height: 120
                        )
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 28)
                }
            }
        }
    }
}

// MARK: - Public Hero Building Card

private struct PublicHeroBuildingCard: View {
    let icon: String
    let accent: String
    let width: CGFloat
    let height: CGFloat
    
    var body: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.35),
                        Color.white.opacity(0.1),
                        Color.black.opacity(0.15)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: width, height: height)
            .overlay(alignment: .topTrailing) {
                Image(systemName: accent)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.9))
                    .padding(10)
            }
            .overlay {
                VStack(spacing: 8) {
                    Spacer(minLength: 0)
                    Image(systemName: icon)
                        .font(.system(size: min(width, height) * 0.3, weight: .regular))
                        .foregroundStyle(.white.opacity(0.95))
                    Spacer(minLength: 0)
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(.white.opacity(0.15), lineWidth: 1)
            }
    }
}

// MARK: - Public Trust Badge

private struct PublicTrustBadge: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.caption.weight(.semibold))
            Text(text)
                .font(.caption.weight(.semibold))
                .lineLimit(1)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(.white.opacity(0.16), in: .capsule)
        .overlay {
            Capsule(style: .continuous)
                .strokeBorder(.white.opacity(0.12), lineWidth: 1)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Public Role Choice View
// Reuses existing RoleSelectionView logic without modifying it

private struct PublicRoleChoiceView: View {
    @Environment(AppViewModel.self) private var viewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Section header
            VStack(alignment: .leading, spacing: 8) {
                Text("Choisissez votre espace")
                    .font(.title2.weight(.bold))
                    .padding(.horizontal, 20)
                
                Text("Une expérience pensée pour publier vite côté vendeur et convertir mieux côté agent.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 20)
            }
            
            // Role cards
            VStack(spacing: 14) {
                ForEach(UserRole.allCases) { role in
                    Button {
                        withAnimation(.smooth(duration: 0.35)) {
                            viewModel.chooseRole(role)
                        }
                    } label: {
                        PublicRoleCard(role: role)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
            
            // Trust summary
            PublicTrustSummary()
                .padding(.horizontal, 20)
        }
    }
}

// MARK: - Public Role Card

private struct PublicRoleCard: View {
    let role: UserRole
    
    private var eyebrow: String {
        switch role {
        case .seller:
            "Parcours express"
        case .agent:
            "Espace professionnel"
        }
    }
    
    private var punchline: String {
        switch role {
        case .seller:
            "Publiez vite, comparez les profils et gardez la main du premier contact jusqu'au mandat."
        case .agent:
            "Recevez les biens de votre secteur, candidatez une fois et pilotez chaque mandat au même endroit."
        }
    }
    
    private var featurePills: [String] {
        switch role {
        case .seller:
            ["Simple", "Rapide", "Gratuit"]
        case .agent:
            ["Local", "Premium", "Vérifié"]
        }
    }
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 16) {
            VStack(alignment: .leading, spacing: 10) {
                // Eyebrow
                Text(eyebrow)
                    .font(.caption.weight(.semibold))
                    .textCase(.uppercase)
                    .foregroundStyle(role == .seller ? Color(red: 0.08, green: 0.18, blue: 0.32).opacity(0.78) : .white.opacity(0.72))
                
                // Title
                Text(role.title)
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(role == .seller ? Color(red: 0.08, green: 0.18, blue: 0.32) : .white)
                    .fixedSize(horizontal: false, vertical: true)
                
                // Subtitle
                Text(role.subtitle)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(role == .seller ? Color.primary : .white)
                    .fixedSize(horizontal: false, vertical: true)
                
                // Punchline
                Text(punchline)
                    .font(.subheadline)
                    .foregroundStyle(role == .seller ? Color.secondary : .white.opacity(0.82))
                    .fixedSize(horizontal: false, vertical: true)
                
                // Feature pills
                HStack(spacing: 7) {
                    ForEach(featurePills, id: \.self) { pill in
                        Text(pill)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(role == .seller ? Color(red: 0.08, green: 0.18, blue: 0.32) : .white)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 6)
                            .background(role == .seller ? Color.white.opacity(0.78) : .white.opacity(0.12), in: .capsule)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Icon and arrow
            VStack(alignment: .trailing, spacing: 12) {
                Image(systemName: role.symbolName)
                    .font(.system(size: 46, weight: .regular))
                    .foregroundStyle(role == .seller ? Color(red: 0.08, green: 0.18, blue: 0.32) : .white)
                    .frame(width: 80, height: 80)
                    .background(role == .seller ? Color.white.opacity(0.78) : .white.opacity(0.12), in: .circle)
                
                Image(systemName: "arrow.right")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(role == .seller ? Color(red: 0.08, green: 0.18, blue: 0.32) : .white)
                    .frame(width: 42, height: 42)
                    .background(role == .seller ? Color.white.opacity(0.72) : .white.opacity(0.12), in: .circle)
            }
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            if role == .seller {
                LinearGradient(
                    colors: [
                        Color.white,
                        Color(red: 235 / 255, green: 244 / 255, blue: 252 / 255),
                        Color(red: 217 / 255, green: 232 / 255, blue: 247 / 255)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            } else {
                LinearGradient(
                    colors: [
                        Color(red: 0.36, green: 0.34, blue: 0.92),
                        Color(red: 0.28, green: 0.26, blue: 0.78),
                        Color(red: 0.20, green: 0.18, blue: 0.65)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
        .overlay(alignment: .topTrailing) {
            if role == .seller {
                HStack(spacing: 9) {
                    Image(systemName: "building.2")
                    Image(systemName: "sun.max")
                }
                .font(.title2.weight(.regular))
                .foregroundStyle(Color(red: 0.08, green: 0.18, blue: 0.32).opacity(0.16))
                .padding(16)
                .allowsHitTesting(false)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 26))
        .overlay {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .strokeBorder(role == .seller ? .white.opacity(0.9) : .white.opacity(0.08), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.06), radius: 16, y: 8)
    }
}

// MARK: - Public Trust Summary

private struct PublicTrustSummary: View {
    var body: some View {
        HStack(spacing: 10) {
            PublicTrustSummaryBadge(icon: "person.text.rectangle", title: "Profils vérifiés")
            PublicTrustSummaryBadge(icon: "bubble.left.and.bubble.right", title: "Chat privé")
            PublicTrustSummaryBadge(icon: "calendar", title: "RDV centralisés")
        }
        .padding(12)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 20))
    }
}

// MARK: - Public Trust Summary Badge

private struct PublicTrustSummaryBadge: View {
    let icon: String
    let title: String
    
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 28, weight: .regular))
                .foregroundStyle(Color(red: 0.08, green: 0.18, blue: 0.32))
                .frame(width: 48, height: 48)
                .background(Color(.systemBackground), in: .circle)
            
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 6)
        .background(Color(.tertiarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    @Previewable @State var viewModel = AppViewModel()
    PublicHomeView()
        .environment(viewModel)
}
