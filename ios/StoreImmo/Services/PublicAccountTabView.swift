import SwiftUI

/// Public account tab for unauthenticated users.
/// REFONTE VISUELLE — Design moderne pour la sélection de rôle et authentification
struct PublicAccountTabView: View {
    @Environment(AppViewModel.self) private var viewModel
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    // Hero section avec branding Store Immo
                    PublicAccountHeroSection()
                        .padding(.top, 8)
                    
                    // Role selection moderne
                    PublicRoleSelectionSection()
                        .padding(.horizontal, 20)
                    
                    // Trust badges
                    PublicTrustBadgesSection()
                        .padding(.horizontal, 20)
                        .padding(.bottom, 32)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Compte")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - Hero Section

private struct PublicAccountHeroSection: View {
    var body: some View {
        VStack(spacing: 18) {
            // Store Immo branding
            HStack(spacing: 10) {
                Image(systemName: "building.2.fill")
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundStyle(.white)
                
                Text("Store Immo")
                    .font(.system(size: 38, weight: .bold))
                    .foregroundStyle(.white)
            }
            
            // Baseline
            Text("Vendez votre bien ou développez votre activité immobilière")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white.opacity(0.9))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 28)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 36)
        .background(StoreImmoTheme.heroGradient)
    }
}

// MARK: - Role Selection Section

private struct PublicRoleSelectionSection: View {
    @Environment(AppViewModel.self) private var viewModel
    
    var body: some View {
        VStack(spacing: 20) {
            // Section title
            VStack(spacing: 8) {
                Text("Choisissez votre espace")
                    .font(.title2.bold())
                    .foregroundStyle(.primary)
                
                Text("Une expérience pensée pour publier vite côté vendeur et convertir mieux côté agent")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.bottom, 8)
            
            // Role cards
            VStack(spacing: 14) {
                // Seller card
                PublicRoleModernCard(
                    role: .seller,
                    action: {
                        withAnimation(.smooth(duration: 0.35)) {
                            viewModel.chooseRole(.seller)
                        }
                    }
                )
                
                // Agent card
                PublicRoleModernCard(
                    role: .agent,
                    action: {
                        withAnimation(.smooth(duration: 0.35)) {
                            viewModel.chooseRole(.agent)
                        }
                    }
                )
            }
        }
    }
}

// MARK: - Modern Role Card

private struct PublicRoleModernCard: View {
    let role: UserRole
    let action: () -> Void
    
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
            ["Simple", "Rapide"]
        case .agent:
            ["Local", "Premium"]
        }
    }
    
    private var backgroundColor: LinearGradient {
        switch role {
        case .seller:
            LinearGradient(
                colors: [
                    Color.white,
                    Color(red: 235 / 255, green: 244 / 255, blue: 252 / 255),
                    Color(red: 217 / 255, green: 232 / 255, blue: 247 / 255)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .agent:
            StoreImmoTheme.heroGradient
        }
    }
    
    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 12) {
                    Text(eyebrow)
                        .font(.caption.weight(.bold))
                        .textCase(.uppercase)
                        .foregroundStyle(role == .seller ? StoreImmoTheme.navy.opacity(0.7) : .white.opacity(0.75))
                    
                    Text(role.title)
                        .font(.title.bold())
                        .foregroundStyle(role == .seller ? StoreImmoTheme.navy : .white)
                    
                    Text(role.subtitle)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(role == .seller ? .primary : .white)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Text(punchline)
                        .font(.footnote)
                        .foregroundStyle(role == .seller ? .secondary : .white.opacity(0.85))
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 2)
                    
                    HStack(spacing: 8) {
                        ForEach(featurePills, id: \.self) { pill in
                            Text(pill)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(role == .seller ? StoreImmoTheme.navy : .white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(
                                    role == .seller ? Color.white.opacity(0.7) : .white.opacity(0.14),
                                    in: .capsule
                                )
                        }
                    }
                    .padding(.top, 4)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                VStack(spacing: 10) {
                    Image(systemName: role.symbolName)
                        .font(.system(size: 42))
                        .foregroundStyle(role == .seller ? StoreImmoTheme.navy : .white)
                        .frame(width: 76, height: 76)
                        .background(
                            role == .seller ? Color.white.opacity(0.7) : .white.opacity(0.14),
                            in: .circle
                        )
                    
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.title2)
                        .foregroundStyle(role == .seller ? StoreImmoTheme.navy : .white)
                }
            }
            .padding(22)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(backgroundColor)
            .clipShape(.rect(cornerRadius: 24))
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(
                        role == .seller ? .white.opacity(0.8) : .white.opacity(0.12),
                        lineWidth: 1
                    )
            }
            .shadow(color: .black.opacity(0.08), radius: 14, y: 6)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Trust Badges Section

private struct PublicTrustBadgesSection: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("Pourquoi choisir Store Immo ?")
                .font(.headline.bold())
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 10) {
                PublicTrustBadge(
                    icon: "checkmark.seal.fill",
                    title: "Profils vérifiés",
                    description: "Tous nos agents sont vérifiés",
                    color: StoreImmoTheme.navy
                )
                
                PublicTrustBadge(
                    icon: "bubble.left.and.bubble.right.fill",
                    title: "Chat privé sécurisé",
                    description: "Échangez en toute confidentialité",
                    color: .blue
                )
                
                PublicTrustBadge(
                    icon: "map.fill",
                    title: "France entière",
                    description: "Des biens et agents partout",
                    color: .green
                )
            }
        }
        .padding(18)
        .background(Color(.secondarySystemBackground), in: .rect(cornerRadius: 20))
    }
}

private struct PublicTrustBadge: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
                .frame(width: 48, height: 48)
                .background(color.opacity(0.12), in: .circle)
            
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding(12)
        .background(Color(.tertiarySystemBackground), in: .rect(cornerRadius: 14))
    }
}

#Preview {
    PublicAccountTabView()
        .environment(AppViewModel())
}
        .buttonStyle(.plain)
    }
}

// MARK: - Authentication Section

private struct PublicAuthenticationSection: View {
    @State private var showLoginSheet = false
    @State private var showSignupSheet = false
    
    var body: some View {
        VStack(spacing: 12) {
            // Login button
            Button {
                showLoginSheet = true
            } label: {
                Text("Se connecter")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.blue)
                    )
            }
            .buttonStyle(.plain)
            
            // Signup button
            Button {
                showSignupSheet = true
            } label: {
                Text("Créer un compte")
                    .font(.headline)
                    .foregroundStyle(.blue)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.blue, lineWidth: 2)
                    )
            }
            .buttonStyle(.plain)
        }
        .sheet(isPresented: $showLoginSheet) {
            PublicAuthenticationInfoSheet(mode: .login)
        }
        .sheet(isPresented: $showSignupSheet) {
            PublicAuthenticationInfoSheet(mode: .signup)
        }
    }
}

// MARK: - Authentication Info Sheet

private struct PublicAuthenticationInfoSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppViewModel.self) private var viewModel
    
    enum Mode {
        case login
        case signup
        
        var title: String {
            switch self {
            case .login: return "Se connecter"
            case .signup: return "Créer un compte"
            }
        }
        
        var message: String {
            switch self {
            case .login:
                return "Pour vous connecter, veuillez d'abord choisir votre espace (Vendeur ou Agent) ci-dessus."
            case .signup:
                return "Pour créer un compte, veuillez d'abord choisir votre espace (Vendeur ou Agent) ci-dessus."
            }
        }
    }
    
    let mode: Mode
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()
                
                // Icon
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.blue)
                
                // Title
                Text(mode.title)
                    .font(.title2)
                    .fontWeight(.bold)
                
                // Message
                Text(mode.message)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Spacer()
                
                // Close button
                Button {
                    dismiss()
                } label: {
                    Text("Compris")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.blue)
                        )
                }
                .buttonStyle(.plain)
                .padding(.horizontal)
            }
            .padding()
            .navigationTitle(mode.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Trust Badges Section

private struct PublicTrustBadgesSection: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("Pourquoi choisir Store Immo ?")
                .font(.headline)
                .foregroundStyle(.primary)
            
            VStack(spacing: 12) {
                PublicTrustBadge(
                    icon: "checkmark.shield.fill",
                    title: "Sécurisé",
                    color: .green
                )
                
                PublicTrustBadge(
                    icon: "person.2.fill",
                    title: "Professionnels vérifiés",
                    color: .blue
                )
                
                PublicTrustBadge(
                    icon: "bolt.fill",
                    title: "Simple et rapide",
                    color: .orange
                )
            }
        }
        .padding(.vertical, 24)
        .padding(.bottom)
    }
}

private struct PublicTrustBadge: View {
    let icon: String
    let title: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(color)
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(color.opacity(0.1))
                )
            
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.primary)
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
        )
    }
}

#Preview {
    PublicAccountTabView()
        .environment(AppViewModel())
}
