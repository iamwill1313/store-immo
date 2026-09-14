import SwiftUI
import StoreKit

struct AccountView: View {
    @Environment(AppViewModel.self) private var viewModel
    @State private var showingPersonalInfo = false
    @State private var showingNotificationSettings = false
    @State private var showingPrivacySettings = false
    @State private var showingReportProblem = false
    @State private var showingMyRequests = false
    @State private var showingFAQ = false
    @State private var showingAbout = false
    @State private var showingSignOutConfirmation = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // 📸 En-tête du compte
                    profileHeaderView
                    
                    // 👤 Mon profil
                    sectionView(title: "Mon profil", icon: "person.circle.fill") {
                        navigationButton(
                            title: "Informations personnelles",
                            icon: "person.text.rectangle",
                            action: { showingPersonalInfo = true }
                        )
                    }
                    
                    // 📁 Mes projets (section adaptée au rôle)
                    if viewModel.selectedRole == .seller {
                        sellerProjectsSection
                    } else if viewModel.selectedRole == .agent {
                        agentProjectsSection
                    }
                    
                    // ⚙️ Paramètres
                    sectionView(title: "Paramètres", icon: "gearshape.fill") {
                        navigationButton(
                            title: "Notifications",
                            icon: "bell.fill",
                            action: { showingNotificationSettings = true }
                        )
                        
                        Divider()
                            .padding(.leading, 44)
                        
                        navigationButton(
                            title: "Confidentialité",
                            icon: "hand.raised.fill",
                            action: { showingPrivacySettings = true }
                        )
                    }
                    
                    // 🆘 Aide et support
                    sectionView(title: "Aide et support", icon: "questionmark.circle.fill") {
                        navigationButton(
                            title: "Signaler un problème",
                            icon: "exclamationmark.bubble.fill",
                            action: { showingReportProblem = true }
                        )
                        
                        Divider()
                            .padding(.leading, 44)
                        
                        navigationButton(
                            title: "Mes demandes",
                            icon: "list.bullet.clipboard",
                            action: { showingMyRequests = true }
                        )
                        
                        Divider()
                            .padding(.leading, 44)
                        
                        navigationButton(
                            title: "Questions fréquentes",
                            icon: "questionmark.circle",
                            action: { showingFAQ = true }
                        )
                    }
                    
                    // ℹ️ À propos
                    sectionView(title: "À propos", icon: "info.circle.fill") {
                        navigationButton(
                            title: "Conditions d'utilisation",
                            icon: "doc.text",
                            action: { /* TODO: Open terms */ }
                        )
                        
                        Divider()
                            .padding(.leading, 44)
                        
                        navigationButton(
                            title: "Politique de confidentialité",
                            icon: "lock.shield",
                            action: { /* TODO: Open privacy policy */ }
                        )
                        
                        Divider()
                            .padding(.leading, 44)
                        
                        navigationButton(
                            title: "Noter l'application",
                            icon: "star.fill",
                            action: { rateApp() }
                        )
                        
                        Divider()
                            .padding(.leading, 44)
                        
                        HStack {
                            Image(systemName: "app.badge")
                                .font(.title3)
                                .foregroundStyle(.secondary)
                                .frame(width: 28)
                            
                            Text("Version")
                                .font(.body)
                            
                            Spacer()
                            
                            Text(appVersion)
                                .font(.body)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal)
                    }
                    
                    // 🚪 Déconnexion
                    Button {
                        showingSignOutConfirmation = true
                    } label: {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .font(.title3)
                            Text("Se déconnecter")
                                .font(.body.weight(.medium))
                        }
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("Compte")
            .sheet(isPresented: $showingPersonalInfo) {
                PersonalInfoView()
            }
            .sheet(isPresented: $showingNotificationSettings) {
                NotificationSettingsView()
            }
            .sheet(isPresented: $showingPrivacySettings) {
                PrivacySettingsView()
            }
            .sheet(isPresented: $showingReportProblem) {
                ReportProblemView()
            }
            .sheet(isPresented: $showingMyRequests) {
                MyRequestsView()
            }
            .sheet(isPresented: $showingFAQ) {
                FAQView()
            }
            .alert(
                "Se déconnecter",
                isPresented: $showingSignOutConfirmation
            ) {
                Button("Annuler", role: .cancel) {}
                Button("Se déconnecter", role: .destructive) {
                    viewModel.signOut()
                }
            } message: {
                Text("Êtes-vous sûr de vouloir vous déconnecter ?")
            }
        }
    }
    
    private func sectionView<Content: View>(
        title: String,
        icon: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(Color.accentColor)
                Text(title)
                    .font(.headline)
            }
            .padding(.horizontal)
            
            VStack(spacing: 0) {
                content()
            }
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal)
        }
    }
    
    private func navigationButton(
        title: String,
        icon: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 28)
                
                Text(title)
                    .font(.body)
                    .foregroundStyle(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, 12)
            .padding(.horizontal)
            .contentShape(Rectangle())
        }
    }
    
    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
    
    private func rateApp() {
        // SKStoreReviewController affiche une alerte système native avec 3 boutons :
        // - "Pas maintenant" (= "Plus tard")
        // - "Noter"
        // - "Jamais"
        // Cette alerte est gérée entièrement par iOS, tous les boutons fonctionnent automatiquement.
        // Note : Dans le simulateur, l'interaction peut parfois ne pas fonctionner correctement.
        // Sur un device réel, tous les boutons fonctionnent normalement.
        guard let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene else {
            print("⚠️ Impossible de trouver une scène active pour afficher l'alerte de notation")
            return
        }
        
        SKStoreReviewController.requestReview(in: scene)
    }
    
    // MARK: - Profile Header
    
    private var profileHeaderView: some View {
        VStack(spacing: 16) {
            // Photo de profil
            if viewModel.selectedRole == .agent {
                // Agent : photo depuis le profil agent
                if let photoURL = viewModel.currentAgentProfile?.profilePhotoURL,
                   !photoURL.isEmpty {
                    AsyncImage(url: URL(string: photoURL)) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .foregroundStyle(.gray)
                    }
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
                } else {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .foregroundStyle(.gray)
                        .frame(width: 100, height: 100)
                }
            } else {
                // Vendeur : icône par défaut (pas de photo de profil pour le vendeur)
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .foregroundStyle(.gray)
                    .frame(width: 100, height: 100)
            }
            
            // Nom complet
            Text(fullName)
                .font(.title2.weight(.semibold))
            
            // Informations de contact
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "envelope.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(email)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                if !phoneNumber.isEmpty {
                    HStack(spacing: 8) {
                        Image(systemName: "phone.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(phoneNumber)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .padding(.horizontal)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }
    
    // MARK: - Projects Sections
    
    private var sellerProjectsSection: some View {
        sectionView(title: "Mes projets", icon: "house.fill") {
            HStack {
                Image(systemName: "folder.fill")
                    .font(.title3)
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 28)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Mes biens")
                        .font(.body)
                        .foregroundStyle(.primary)
                    
                    Text("\(viewModel.sellerProjects.count) projet(s)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Button {
                    // Navigation vers l'onglet Dashboard (projets du vendeur)
                    viewModel.sellerTab = .dashboard
                } label: {
                    Text("Voir")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.accentColor)
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal)
        }
    }
    
    private var agentProjectsSection: some View {
        sectionView(title: "Mes projets", icon: "house.fill") {
            HStack {
                Image(systemName: "sparkles")
                    .font(.title3)
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 28)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Opportunités")
                        .font(.body)
                        .foregroundStyle(.primary)
                    
                    Text("\(viewModel.agentOpportunities.count) projet(s)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Button {
                    // Navigation vers l'onglet Opportunities
                    viewModel.agentTab = .opportunities
                } label: {
                    Text("Voir")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.accentColor)
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal)
        }
    }
    
    // MARK: - Computed Properties
    
    private var fullName: String {
        if viewModel.selectedRole == .agent {
            return viewModel.currentAgentProfile?.fullName ?? "Agent"
        } else {
            let firstName = viewModel.sellerPublicFirstName
            let lastName = viewModel.sellerOnboardingDraft.lastName
            if lastName.isEmpty {
                return firstName
            }
            return "\(firstName) \(lastName)"
        }
    }
    
    private var email: String {
        if viewModel.selectedRole == .agent {
            return viewModel.agentOnboardingDraft.email
        } else {
            return viewModel.sellerOnboardingDraft.email
        }
    }
    
    private var phoneNumber: String {
        if viewModel.selectedRole == .agent {
            return viewModel.agentOnboardingDraft.phoneNumber
        } else {
            return viewModel.sellerPhoneNumber
        }
    }
}

#Preview {
    @Previewable @State var viewModel = AppViewModel()
    AccountView()
        .environment(viewModel)
}
