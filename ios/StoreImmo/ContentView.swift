import SwiftUI
import PhotosUI

struct ContentView: View {
    @Environment(AppViewModel.self) private var viewModel
    @Environment(StoreImmoReadinessService.self) private var readiness
    @Environment(StoreImmoNotificationService.self) private var notificationService

    var body: some View {
        Group {
            if let role = viewModel.selectedRole {
                if viewModel.isAuthenticated {
                    switch role {
                    case .seller:
                        if viewModel.hasCompletedSellerOnboarding {
                            SellerRootView()
                        } else {
                            SellerOnboardingView()
                        }
                    case .agent:
                        if viewModel.hasCompletedAgentOnboarding {
                            AgentRootView()
                        } else if viewModel.hasCompletedAgentProfileOnboarding {
                            AgentSubscriptionOnboardingView()
                        } else {
                            AgentProfileOnboardingView()
                        }
                    }
                } else {
                    AuthenticationFlowView(role: role)
                }
            } else {
                RoleSelectionView()
            }
        }
        .tint(.blue)
        .background(Color(.systemBackground))
        .environment(readiness)
        .task {
            await notificationService.refreshAuthorizationStatus()
        }
    }
}

private struct RoleSelectionView: View {
    @Environment(AppViewModel.self) private var viewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 30) {
                    HeroSectionView()

                    VStack(alignment: .leading, spacing: 16) {
                        Text("Choisissez votre espace")
                            .font(.title2.weight(.bold))

                        Text("Une expérience pensée pour publier vite côté vendeur et convertir mieux côté agent.")
                            .font(.body)
                            .foregroundStyle(.secondary)

                        ForEach(UserRole.allCases) { role in
                            Button {
                                withAnimation(.smooth(duration: 0.35)) {
                                    viewModel.chooseRole(role)
                                }
                            } label: {
                                RoleCardView(role: role)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    TrustSummaryView()
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 28)
            }
            .navigationBarHidden(true)
        }
    }
}

private struct HeroSectionView: View {
    var body: some View {
        Color(StoreImmoTheme.navy)
            .frame(height: 390)
            .overlay {
                HeroBackgroundArtworkView()
                    .allowsHitTesting(false)
            }
            .overlay {
                LinearGradient(
                    colors: [
                        StoreImmoTheme.navy.opacity(0.16),
                        StoreImmoTheme.navy.opacity(0.48),
                        StoreImmoTheme.navy.opacity(0.9),
                        Color.black.opacity(0.92)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .allowsHitTesting(false)
            }
            .clipShape(.rect(cornerRadius: 36))
            .overlay {
                VStack(spacing: 18) {
                    Spacer(minLength: 48)

                    VStack(spacing: 12) {
                        Text("Store Immo")
                            .font(.system(size: 36, weight: .bold, design: .default).width(.expanded))
                            .tracking(1.2)
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)
                            .lineLimit(1)
                            .minimumScaleFactor(0.9)

                        Text("Choisissez mieux.\nVendez sereinement.")
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .minimumScaleFactor(0.92)
                            .fixedSize(horizontal: false, vertical: true)

                        Text("Des vendeurs et des pros vérifiés, partout en France.")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.white.opacity(0.88))
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity)

                    HStack(spacing: 8) {
                        HighlightChipView(text: "France", symbolName: "map")
                        HighlightChipView(text: "Avis vérifiés", symbolName: "checkmark.seal")
                        HighlightChipView(text: "Pros vérifiés", symbolName: "person.badge.shield.checkmark")
                    }

                    Spacer(minLength: 28)
                }
                .padding(.horizontal, 24)
                .padding(.top, 26)
                .padding(.bottom, 22)
            }
            .shadow(color: .black.opacity(0.18), radius: 24, y: 12)
    }
}

private struct HighlightChipView: View {
    let text: String
    let symbolName: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: symbolName)
                .font(.caption.weight(.semibold))
            Text(text)
                .font(.caption.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.9)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 10)
        .background(.white.opacity(0.16), in: .capsule)
        .overlay {
            Capsule(style: .continuous)
                .strokeBorder(.white.opacity(0.14), lineWidth: 1)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct RoleCardView: View {
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
            ["Simple", "Rapide"]
        case .agent:
            ["Local", "Premium"]
        }
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 18) {
            VStack(alignment: .leading, spacing: 12) {
                Text(eyebrow)
                    .font(.caption.weight(.semibold))
                    .textCase(.uppercase)
                    .foregroundStyle(role == .seller ? StoreImmoTheme.navy.opacity(0.78) : .white.opacity(0.72))

                Text(role.title)
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(role == .seller ? StoreImmoTheme.navy : .white)
                    .fixedSize(horizontal: false, vertical: true)

                Text(role.subtitle)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(role == .seller ? Color.primary : .white)
                    .fixedSize(horizontal: false, vertical: true)

                Text(punchline)
                    .font(.subheadline)
                    .foregroundStyle(role == .seller ? Color.secondary : .white.opacity(0.82))
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 8) {
                    ForEach(featurePills, id: \.self) { pill in
                        Text(pill)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(role == .seller ? StoreImmoTheme.navy : .white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(role == .seller ? Color.white.opacity(0.78) : .white.opacity(0.12), in: .capsule)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .trailing, spacing: 14) {
                Image(systemName: role.symbolName)
                    .font(.system(size: 50, weight: .regular))
                    .foregroundStyle(role == .seller ? StoreImmoTheme.navy : .white)
                    .frame(width: 88, height: 88)
                    .background(role == .seller ? Color.white.opacity(0.78) : .white.opacity(0.12), in: .circle)

                Image(systemName: "arrow.right")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(role == .seller ? StoreImmoTheme.navy : .white)
                    .frame(width: 46, height: 46)
                    .background(role == .seller ? Color.white.opacity(0.72) : .white.opacity(0.12), in: .circle)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            if role == .seller {
                LinearGradient(
                    colors: [Color.white, Color(red: 235 / 255, green: 244 / 255, blue: 252 / 255), Color(red: 217 / 255, green: 232 / 255, blue: 247 / 255)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            } else {
                StoreImmoTheme.heroGradient
            }
        }
        .overlay(alignment: .topTrailing) {
            if role == .seller {
                HStack(spacing: 10) {
                    Image(systemName: "building.2")
                    Image(systemName: "sun.max")
                }
                .font(.title2.weight(.regular))
                .foregroundStyle(StoreImmoTheme.navy.opacity(0.18))
                .padding(18)
                .allowsHitTesting(false)
            }
        }
        .clipShape(.rect(cornerRadius: 30))
        .overlay {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .strokeBorder(role == .seller ? .white.opacity(0.9) : .white.opacity(0.08), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.06), radius: 18, y: 8)
    }
}

private struct TrustSummaryView: View {
    var body: some View {
        HStack(spacing: 12) {
            CompactTrustBadgeView(symbolName: "person.text.rectangle", title: "Profils vérifiés")
            CompactTrustBadgeView(symbolName: "bubble.left.and.bubble.right", title: "Chat privé")
            CompactTrustBadgeView(symbolName: "calendar", title: "RDV centralisés")
        }
        .padding(14)
        .background(Color(.secondarySystemBackground), in: .rect(cornerRadius: 24))
    }
}

private struct CompactTrustBadgeView: View {
    let symbolName: String
    let title: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: symbolName)
                .font(.system(size: 32, weight: .regular))
                .foregroundStyle(StoreImmoTheme.navy)
                .frame(width: 52, height: 52)
                .background(Color(.systemBackground), in: .circle)

            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .padding(.horizontal, 8)
        .background(Color(.tertiarySystemBackground), in: .rect(cornerRadius: 18))
    }
}

private struct HeroBackgroundArtworkView: View {
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                LinearGradient(
                    colors: [Color.white.opacity(0.28), .clear, Color.black.opacity(0.25)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                VStack(spacing: 0) {
                    Spacer(minLength: 0)

                    HStack(alignment: .bottom, spacing: 14) {
                        Spacer(minLength: 0)

                        BuildingArtworkCardView(symbolName: "building.2", accentSymbol: "sun.max", width: proxy.size.width * 0.3, height: 168)

                        BuildingArtworkCardView(symbolName: "house", accentSymbol: "tree", width: proxy.size.width * 0.38, height: 224)

                        BuildingArtworkCardView(symbolName: "building.columns", accentSymbol: "sparkles", width: proxy.size.width * 0.24, height: 148)
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 34)
                }
            }
        }
    }
}

private struct BuildingArtworkCardView: View {
    let symbolName: String
    let accentSymbol: String
    let width: CGFloat
    let height: CGFloat

    var body: some View {
        RoundedRectangle(cornerRadius: 28, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [Color.white.opacity(0.4), Color.white.opacity(0.12), Color.black.opacity(0.18)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: width, height: height)
            .overlay(alignment: .topTrailing) {
                Image(systemName: accentSymbol)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white.opacity(0.95))
                    .padding(12)
            }
            .overlay {
                VStack(spacing: 10) {
                    Spacer(minLength: 0)
                    Image(systemName: symbolName)
                        .font(.system(size: min(width, height) * 0.32, weight: .regular))
                        .foregroundStyle(.white.opacity(0.96))
                    Spacer(minLength: 0)
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .strokeBorder(.white.opacity(0.16), lineWidth: 1)
            }
    }
}

private struct AuthenticationFlowView: View {
    let role: UserRole
    @Environment(AppViewModel.self) private var viewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(role == .seller ? "Bienvenue côté vendeur" : "Espace agent vérifié")
                            .font(.largeTitle.bold())
                        Text(role == .seller ? "Créez votre compte et publiez votre projet sans friction." : "Renseignez vos justificatifs puis accédez aux projets correspondant à vos zones.")
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }

                    VStack(spacing: 12) {
                        Button { viewModel.completeAuthentication() } label: { LoginButtonView(title: "Continuer avec Email", symbolName: "envelope.fill") }
                        Button { viewModel.completeAuthentication() } label: { LoginButtonView(title: "Continuer avec Téléphone", symbolName: "phone.fill") }
                        Button { viewModel.completeAuthentication() } label: { LoginButtonView(title: "Continuer avec Google", symbolName: "globe") }
                        Button { viewModel.completeAuthentication() } label: { LoginButtonView(title: "Continuer avec Apple", symbolName: "apple.logo") }
                    }
                    .buttonStyle(.plain)

                    if role == .agent {
                        AgentVerificationFormView()
                    } else {
                        SellerFastPostPreviewView()
                    }

                    Button(role == .agent ? "Continuer vers l’onboarding agent" : "Entrer dans l’application") {
                        viewModel.completeAuthentication()
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
                    .controlSize(.large)

                    Button("Retour") {
                        viewModel.selectedRole = nil
                    }
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity)
                }
                .padding(20)
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

private struct LoginButtonView: View {
    let title: String
    let symbolName: String

    var body: some View {
        HStack {
            Image(systemName: symbolName)
                .font(.headline)
            Text(title)
                .font(.headline)
            Spacer()
        }
        .padding(16)
        .background(Color(.secondarySystemBackground), in: .rect(cornerRadius: 20))
    }
}

private struct SellerFastPostPreviewView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Parcours vendeur")
                .font(.headline)
            Text("Adresse, type de bien, photos, prix souhaité, date idéale. Le flow est prêt pour une saisie très rapide.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .storeImmoCardStyle()
    }
}

private struct AgentVerificationFormView: View {
    @State private var selectedVerification: Int = 0
    @State private var cardNumber: String = "CPI 7501 2025 000 112 450"
    @State private var networkName: String = "Century 21"

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Vérification professionnelle")
                .font(.title3.bold())

            Picker("Type", selection: $selectedVerification) {
                Text("Carte pro").tag(0)
                Text("Mandataire").tag(1)
            }
            .pickerStyle(.segmented)

            VStack(alignment: .leading, spacing: 10) {
                TextField(selectedVerification == 0 ? "Numéro de carte professionnelle" : "Numéro de carte mandataire", text: $cardNumber)
                    .textFieldStyle(.roundedBorder)
                if selectedVerification == 1 {
                    TextField("Réseau", text: $networkName)
                        .textFieldStyle(.roundedBorder)
                }
                HStack(spacing: 10) {
                    Image(systemName: "paperclip")
                    Text("Upload de la preuve prêt à intégrer avec Supabase Storage")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .storeImmoCardStyle()
    }
}

private struct AgentProfileOnboardingView: View {
    @Environment(AppViewModel.self) private var viewModel

    var body: some View {
        @Bindable var viewModel = viewModel
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    DashboardTopCardView(title: "Créez votre profil agent", subtitle: "Étape obligatoire avant d’accéder aux biens, candidatures et mandats.")
                    VStack(spacing: 12) {
                        HStack(spacing: 14) {
                            Image(systemName: viewModel.agentOnboardingDraft.photoSymbol)
                                .font(.system(size: 48, weight: .regular))
                                .foregroundStyle(StoreImmoTheme.navy)
                                .frame(width: 72, height: 72)
                                .background(Color(.secondarySystemBackground), in: .circle)
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Photo de profil")
                                    .font(.headline)
                                Text("Avatar de démonstration, prêt pour Supabase Storage.")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }

                        HStack(spacing: 12) {
                            TextField("Prénom", text: $viewModel.agentOnboardingDraft.firstName).textFieldStyle(.roundedBorder)
                            TextField("Nom", text: $viewModel.agentOnboardingDraft.lastName).textFieldStyle(.roundedBorder)
                        }
                        TextField("Email", text: $viewModel.agentOnboardingDraft.email)
                            .textFieldStyle(.roundedBorder)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.emailAddress)
                        TextField("Ville", text: $viewModel.agentOnboardingDraft.city).textFieldStyle(.roundedBorder)
                        TextField("Agence (optionnel)", text: $viewModel.agentOnboardingDraft.agency).textFieldStyle(.roundedBorder)
                        TextField("Numéro de téléphone", text: $viewModel.agentOnboardingDraft.phoneNumber).textFieldStyle(.roundedBorder).keyboardType(.phonePad)
                        TextField("Description professionnelle (optionnelle)", text: $viewModel.agentOnboardingDraft.professionalDescription, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                            .lineLimit(5, reservesSpace: true)
                    }
                    .storeImmoCardStyle()
                    if let message = viewModel.appStatusMessage {
                        Text(message).font(.footnote.weight(.semibold)).foregroundStyle(StoreImmoTheme.navy).storeImmoCardStyle()
                    }
                    Button {
                        viewModel.saveAgentProfileOnboarding()
                    } label: {
                        Label("Enregistrer et choisir mon abonnement", systemImage: "arrow.right.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(!viewModel.agentOnboardingDraft.isComplete)
                    NavigationLink {
                        LoginExistingAccountView(role: .agent)
                    } label: {
                        Text("Déjà inscrit ? Se connecter")
                            .font(.footnote.weight(.semibold))
                            .frame(maxWidth: .infinity)
                    }
                    Button("Se déconnecter", role: .destructive) { viewModel.signOut() }.buttonStyle(.bordered)
                }
                .padding(20)
            }
            .navigationTitle("Onboarding agent")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

private struct AgentSubscriptionOnboardingView: View {
    var body: some View {
        SubscriptionPlansView(showsCloseButton: false)
    }
}

private struct SellerOnboardingView: View {
    @Environment(AppViewModel.self) private var viewModel

    var body: some View {
        @Bindable var viewModel = viewModel
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    DashboardTopCardView(title: "Votre profil vendeur", subtitle: "Quelques informations privées pour sécuriser vos échanges. Votre nom complet ne sera jamais affiché publiquement.")

                    VStack(spacing: 12) {
                        HStack(spacing: 12) {
                            TextField("Prénom", text: $viewModel.sellerOnboardingDraft.firstName)
                                .textFieldStyle(.roundedBorder)
                            TextField("Nom", text: $viewModel.sellerOnboardingDraft.lastName)
                                .textFieldStyle(.roundedBorder)
                        }
                        TextField("Email", text: $viewModel.sellerOnboardingDraft.email)
                            .textFieldStyle(.roundedBorder)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.emailAddress)
                        TextField("Numéro de téléphone", text: $viewModel.sellerOnboardingDraft.phoneNumber)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.phonePad)
                    }
                    .storeImmoCardStyle()

                    Label("Public : seul votre prénom sera visible par les agents.", systemImage: "lock.shield.fill")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(StoreImmoTheme.navy)
                        .storeImmoCardStyle()

                    if let message = viewModel.appStatusMessage {
                        Text(message).font(.footnote.weight(.semibold)).foregroundStyle(StoreImmoTheme.navy).storeImmoCardStyle()
                    }

                    Button {
                        viewModel.saveSellerOnboarding()
                    } label: {
                        Label("Enregistrer et continuer", systemImage: "arrow.right.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(!viewModel.sellerOnboardingDraft.isComplete)
                    NavigationLink {
                        LoginExistingAccountView(role: .seller)
                    } label: {
                        Text("Déjà inscrit ? Se connecter")
                            .font(.footnote.weight(.semibold))
                            .frame(maxWidth: .infinity)
                    }
                    Button("Se déconnecter", role: .destructive) { viewModel.signOut() }.buttonStyle(.bordered)
                }
                .padding(20)
            }
            .navigationTitle("Onboarding vendeur")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

private struct LoginExistingAccountView: View {
    let role: UserRole

    @Environment(AppViewModel.self) private var viewModel
    @Environment(\.dismiss) private var dismiss

    @State private var email: String = ""
    @State private var phone: String = ""

    private var canLogin: Bool {
        email.trimmingCharacters(in: .whitespacesAndNewlines).isValidEmail &&
        !phone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                DashboardTopCardView(
                    title: role == .seller ? "Connexion vendeur" : "Connexion agent",
                    subtitle: "Connectez-vous avec l’email et le téléphone utilisés lors de votre inscription."
                )

                VStack(spacing: 12) {
                    TextField("Email", text: $email)
                        .textFieldStyle(.roundedBorder)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)

                    TextField("Numéro de téléphone", text: $phone)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.phonePad)
                }
                .storeImmoCardStyle()

                if let message = viewModel.appStatusMessage {
                    Text(message)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(StoreImmoTheme.navy)
                        .storeImmoCardStyle()
                }

                Button {
                    viewModel.loginExistingAccount(
                        role: role,
                        email: email,
                        phone: phone
                    )
                    dismiss()
                } label: {
                    Label("Se connecter", systemImage: "arrow.right.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(!canLogin)

                Button("Pas encore inscrit ? Créer un compte") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity)
            }
            .padding(20)
        }
        .navigationTitle("Connexion")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct SellerRootView: View {
    @Environment(AppViewModel.self) private var viewModel

    var body: some View {
        TabView(selection: Binding(get: { viewModel.sellerTab }, set: { viewModel.sellerTab = $0 })) {
            Tab("Accueil", systemImage: "house", value: .dashboard) {
                NavigationStack {
                    SellerDashboardView()
                }
            }
            Tab("Suivi", systemImage: "checkmark.seal", value: .mandates) {
                NavigationStack {
                    SellerFollowUpView()
                }
            }
            Tab("Messages", systemImage: "bubble.left.and.bubble.right", value: .messages) {
                NavigationStack {
                    MessagingHubView()
                }
            }
            Tab("Profil", systemImage: "person.crop.circle", value: .profile) {
                NavigationStack {
                    ProfileSettingsView(isAgent: false)
                }
            }
        }
    }
}

private struct AgentRootView: View {
    @Environment(AppViewModel.self) private var viewModel

    var body: some View {
        TabView(selection: Binding(get: { viewModel.agentTab }, set: { viewModel.agentTab = $0 })) {
            Tab("Découvrir", systemImage: "sparkles.rectangle.stack", value: .discover) {
                NavigationStack {
                    AgentDiscoverFeedView()
                }
            }
            Tab("Projets", systemImage: "building.2", value: .opportunities) {
                NavigationStack {
                    AgentDashboardView()
                }
            }
            Tab("Messages", systemImage: "bubble.left.and.exclamationmark.bubble.right", value: .messages) {
                NavigationStack {
                    MessagingHubView()
                }
            }
            Tab("Profil", systemImage: "person.badge.shield.checkmark", value: .profile) {
                NavigationStack {
                    ProfileSettingsView(isAgent: true)
                }
            }
        }
    }
}

private struct SellerDashboardView: View {
    @Environment(AppViewModel.self) private var viewModel
    @State private var isComposerPresented: Bool = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                DashboardTopCardView(title: "Bonjour \(viewModel.sellerPublicFirstName)", subtitle: "Vos projets actifs et les meilleures candidatures du moment.")

                Button {
                    isComposerPresented = true
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Déposer un projet de vente")
                            .fontWeight(.semibold)
                        Spacer()
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                VStack(alignment: .leading, spacing: 12) {
                    Text("Mes projets")
                        .font(.title3.bold())
                    ForEach(viewModel.sellerProjects) { project in
                        NavigationLink(value: project.id) {
                            ProjectSummaryCardView(project: project)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(20)
        }
        .navigationTitle("Vendeur")
        .navigationDestination(for: UUID.self) { projectID in
            if let project = viewModel.sellerProjects.first(where: { $0.id == projectID }) {
                SellerProjectDetailView(project: project)
            }
        }
        .sheet(isPresented: $isComposerPresented) {
            SellerProjectComposerView()
                .presentationDetents([.large])
                .presentationContentInteraction(.scrolls)
        }
    }
}

private struct AgentDashboardView: View {
    @Environment(AppViewModel.self) private var viewModel

    private var chosenProjects: [PropertyProject] {
        let allProjects = viewModel.discoverFeedProjects + viewModel.sellerProjects

        return allProjects.filter { project in
            project.applications.contains { application in
                application.status.lowercased() == "chosen"
            } || project.status == .agentChosen
        }
    }

    private var appliedProjects: [PropertyProject] {
        viewModel.discoverFeedProjects.filter { project in
            viewModel.hasApplied(to: project) &&
            !chosenProjects.contains(where: { $0.id == project.id })
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Text("Mes projets")
                    .font(.largeTitle.bold())

                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Mes candidatures")
                            .font(.title3.bold())
                        Spacer()
                        Text("\(appliedProjects.count)")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }

                    if appliedProjects.isEmpty {
                        ContentUnavailableView(
                            "Aucune candidature envoyée",
                            systemImage: "paperplane",
                            description: Text("Les projets sur lesquels vous candidatez apparaîtront ici.")
                        )
                    } else {
                        ForEach(appliedProjects) { project in
                            NavigationLink(value: project.id) {
                                ProjectOpportunityCardView(project: project, showsAction: false, isImmersive: false)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Sélectionné par un vendeur")
                            .font(.title3.bold())
                        Spacer()
                        Text("\(chosenProjects.count)")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }

                    if chosenProjects.isEmpty {
                        ContentUnavailableView(
                            "Aucune sélection pour le moment",
                            systemImage: "checkmark.seal",
                            description: Text("Les projets où un vendeur vous sélectionne apparaîtront ici.")
                        )
                    } else {
                        ForEach(chosenProjects) { project in
                            NavigationLink(value: project.id) {
                                ProjectOpportunityCardView(project: project, showsAction: false, isImmersive: false)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(20)
        }
        .navigationTitle("Projets")
        .navigationDestination(for: UUID.self) { projectID in
            if let project = viewModel.discoverFeedProjects.first(where: { $0.id == projectID }) ?? viewModel.sellerProjects.first(where: { $0.id == projectID }) {
                AgentProjectDetailView(project: project)
            }
        }
    }
}

private struct AgentDiscoverFeedView: View {
    @Environment(AppViewModel.self) private var viewModel
    @Environment(StoreImmoNotificationService.self) private var notificationService
    @State private var selectedProject: PropertyProject?
    @State private var galleryProject: PropertyProject?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                DiscoverFeedHeroView()

                LazyVStack(spacing: 18, pinnedViews: [.sectionHeaders]) {
                    Section {
                        ForEach(viewModel.discoverFeedProjects) { project in
                            DiscoverPropertyCardView(project: project, onOpen: {
                                selectedProject = project
                            }, onApply: {
                                selectedProject = project
                            }, onGallery: {
                                galleryProject = project
                            })
                            .onAppear {
                                viewModel.loadMoreDiscoverProjectsIfNeeded(currentProject: project)
                            }
                        }

                        if viewModel.isDiscoverFeedRefreshing {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 20)
                        }
                    } header: {
                        DiscoverFeedStickyFiltersView()
                            .padding(.bottom, 14)
                            .background(Color(.systemBackground))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
        .navigationTitle("Découvrir")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            await notificationService.requestAuthorizationIfNeeded()
            let newProject = viewModel.refreshDiscoverFeed()
            if let newProject {
                await notificationService.scheduleSectorAlert(for: newProject)
            }
        }
        .sheet(item: $selectedProject) { project in
            AgentProjectDetailSheetView(project: project)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .presentationContentInteraction(.scrolls)
        }
        .fullScreenCover(item: $galleryProject) { project in
            PropertyGalleryFullScreenView(project: project)
        }
    }
}

private struct DiscoverFeedHeroView: View {
    @Environment(AppViewModel.self) private var viewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 10) {

                        Text("Votre feed")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundStyle(.white)

                        Text(viewModel.agentSectorSummary)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)

                        Text("Recevez les projets vendeurs disponibles dans votre secteur et candidatez directement !")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.86))
                    }
                }

            HStack(spacing: 12) {
                Label("Nouveaux biens en direct", systemImage: "bell.badge.fill")
                    .font(.footnote.weight(.semibold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.white.opacity(0.14), in: .capsule)
                Label("Galerie plein écran", systemImage: "rectangle.on.rectangle")
                    .font(.footnote.weight(.semibold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.white.opacity(0.14), in: .capsule)
            }

            HStack(spacing: 12) {
                ProjectMetricBadgeView(value: viewModel.discoverFeedProjects.count, label: "Biens visibles")
                ProjectMetricBadgeView(value: viewModel.savedDiscoverProjects.count, label: "Biens sauvegardés")
                ProjectMetricBadgeView(value: Int(viewModel.radiusFilter), label: "Rayon km")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(22)
        .background(StoreImmoTheme.heroGradient, in: .rect(cornerRadius: 30))
    }
}

private struct AgentSectorOverviewCardView: View {
    @Environment(AppViewModel.self) private var viewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Votre secteur actif")
                    .font(.headline)
                Spacer()
                StatusBadgeView(text: viewModel.agentSectorSummary)
            }

            Text("Le feed Découvrir n’affiche que les biens de votre périmètre. Changez votre ville ou votre rayon depuis le profil pour basculer vers une autre zone.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                ProjectMetricBadgeView(value: viewModel.discoverFeedProjects.count, label: "Biens visibles")
                ProjectMetricBadgeView(value: Int(viewModel.radiusFilter), label: "Rayon km")
                ProjectMetricBadgeView(value: viewModel.savedDiscoverProjects.count, label: "Sauvegardés")
            }
        }
        .storeImmoCardStyle()
    }
}

private struct DiscoverFeedStickyFiltersView: View {
    @Environment(AppViewModel.self) private var viewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 10) {
                Label("Rayon du feed", systemImage: "location.magnifyingglass")
                    .font(.footnote.weight(.semibold))
                    .lineLimit(1)
                Spacer(minLength: 8)
                Text("\(Int(viewModel.radiusFilter)) km")
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(StoreImmoTheme.navy)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color(.secondarySystemBackground), in: .capsule)
            }

            Slider(
                value: Binding(
                    get: {
                        Double(viewModel.discoverRadiusOptions.firstIndex(of: Int(viewModel.radiusFilter)) ?? 3)
                    },
                    set: { newValue in
                        let index = min(max(Int(newValue.rounded()), 0), viewModel.discoverRadiusOptions.count - 1)
                        viewModel.updateRadiusFilter(to: viewModel.discoverRadiusOptions[index])
                    }
                ),
                in: 0...Double(viewModel.discoverRadiusOptions.count - 1),
                step: 1
            )
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.regularMaterial, in: .rect(cornerRadius: 18))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
        }
    }
}

private struct RadiusFilterSettingsBlock: View {
    @Environment(AppViewModel.self) private var viewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Rayon d’intervention")
            DiscoverFeedStickyFiltersView()
                .padding(.vertical, 4)
        }
    }
}

private struct DiscoverPropertyGalleryPreview: View {
    let project: PropertyProject
    let onGallery: () -> Void
    @State private var selectedPhotoID: UUID?

    var body: some View {
        TabView(selection: Binding(get: {
            selectedPhotoID ?? project.photos.first?.id ?? UUID()
        }, set: { newValue in
            selectedPhotoID = newValue
        })) {
            ForEach(project.photos) { photo in
                Button {
                    onGallery()
                } label: {
                    PropertyGallerySlideView(
                        photo: photo,
                        title: project.title,
                        subtitle: project.fullAddress,
                        priceText: project.formattedPrice,
                        height: 430
                    )
                }
                .buttonStyle(.plain)
                .tag(photo.id)
            }
        }
        .frame(height: 430)
        .tabViewStyle(.page(indexDisplayMode: .automatic))
        .indexViewStyle(.page(backgroundDisplayMode: .interactive))
        .clipShape(.rect(cornerRadius: 28))
    }
}

private struct PropertyGallerySlideView: View {
    let photo: PhotoAsset
    let title: String
    let subtitle: String
    let priceText: String
    let height: CGFloat

    var body: some View {
        ZStack {
            if let urlString = photo.url, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    if case .success(let image) = phase {
                        image
                            .resizable()
                            .scaledToFill()
                    } else {
                        symbolBackground
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                symbolBackground
            }
        }
        .frame(height: height)
        .overlay {
            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0.2),
                    .init(color: .black.opacity(0.15), location: 0.48),
                    .init(color: .black.opacity(0.82), location: 1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .allowsHitTesting(false)
        }
        .overlay(alignment: .topLeading) {
            HStack {
                StatusBadgeView(text: photo.label)
                Spacer()
                Image(systemName: photo.accentName)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(10)
                    .background(.black.opacity(0.24), in: .circle)
            }
            .padding(16)
        }
        .overlay(alignment: .bottomLeading) {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.88))
                Text(priceText)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)
            }
            .padding(18)
        }
    }

    @ViewBuilder private var symbolBackground: some View {
        Color(StoreImmoTheme.navy)
            .overlay {
                LinearGradient(
                    colors: [StoreImmoTheme.slate, StoreImmoTheme.navy.opacity(0.95), .black],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .allowsHitTesting(false)
                .overlay {
                    VStack(spacing: 18) {
                        Spacer()
                        Image(systemName: photo.systemName)
                            .font(.system(size: 108, weight: .regular))
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.white.opacity(0.96))
                        Text(photo.label)
                            .font(.headline)
                            .foregroundStyle(.white.opacity(0.9))
                        Spacer()
                    }
                    .allowsHitTesting(false)
                }
            }
    }
}

private struct PropertyGalleryFullScreenView: View {
    let project: PropertyProject
    @Environment(AppViewModel.self) private var viewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPhotoID: UUID?

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                Color.black.ignoresSafeArea()

                TabView(selection: Binding(get: {
                    selectedPhotoID ?? project.photos.first?.id ?? UUID()
                }, set: { newValue in
                    selectedPhotoID = newValue
                })) {
                    ForEach(project.photos) { photo in
                        PropertyGallerySlideView(
                            photo: photo,
                            title: project.title,
                            subtitle: project.fullAddress,
                            priceText: project.formattedPrice,
                            height: 520
                        )
                        .tag(photo.id)
                        .clipShape(.rect(cornerRadius: 0))
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .automatic))
                .indexViewStyle(.page(backgroundDisplayMode: .always))

                VStack(spacing: 14) {
                    HStack {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.headline)
                                .foregroundStyle(.white)
                                .frame(width: 42, height: 42)
                                .background(.black.opacity(0.3), in: .circle)
                        }

                        Spacer()

                        Button {
                            viewModel.toggleSavedProject(project)
                        } label: {
                            Image(systemName: viewModel.isProjectSaved(project) ? "heart.fill" : "heart")
                                .font(.headline)
                                .foregroundStyle(viewModel.isProjectSaved(project) ? .red : .white)
                                .frame(width: 42, height: 42)
                                .background(.black.opacity(0.3), in: .circle)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                    Spacer()

                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text(project.propertyType.rawValue)
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 7)
                                .background(.white.opacity(0.14), in: .capsule)
                            Spacer()
                            Text("\(project.photos.count) vues")
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(.white.opacity(0.88))
                        }

                        Text(project.feedHighlight)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.white)

                        Text("Swipez pour parcourir toute la galerie puis revenez au feed pour candidater.")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.78))
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.black.opacity(0.34))
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }
}

private struct DashboardTopCardView: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.largeTitle.bold())
                .foregroundStyle(.white)
            Text(subtitle)
                .font(.body)
                .foregroundStyle(.white.opacity(0.85))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(22)
        .background(StoreImmoTheme.heroGradient, in: .rect(cornerRadius: 30))
    }
}

private struct ProjectSummaryCardView: View {
    let project: PropertyProject

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            PropertyHeroImageView(photo: project.photos.first, height: 230) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        StatusBadgeView(text: project.status.accentLabel)

                        Spacer()

                        Text(project.propertyType.rawValue)
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(.black.opacity(0.22), in: .capsule)
                    }

                    Spacer()

                    VStack(alignment: .leading, spacing: 4) {
                        Text(project.title)
                            .font(.title3.bold())
                            .foregroundStyle(.white)

                        Text(project.fullAddress)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.88))
                    }
                }
            }

            HStack(spacing: 12) {
                ProjectMetricBadgeView(
                    value: project.desiredPrice,
                    label: "Prix"
                )

                ProjectMetricBadgeView(
                    value: project.applications.count,
                    label: "Candidatures"
                )
            }
        }
        .storeImmoCardStyle()
    }
}
private struct ProjectFollowUpHeroCardView: View {
    let project: PropertyProject

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            PropertyHeroImageView(photo: project.photos.first, height: 230) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Color.clear
                            .frame(width: 1, height: 1)
                        Spacer()
                        Text(project.propertyType.rawValue)
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(.black.opacity(0.22), in: .capsule)
                    }

                    Spacer()

                    VStack(alignment: .leading, spacing: 4) {
                        Text(project.title)
                            .font(.title3.bold())
                            .foregroundStyle(.white)

                        Text(project.fullAddress)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.88))
                    }
                }
            }
        }
        .storeImmoCardStyle()
    }
}
private struct ProjectOpportunityCardView: View {
    let project: PropertyProject
    let showsAction: Bool
    let isImmersive: Bool

    init(project: PropertyProject, showsAction: Bool = true, isImmersive: Bool = true) {
        self.project = project
        self.showsAction = showsAction
        self.isImmersive = isImmersive
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            PropertyHeroImageView(photo: project.photos.first, height: isImmersive ? 300 : 220) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(alignment: .top) {
                        StatusBadgeView(text: project.districtLabel)
                        Spacer()
                        Text(project.feedHighlight)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(.black.opacity(0.24), in: .capsule)
                    }
                    Spacer()
                    VStack(alignment: .leading, spacing: 6) {
                        Text(project.title)
                            .font(isImmersive ? .title2.bold() : .headline)
                            .foregroundStyle(.white)
                        Text(project.fullAddress)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.88))
                        Text(project.formattedPrice)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.white)
                    }
                }
            }

            Text(project.description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(isImmersive ? 3 : 2)

            HStack(spacing: 12) {
                ProjectMetricBadgeView(value: project.desiredPrice, label: "Objectif")
                ProjectMetricBadgeView(value: project.applications.count, label: "Déjà reçues")
            }

            if showsAction {
                HStack(spacing: 10) {
                    Label(project.requiredRegion, systemImage: "location.fill")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("Mise en vente \(project.idealListingDate.formatted(date: .abbreviated, time: .omitted))")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .storeImmoCardStyle()
    }
}

private struct DiscoverPropertyCardView: View {
    let project: PropertyProject
    let onOpen: () -> Void
    let onApply: () -> Void
    let onGallery: () -> Void
    @Environment(AppViewModel.self) private var viewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            DiscoverPropertyGalleryPreview(project: project, onGallery: onGallery)
                .overlay(alignment: .topTrailing) {
                    VStack(spacing: 10) {
                        if viewModel.hasApplied(to: project) {
                            Text("Candidaté")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 9)
                                .background(.blue, in: .capsule)
                        } else {
                            Button {
                                viewModel.toggleSavedProject(project)
                            } label: {
                                Image(systemName: viewModel.isProjectSaved(project) ? "heart.fill" : "heart")
                                    .font(.headline)
                                    .foregroundStyle(viewModel.isProjectSaved(project) ? .red : .white)
                                    .frame(width: 42, height: 42)
                                    .background(.black.opacity(0.26), in: .circle)
                            }
                        }
                        
                        Image(systemName: "bell.badge.fill")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(width: 42, height: 42)
                            .background(.black.opacity(0.22), in: .circle)
                    }
                    .padding(16)
                }
                .overlay(alignment: .bottomTrailing) {
                    Button("Voir") {
                        onOpen()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .padding(16)
                }
            
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        StatusBadgeView(text: project.districtLabel)
                        Text(project.feedHighlight)
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    Text(project.description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                    Label(project.requiredRegion, systemImage: "location")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            
            HStack(spacing: 10) {
                Button {
                    onGallery()
                } label: {
                    HStack {
                        Image(systemName: "photo.on.rectangle")
                        Text("Galerie")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                
                if viewModel.hasApplied(to: project) {
                    
                    Button { } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)

                            VStack(spacing: -1) {
                                Text("Candidature")
                                Text("envoyée")
                            }
                            .font(.caption.weight(.semibold))
                            .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(true)
                    
                } else {
                    
                    Button {
                        onApply()
                    } label: {
                        HStack {
                            Image(systemName: "paperplane.fill")
                            Text("Candidater")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
            }
        }
        .storeImmoCardStyle()
    }
}

private struct PropertyHeroImageView<OverlayContent: View>: View {
    let photo: PhotoAsset?
    let height: CGFloat
    @ViewBuilder let overlayContent: OverlayContent

    var body: some View {
        ZStack {
            if let urlString = photo?.url, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    if case .success(let image) = phase {
                        image
                            .resizable()
                            .scaledToFill()
                    } else {
                        symbolBackground
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                symbolBackground
            }
        }
        .frame(height: height)
        .overlay {
            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0.18),
                    .init(color: .black.opacity(0.10), location: 0.52),
                    .init(color: .black.opacity(0.68), location: 1.0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .allowsHitTesting(false)
        }
        .clipShape(.rect(cornerRadius: 28))
        .overlay(alignment: .bottomLeading) {
            overlayContent
                .padding(18)
        }
    }

    @ViewBuilder private var symbolBackground: some View {
        Color(StoreImmoTheme.navy)
            .overlay {
                LinearGradient(
                    colors: [StoreImmoTheme.slate, StoreImmoTheme.navy.opacity(0.92), .black.opacity(0.94)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .allowsHitTesting(false)
                .overlay {
                    GeometryReader { proxy in
                        ZStack {
                            Circle()
                                .fill(.white.opacity(0.14))
                                .frame(width: proxy.size.width * 0.72)
                                .offset(x: proxy.size.width * 0.18, y: -proxy.size.height * 0.18)
                            Circle()
                                .fill(.white.opacity(0.08))
                                .frame(width: proxy.size.width * 0.92)
                                .offset(x: -proxy.size.width * 0.2, y: proxy.size.height * 0.28)
                            if let photo {
                                Image(systemName: photo.systemName)
                                    .font(.system(size: min(proxy.size.width, proxy.size.height) * 0.34, weight: .regular))
                                    .foregroundStyle(.white.opacity(0.94))
                                    .offset(x: proxy.size.width * 0.18, y: -10)
                                Image(systemName: photo.accentName)
                                    .font(.system(size: min(proxy.size.width, proxy.size.height) * 0.14, weight: .semibold))
                                    .symbolRenderingMode(.hierarchical)
                                    .foregroundStyle(.white.opacity(0.42))
                                    .offset(x: -proxy.size.width * 0.25, y: proxy.size.height * 0.18)
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .allowsHitTesting(false)
                }
            }
    }
}

private struct PropertyPhotoStripView: View {
    let photos: [PhotoAsset]
    let height: CGFloat

    init(photos: [PhotoAsset], height: CGFloat = 160) {
        self.photos = photos
        self.height = height
    }

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 12) {
                ForEach(photos) { photo in
                    VStack(alignment: .leading, spacing: 8) {
                        ZStack {
                            if let urlString = photo.url, let url = URL(string: urlString) {
                                AsyncImage(url: url) { phase in
                                    if case .success(let image) = phase {
                                        image
                                            .resizable()
                                            .scaledToFill()
                                    } else {
                                        photoStripSymbolCell(photo: photo, height: height)
                                    }
                                }
                                .frame(width: 220, height: height)
                            } else {
                                photoStripSymbolCell(photo: photo, height: height)
                            }
                        }
                        .frame(width: 220, height: height)
                        .clipShape(.rect(cornerRadius: 22))
                        .overlay(alignment: .topTrailing) {
                            Image(systemName: photo.accentName)
                                .font(.headline)
                                .foregroundStyle(.white.opacity(0.84))
                                .padding(10)
                        }
                    }
                }
            }
        }
        .contentMargins(.horizontal, 0)
        .scrollIndicators(.hidden)
    }

    @ViewBuilder private func photoStripSymbolCell(photo: PhotoAsset, height: CGFloat) -> some View {
        Color(StoreImmoTheme.navy)
            .overlay {
                LinearGradient(
                    colors: [StoreImmoTheme.slate, StoreImmoTheme.navy, .black.opacity(0.92)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .allowsHitTesting(false)
                .overlay {
                    VStack(spacing: 12) {
                        Image(systemName: photo.systemName)
                            .font(.system(size: 44))
                            .foregroundStyle(.white)
                        Text(photo.label)
                            .font(.headline)
                            .foregroundStyle(.white.opacity(0.92))
                    }
                    .allowsHitTesting(false)
                }
            }
    }
}

private struct StatusBadgeView: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(StoreImmoTheme.navy)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(.white.opacity(0.88), in: .capsule)
    }
}

private struct ProjectMetricBadgeView: View {
    let value: Int
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value.formatted(.number.grouping(.automatic)))
                .font(.headline)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(.tertiarySystemBackground), in: .rect(cornerRadius: 18))
    }
}

private struct SellerProjectDetailView: View {
    let project: PropertyProject

    var currentProject: PropertyProject {
        viewModel.sellerProjects.first { $0.id == project.id } ?? project
    }

    @Environment(AppViewModel.self) private var viewModel
    @State private var selectedAgent: AgentProfile?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                ProjectSummaryCardView(project: currentProject)

                PropertyPhotoStripView(photos: currentProject.photos, height: 210)

               
                VStack(alignment: .leading, spacing: 12) {

                    Text("Candidatures")
                        .font(.title3.bold())

                    let pendingApplications = currentProject.applications
                    

                    if pendingApplications.isEmpty {
                        ContentUnavailableView(
                            "Aucune autre candidature",
                            systemImage: "tray"
                        )
                    } else {
                        ForEach(pendingApplications) { application in
                            AgentApplicationCardView(
                                application: application,
                                onProfile: {
                                    selectedAgent = application.agent
                                },
                                onChoose: {
                                    print("🔥 BOUTON CLIQUE")
                                        viewModel.chooseAgent(application)
                                }
                            )
                        }
                    }
                }
            }
            .padding(20)
        }
        .navigationTitle(currentProject.title)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedAgent) { agent in
            AgentProfileSheetView(agent: agent)
                .presentationDetents([.medium, .large])
                .presentationContentInteraction(.scrolls)
        }
    }
}
        
struct AgentApplicationCardView: View {
    let application: AgentApplication
    let onProfile: () -> Void
    let onChoose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: application.agent.photoSymbol)
                    .font(.system(size: 32))
                    .foregroundStyle(StoreImmoTheme.navy)
                    .frame(width: 56, height: 56)
                    .background(StoreImmoTheme.mist, in: .circle)

                VStack(alignment: .leading, spacing: 6) {
                    Text(application.agent.fullName)
                        .font(.headline)
                    Text(application.agent.agencyName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    HStack(spacing: 8) {
                        Label(String(format: "%.1f", application.agent.averageRating), systemImage: "star.fill")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.yellow)
                        Text("\(application.agent.reviewCount) avis")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()
                StatusBadgeView(text: application.agent.badge.title)
            }

            Text(application.customMessage)
                .font(.subheadline)
                .foregroundStyle(.primary)

            HStack(spacing: 12) {
                ProjectMetricBadgeView(value: application.agent.salesLast12Months, label: "Ventes 12 mois")
                ProjectMetricBadgeView(value: application.agent.soldRate, label: "Bien vendu %")
            }

            HStack(spacing: 10) {
                Button("Voir profil complet") {
                    onProfile()
                }
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity)

                Button(application.status == "chosen" ? "Agent choisi" : "Choisir cet agent") {
                    if application.status != "chosen" {
                        onChoose()
                    }
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
                .disabled(application.status == "chosen")
            }
        }
        .storeImmoCardStyle()
    }
}

private struct ChatActivationCardView: View {
    let application: AgentApplication
    @Environment(AppViewModel.self) private var viewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Agent sélectionné")
                .font(.title3.bold())
            Text("Le chat privé est activé avec \(application.agent.fullName).")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button(viewModel.revealPhoneNumber ? viewModel.sellerPhoneNumber : "Révéler mon numéro de téléphone") {
                viewModel.revealPhone()
            }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity)
        }
        .storeImmoCardStyle()
    }
}

private struct AgentProfileSheetView: View {
    let agent: AgentProfile

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HStack(spacing: 16) {
                        Image(systemName: agent.photoSymbol)
                            .font(.system(size: 40))
                            .foregroundStyle(.white)
                            .frame(width: 78, height: 78)
                            .background(StoreImmoTheme.heroGradient, in: .circle)
                        VStack(alignment: .leading, spacing: 6) {
                            Text(agent.fullName)
                                .font(.title3.bold())
                            Text(agent.agencyName)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            StatusBadgeView(text: agent.badge.detail)
                        }
                    }

                    Text(agent.bio)
                        .font(.body)

                    HStack(spacing: 12) {
                        ProjectMetricBadgeView(value: agent.salesLast12Months, label: "Ventes")
                        ProjectMetricBadgeView(value: agent.averageDelayDays, label: "Délai moyen")
                        ProjectMetricBadgeView(value: agent.averageSalePrice, label: "Prix moyen")
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Zones d’intervention")
                            .font(.headline)
                        ForEach(agent.interventionZones) { zone in
                            Text("• \(zone.city) · \(zone.radiusKilometers) km")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Avis vérifiés")
                            .font(.headline)
                        ForEach(agent.reviews) { review in
                            VStack(alignment: .leading, spacing: 6) {
                                Text(review.author)
                                    .font(.subheadline.weight(.semibold))
                                Text(review.comment)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .storeImmoCardStyle()
                        }
                    }
                }
                .padding(20)
            }
            .navigationTitle("Profil agent")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

private struct SellerProjectComposerView: View {
    @Environment(AppViewModel.self) private var viewModel
    @Environment(\.dismiss) private var dismiss

    @State private var selectedPhoto: PhotosPickerItem?
    @State private var selectedPhotoData: Data?
    
    var body: some View {
        @Bindable var viewModel = viewModel

        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    TextField("Adresse complète", text: $viewModel.sellerLeadDraft.address)
                        .textFieldStyle(.roundedBorder)
                    HStack {
                        TextField("Ville", text: $viewModel.sellerLeadDraft.city)
                            .textFieldStyle(.roundedBorder)
                        TextField("Code postal", text: $viewModel.sellerLeadDraft.postalCode)
                            .textFieldStyle(.roundedBorder)
                    }

                    Picker("Type de bien", selection: $viewModel.sellerLeadDraft.propertyType) {
                        ForEach(PropertyType.allCases) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.menu)

                    TextField("Prix souhaité", text: $viewModel.sellerLeadDraft.desiredPrice)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.numberPad)

                    DatePicker("Date idéale", selection: $viewModel.sellerLeadDraft.idealListingDate, displayedComponents: .date)

                    TextField("Description", text: $viewModel.sellerLeadDraft.description, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(4, reservesSpace: true)

                    TextField("Informations complémentaires", text: $viewModel.sellerLeadDraft.extraInformation, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(3, reservesSpace: true)

                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        Label("Ajouter une photo", systemImage: "photo.badge.plus")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)

                    if let selectedPhotoData,
                       let uiImage = UIImage(data: selectedPhotoData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 220)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                    }
                .padding(20)
            }
            .navigationTitle("Nouveau projet")
            .navigationBarTitleDisplayMode(.inline)
            .task(id: selectedPhoto) {
                guard let selectedPhoto else { return }
                selectedPhotoData = try? await selectedPhoto.loadTransferable(type: Data.self)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Publier") {
                        viewModel.submitSellerLead(photoData: selectedPhotoData)
                        dismiss()
                    }
                }
            }
        }
    }
}

private struct SubscriptionBannerView: View {
    @Environment(AppViewModel.self) private var viewModel
    @State private var isPresented: Bool = false

    private var statusMessage: String {
        if !viewModel.isAgentSubscriptionActive {
            return "Aucun abonnement actif. Choisissez une offre pour candidater."
        }
        if viewModel.hasUnlimitedApplications {
            return "Votre accès Premium est actif. Candidatez sans limite."
        }
        return "Il vous reste \(viewModel.applicationsTodayRemaining) candidatures actives."
    }

    var body: some View {
        Button {
            isPresented = true
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.18))
                        .frame(width: 44, height: 44)
                    Image(systemName: viewModel.selectedPlan.iconName)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                }
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text("Abonnement \(viewModel.selectedPlan.title)")
                            .font(.headline)
                            .foregroundStyle(.white)
                        if viewModel.isAgentSubscriptionActive {
                            Text("Actif")
                                .font(.caption2.weight(.bold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(.white.opacity(0.22), in: .capsule)
                                .foregroundStyle(.white)
                        }
                    }
                    Text(statusMessage)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.9))
                        .lineLimit(2)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.8))
            }
            .padding(18)
            .background(viewModel.selectedPlan.bannerGradient, in: .rect(cornerRadius: 24))
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(.white.opacity(0.18), lineWidth: 1)
            }
            .shadow(color: viewModel.selectedPlan.accentColor.opacity(0.35), radius: 18, y: 10)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $isPresented) {
            SubscriptionPlansView()
                .presentationDetents([.large])
                .presentationContentInteraction(.scrolls)
        }
    }
}

private struct SubscriptionPlansView: View {
    let showsCloseButton: Bool
    @Environment(AppViewModel.self) private var viewModel
    @Environment(\.dismiss) private var dismiss

    init(showsCloseButton: Bool = true) {
        self.showsCloseButton = showsCloseButton
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Choisissez votre offre")
                            .font(.system(size: 30, weight: .bold))
                            .foregroundStyle(StoreImmoTheme.navy)
                        Text("L’abonnement est obligatoire pour activer votre compte agent et candidater sur les projets vendeurs.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 4)
                    .padding(.top, 8)

                    ForEach(SubscriptionPlan.allCases) { plan in
                        SubscriptionPlanCardView(
                            plan: plan,
                            isSelected: viewModel.selectedPlan == plan && viewModel.isAgentSubscriptionActive
                        ) {
                            viewModel.chooseSubscription(plan)
                            if showsCloseButton {
                                dismiss()
                            }
                        }
                    }

                    if !viewModel.isAgentSubscriptionActive {
                        HStack(spacing: 10) {
                            Image(systemName: "lock.fill")
                                .foregroundStyle(.orange)
                            Text("Les fonctionnalités agent sont bloquées tant qu’aucun abonnement n’est actif.")
                                .font(.footnote.weight(.medium))
                                .foregroundStyle(.secondary)
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.orange.opacity(0.1), in: .rect(cornerRadius: 16))
                    }

                    if let message = viewModel.appStatusMessage {
                        Text(message)
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(StoreImmoTheme.navy)
                            .padding(.horizontal, 4)
                    }

                    Text("Paiement sécurisé via Stripe. Annulation possible à tout moment.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 4)
                        .padding(.bottom, 12)
                }
                .padding(20)
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Abonnements")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if showsCloseButton {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Fermer") {
                            dismiss()
                        }
                    }
                }
            }
        }
    }
}

private struct SubscriptionPlanCardView: View {
    let plan: SubscriptionPlan
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.2))
                        .frame(width: 52, height: 52)
                    Image(systemName: plan.iconName)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(.white)
                }
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(plan.title)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(.white)
                        if plan.isHighlighted {
                            Text("Populaire")
                                .font(.caption2.weight(.bold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(.white.opacity(0.25), in: .capsule)
                                .foregroundStyle(.white)
                        }
                        if isSelected {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundStyle(.white)
                        }
                    }
                    Text(plan.tagline)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.88))
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }

            VStack(alignment: .leading, spacing: 12) {
                ForEach(plan.features, id: \.self) { feature in
                    HStack(alignment: .top, spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(.white.opacity(0.22))
                                .frame(width: 22, height: 22)
                            Image(systemName: "checkmark")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(.white)
                        }
                        Text(feature)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.white)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 0)
                    }
                }
            }

            Divider()
                .overlay(.white.opacity(0.25))

            HStack(alignment: .lastTextBaseline, spacing: 6) {
                Text(plan.priceText)
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(.white)
                Spacer()
                Button(action: action) {
                    Text(isSelected ? "Plan actuel" : plan.ctaTitle)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(plan.accentColor)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 12)
                        .background(.white, in: .capsule)
                }
                .buttonStyle(.plain)
                .disabled(isSelected)
                .opacity(isSelected ? 0.7 : 1)
            }
        }
        .padding(22)
        .background(plan.cardGradient, in: .rect(cornerRadius: 28))
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .strokeBorder(.white.opacity(isSelected ? 0.6 : 0.2), lineWidth: isSelected ? 2 : 1)
        }
        .overlay(alignment: .topTrailing) {
            // subtle shine
            Circle()
                .fill(.white.opacity(0.18))
                .frame(width: 140, height: 140)
                .blur(radius: 40)
                .offset(x: 40, y: -50)
                .allowsHitTesting(false)
        }
        .clipShape(.rect(cornerRadius: 28))
        .shadow(color: plan.accentColor.opacity(0.35), radius: 22, y: 14)
    }
}

private extension SubscriptionPlan {
    var accentColor: Color {
        switch self {
        case .starter:
            Color(red: 0.12, green: 0.55, blue: 0.50)
        case .pro:
            Color(red: 0.30, green: 0.30, blue: 0.85)
        case .elite:
            Color(red: 0.78, green: 0.50, blue: 0.16)
        }
    }

    var cardGradient: LinearGradient {
        switch self {
        case .starter:
            LinearGradient(
                colors: [
                    Color(red: 0.10, green: 0.62, blue: 0.55),
                    Color(red: 0.05, green: 0.42, blue: 0.45)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .pro:
            LinearGradient(
                colors: [
                    Color(red: 0.36, green: 0.34, blue: 0.92),
                    Color(red: 0.20, green: 0.18, blue: 0.65)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .elite:
            LinearGradient(
                colors: [
                    Color(red: 0.18, green: 0.14, blue: 0.22),
                    Color(red: 0.42, green: 0.30, blue: 0.18),
                    Color(red: 0.82, green: 0.62, blue: 0.28)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    var bannerGradient: LinearGradient {
        cardGradient
    }
}

private struct AgentProjectDetailView: View {
    let project: PropertyProject
    @State private var showApplicationSheet: Bool = false
    @Environment(AppViewModel.self) private var viewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                ProjectOpportunityCardView(project: project)

                VStack(alignment: .leading, spacing: 10) {
                    Text("Détails du bien")
                        .font(.title3.bold())
                    Text(project.fullAddress)
                        .font(.headline)
                    Text(project.description)
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                .storeImmoCardStyle()

                PropertyPhotoStripView(photos: project.photos, height: 220)

                if viewModel.hasApplied(to: project) {
                    Button("Candidature envoyée") { }
                        .buttonStyle(.borderedProminent)
                        .frame(maxWidth: .infinity)
                        .disabled(true)
                } else {
                    Button("Candidater à ce projet") {
                        showApplicationSheet = true
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(20)
        }
        .navigationTitle(project.title)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showApplicationSheet) {
            AgentApplicationComposerView(project: project)
                .presentationDetents([.medium, .large])
                .presentationContentInteraction(.scrolls)
        }
    }
}
private struct AgentProjectDetailSheetView: View {
    let project: PropertyProject

    var body: some View {
        NavigationStack {
            AgentProjectDetailView(project: project)
        }
    }
}

private struct AgentApplicationComposerView: View {
    let project: PropertyProject
    @Environment(AppViewModel.self) private var viewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        @Bindable var viewModel = viewModel

        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text(project.title)
                        .font(.title3.bold())
                    TextField("Commission proposée", text: $viewModel.agentApplicationDraft.commissionText)
                        .textFieldStyle(.roundedBorder)
                    TextField("Message personnalisé", text: $viewModel.agentApplicationDraft.message, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(5, reservesSpace: true)
                    Text("Une seule candidature par projet. Les limites anti-spam sont pilotées par votre plan.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding(20)
            }
            .navigationTitle("Votre candidature")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Envoyer") {
                        viewModel.submitAgentApplication(for: project)
                        dismiss()
                    }
                }
            }
        }
    }
}

private struct SellerFollowUpView: View {
    @Environment(AppViewModel.self) private var viewModel
    @State private var expandedProjectIDs: Set<UUID> = []
    
    private var selectedProjects: [PropertyProject] {
        viewModel.sellerProjects.filter {
            $0.status == .agentChosen || $0.selectedAgentID != nil
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                
                
                Text("Retrouvez ici les projets pour lesquels vous avez choisi un agent.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                if selectedProjects.isEmpty {
                    ContentUnavailableView(
                        "Aucun agent sélectionné",
                        systemImage: "checkmark.seal",
                        description: Text("Les biens pour lesquels vous choisissez un agent apparaîtront ici.")
                    )
                } else {
                    VStack(alignment: .leading, spacing: 14) {
                        ForEach(selectedProjects) { project in
                            SellerFollowUpCardView(
                                project: project,
                                isExpanded: expandedProjectIDs.contains(project.id),
                                onToggle: {
                                    if expandedProjectIDs.contains(project.id) {
                                        expandedProjectIDs.remove(project.id)
                                    } else {
                                        expandedProjectIDs.insert(project.id)
                                    }
                                },
                                onOpenConversation: {
                                    viewModel.sellerTab = .messages
                                }
                            )
                        }
                    }
                }
            }
        }
        .padding(20)
        .navigationTitle("Suivi")
        }
    }

private struct SellerFollowUpCardView: View {
    let project: PropertyProject
    let isExpanded: Bool
    let onToggle: () -> Void
    let onOpenConversation: () -> Void

    private var chosenApplication: AgentApplication? {
        project.applications.first { $0.status.lowercased() == "chosen" }
    }

    private var agent: AgentProfile? {
        chosenApplication?.agent
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Button {
                withAnimation(.smooth) {
                    onToggle()
                }
            } label: {
                VStack(alignment: .leading, spacing: 10) {
                    ProjectFollowUpHeroCardView(project: project)
                        .overlay(alignment: .topTrailing) {
                            Image(systemName: isExpanded ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                                .font(.title)
                                .foregroundStyle(.white)
                                .padding(16)
                        }

                    Text(isExpanded ? "Masquer les détails de l’agent" : "Afficher les détails de l’agent")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.plain)

            if isExpanded, let agent {
                Divider()

                VStack(alignment: .leading, spacing: 10) {
                    Text("Agent sélectionné")
                        .font(.headline)

                    Text(agent.fullName)
                        .font(.title3.bold())

                    Text("Agence : \(agent.agencyName)")
                        .font(.subheadline)

                    HStack(spacing: 8) {
                        Label(String(format: "%.1f", agent.averageRating), systemImage: "star.fill")
                            .foregroundStyle(.yellow)

                        Text("· \(agent.reviewCount) avis")
                            .foregroundStyle(.secondary)
                    }
                    .font(.subheadline.weight(.semibold))

                    if let chosenApplication {
                        Text("Commission : \(Int(chosenApplication.proposedCommission)) %")
                            .font(.subheadline)

                        Text("Message : “\(chosenApplication.customMessage)”")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Button {
                        onOpenConversation()
                    } label: {
                        Label("Ouvrir la conversation", systemImage: "bubble.left.and.bubble.right.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .storeImmoCardStyle()
    }
}

private struct AgentMandatesView: View {
    @Environment(AppViewModel.self) private var viewModel

    var body: some View {
        List(viewModel.agentMandates) { mandate in
            NavigationLink(value: mandate.id) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(mandate.propertyTitle)
                        .font(.headline)
                    Text(mandate.status)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Mes projets")
        .navigationDestination(for: UUID.self) { mandateID in
            if let mandate = viewModel.agentMandates.first(where: { $0.id == mandateID }) {
                MandateDetailView(mandate: mandate)
            }
        }
    }
}

private struct MandateDetailView: View {
    let mandate: Mandate

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(mandate.propertyTitle)
                        .font(.title2.bold())
                    Text(mandate.status)
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
                .storeImmoCardStyle()

                PropertyPhotoStripView(photos: mandate.photos, height: 210)

                VStack(alignment: .leading, spacing: 10) {
                    Text("Estimations")
                        .font(.headline)
                    Text(mandate.estimatedRange)
                        .font(.title3.bold())
                    Text(mandate.valuationNotice)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .storeImmoCardStyle()

                VStack(alignment: .leading, spacing: 10) {
                    Text("Mandat digital")
                        .font(.headline)
                    Label(mandate.digitalMandateName, systemImage: "doc.richtext")
                        .font(.subheadline)
                }
                .storeImmoCardStyle()

                VStack(alignment: .leading, spacing: 10) {
                    Text("Calendrier des RDV")
                        .font(.headline)
                    ForEach(mandate.appointments) { appointment in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(appointment.title)
                                .font(.headline)
                            Text(appointment.date.formatted(date: .abbreviated, time: .shortened))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text(appointment.note)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        .storeImmoCardStyle()
                    }
                }
            }
            .padding(20)
        }
        .navigationTitle("Mandat")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct MessagingHubView: View {
    @Environment(AppViewModel.self) private var viewModel
    
    private func displayTitle(for conversation: Conversation) -> String {
        if viewModel.selectedRole == .agent {
            return conversation.messages.first(where: {
                $0.senderRole == .seller && $0.senderName != "Store Immo"
            })?.senderName ?? "Vendeur"
        } else {
            return conversation.title
        }
    }
    
    var body: some View {
        List(viewModel.conversations) { conversation in
            NavigationLink(value: conversation.id) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                        .font(.title3)
                        .foregroundStyle(StoreImmoTheme.navy)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(displayTitle(for: conversation))
                            .font(.headline)
                        Text(conversation.projectTitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(
                            viewModel.selectedRole == .agent &&
                            conversation.lastMessagePreview.contains("agent")
                            ? "Commencez la discussion avec le vendeur."
                            : conversation.lastMessagePreview
                        )
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if conversation.unreadCount > 0 {
                        Text("\(conversation.unreadCount)")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white)
                            .padding(8)
                            .background(.blue, in: .circle)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Messages")
        .navigationDestination(for: UUID.self) { conversationID in
            if let conversation = viewModel.conversations.first(where: { $0.id == conversationID }) {
                ConversationDetailView(conversation: conversation)
            }
        }
    }
}

private struct ConversationDetailView: View {
    let conversation: Conversation
    @Environment(AppViewModel.self) private var viewModel
    @State private var draft: String = ""

    private var liveConversation: Conversation {
        viewModel.conversations.first(where: { $0.id == conversation.id }) ?? conversation
    }
    private var displayedTitle: String {
        if viewModel.selectedRole == .seller {
            return liveConversation.title
        } else {
            return sellerNameFromMessages
        }
    }

    private var sellerNameFromMessages: String {
        liveConversation.messages.first(where: { $0.senderRole == .seller })?.senderName ?? "Vendeur"
    }

    private var introText: String {
        viewModel.selectedRole == .agent
        ? "Commencez la discussion avec le vendeur."
        : "Commencez la discussion avec l'agent."
    }

    private var realMessages: [ChatMessage] {
        liveConversation.messages.filter {
            $0.senderName != "Store Immo" &&
            !$0.text.lowercased().contains("commencez la discussion")
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 12) {
                    if realMessages.isEmpty {
                        Text(introText)
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.secondary.opacity(0.7))
                            .frame(maxWidth: .infinity)
                            .padding(.top, 18)
                            .padding(.bottom, 8)
                    }
                    ForEach(realMessages) { message in
                        HStack {
                            if message.isFrom(role: viewModel.selectedRole) {
                                Spacer(minLength: 40)
                            }
                            Text(message.text)
                                .font(.body)
                                .foregroundStyle(message.isFrom(role: viewModel.selectedRole) ? .white : .primary)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                                .background(message.isFrom(role: viewModel.selectedRole) ? StoreImmoTheme.navy : Color(.secondarySystemBackground), in: .rect(cornerRadius: 18))
                            if !message.isFrom(role: viewModel.selectedRole) {
                                Spacer(minLength: 40)
                            }
                        }
                    }
                }
                .padding(20)
            }

            HStack(spacing: 12) {
                TextField("Votre message", text: $draft)
                    .textFieldStyle(.roundedBorder)
                Button("Envoyer") {
                    viewModel.selectConversation(conversation)
                    viewModel.sendCurrentMessage(draft)
                    draft = ""
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(16)
            .background(.bar)
        }
        .navigationTitle(displayedTitle)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct ProfileSettingsView: View {
    let isAgent: Bool
    @Environment(AppViewModel.self) private var viewModel

    private let cities: [String] = ["Paris", "Bordeaux", "Lyon", "Nîmes", "Ajaccio"]

    var body: some View {
        List {
            Section("Notifications") {
                Toggle("Push activées", isOn: Binding(get: { viewModel.isPushEnabled }, set: { viewModel.isPushEnabled = $0 }))
                if isAgent {
                    Picker("Secteur principal", selection: Binding(get: { viewModel.agentBaseCity }, set: { viewModel.updateAgentLocation(city: $0) })) {
                        ForEach(cities, id: \.self) { city in
                            Text(city).tag(city)
                        }
                    }
                    RadiusFilterSettingsBlock()
                }
            }

            Section(isAgent ? "Abonnement" : "Confiance") {
                if isAgent {
                    Label("Plan actuel : \(viewModel.selectedPlan.title)", systemImage: "crown.fill")
                    Label("Paiement externe Stripe prêt", systemImage: "creditcard")
                    Label("Flux feed local en direct", systemImage: "sparkles.rectangle.stack")
                    if let profile = viewModel.currentAgentProfile {
                        Label("Profil : \(profile.fullName)", systemImage: "person.crop.circle.badge.checkmark")
                    }
                } else {
                    Label("RGPD friendly", systemImage: "lock.shield")
                    Label("Avis vérifiés en fin de mandat", systemImage: "star.bubble")
                }
            }

            if isAgent {
                Section("Tables Supabase à créer") {
                    NavigationLink("Voir le schéma nécessaire") {
                        SupabaseRequirementsView()
                    }
                }
            }

            Section("Activité récente") {
                ForEach(viewModel.notifications.prefix(3)) { item in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.title)
                            .font(.headline)
                        Text(item.body)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section {
                Button("Se déconnecter", role: .destructive) {
                    viewModel.signOut()
                }
            }
        }
        .navigationTitle(isAgent ? "Profil agent" : "Mon profil")
        .listStyle(.insetGrouped)
    }
}

private struct SupabaseRequirementsView: View {
    @Environment(AppViewModel.self) private var viewModel

    var body: some View {
        List {
            Section {
                Text("Ces tables sont nécessaires pour remplacer les données de démonstration par une app production Supabase : Auth, Storage, Realtime, paiements Stripe et notifications.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            ForEach(viewModel.supabaseRequirements) { requirement in
                Section(requirement.name) {
                    Text(requirement.purpose)
                        .font(.subheadline)
                    ForEach(requirement.requiredColumns, id: \.self) { column in
                        Text(column)
                            .font(.caption.monospaced())
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Schéma Supabase")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private extension PropertyProject {
    var formattedPrice: String {
        desiredPrice.formatted(.currency(code: "EUR").presentation(.narrow))
    }
}

#Preview {
    ContentView()
        .environment(AppViewModel())
        .environment(StoreImmoReadinessService())
}
