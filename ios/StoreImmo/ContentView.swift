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
        .sheet(isPresented: Binding(
            get: { viewModel.pendingOTPEmail != nil },
            set: { if !$0 { viewModel.cancelOTP() } }
        )) {
            OTPVerificationView()
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
                        Button {
                            viewModel.completeAuthentication()
                        } label: {
                            LoginButtonView(title: "Créer un compte", symbolName: "person.badge.plus")
                        }
                        .buttonStyle(.plain)

                        NavigationLink {
                            LoginExistingAccountView(role: role)
                        } label: {
                            LoginButtonView(title: "Déjà inscrit ? Se connecter", symbolName: "arrow.right.circle")
                        }
                        .buttonStyle(.plain)
                    }

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
                    DashboardTopCardView(title: "Créez votre profil agent", subtitle: "Étape obligatoire avant d'accéder aux biens, candidatures et mandats.")
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
                                Text("Photo de profil (symbole)")
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
                    .disabled(!viewModel.agentOnboardingDraft.isComplete || viewModel.isCheckingAccount)
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
                    .disabled(!viewModel.sellerOnboardingDraft.isComplete || viewModel.isCheckingAccount)
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
                    subtitle: "Connectez-vous avec l'email et le téléphone utilisés lors de votre inscription."
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
                } label: {
                    Label("Se connecter", systemImage: "arrow.right.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(!canLogin || viewModel.isCheckingAccount)

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
        .onChange(of: viewModel.isAuthenticated) { _, isAuth in
            if isAuth { dismiss() }
        }
    }
}

private struct SellerRootView: View {
    @Environment(AppViewModel.self) private var viewModel

    var body: some View {
        @Bindable var viewModel = viewModel
        ZStack(alignment: .top) {
            TabView(selection: $viewModel.sellerTab) {
                Tab("Accueil", systemImage: "house", value: .dashboard) {
                    NavigationStack {
                        SellerDashboardView()
                    }
                }
                .badge(viewModel.unreadApplicationCount > 0 ? viewModel.unreadApplicationCount : 0)
                Tab("Suivi", systemImage: "checkmark.seal", value: .mandates) {
                    NavigationStack {
                        SellerFollowUpView()
                    }
                }
                Tab("Messages", systemImage: "bubble.left.and.bubble.right", value: .messages) {
                    NavigationStack(path: $viewModel.sellerMessagesNavPath) {
                        MessagingHubView()
                    }
                }
                .badge(viewModel.unreadConversationCount > 0 ? viewModel.unreadConversationCount : 0)
                Tab("Profil", systemImage: "person.crop.circle", value: .profile) {
                    NavigationStack {
                        ProfileSettingsView(isAgent: false)
                    }
                }
                .badge(viewModel.unreadNotificationCount > 0 ? viewModel.unreadNotificationCount : 0)
            }
            if let banner = viewModel.inAppBanner {
                InAppNotificationBannerView(notification: banner) {
                    viewModel.openFromNotification(banner)
                    viewModel.inAppBanner = nil
                } onDismiss: {
                    withAnimation(.easeOut(duration: 0.3)) {
                        viewModel.inAppBanner = nil
                    }
                }
                .transition(.asymmetric(insertion: .move(edge: .top).combined(with: .opacity),
                                        removal: .move(edge: .top).combined(with: .opacity)))
                .zIndex(10)
                .padding(.top, 8)
                .sensoryFeedback(.impact, trigger: banner.id)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.75), value: viewModel.inAppBanner?.id)
    }
}

private struct InAppNotificationBannerView: View {
    let notification: NotificationItem
    let onTap: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: notification.symbolName)
                .font(.title2)
                .foregroundStyle(StoreImmoTheme.navy)

            VStack(alignment: .leading, spacing: 2) {
                Text(notification.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                Text(notification.body)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.12), radius: 12, y: 4)
        .padding(.horizontal, 16)
        .contentShape(Rectangle())
        .onTapGesture { onTap() }
        .gesture(
            DragGesture(minimumDistance: 20)
                .onEnded { value in
                    if value.translation.height < -20 {
                        withAnimation(.easeOut(duration: 0.3)) { onDismiss() }
                    }
                }
        )
    }
}

private struct AgentRootView: View {
    @Environment(AppViewModel.self) private var viewModel

    var body: some View {
        @Bindable var viewModel = viewModel
        ZStack(alignment: .top) {
            TabView(selection: $viewModel.agentTab) {
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
                    NavigationStack(path: $viewModel.agentMessagesNavPath) {
                        MessagingHubView()
                    }
                }
                .badge(viewModel.unreadConversationCount > 0 ? viewModel.unreadConversationCount : 0)
                Tab("Profil", systemImage: "person.badge.shield.checkmark", value: .profile) {
                    NavigationStack {
                        ProfileSettingsView(isAgent: true)
                    }
                }
                .badge(viewModel.unreadNotificationCount > 0 ? viewModel.unreadNotificationCount : 0)
            }
            if let banner = viewModel.inAppBanner {
                InAppNotificationBannerView(notification: banner) {
                    viewModel.openFromNotification(banner)
                    viewModel.inAppBanner = nil
                } onDismiss: {
                    withAnimation(.easeOut(duration: 0.3)) {
                        viewModel.inAppBanner = nil
                    }
                }
                .transition(.asymmetric(insertion: .move(edge: .top).combined(with: .opacity),
                                        removal: .move(edge: .top).combined(with: .opacity)))
                .zIndex(10)
                .padding(.top, 8)
                .sensoryFeedback(.impact, trigger: banner.id)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.75), value: viewModel.inAppBanner?.id)
    }
}

private struct SellerDashboardView: View {
    @Environment(AppViewModel.self) private var viewModel

    var body: some View {
        @Bindable var viewModel = viewModel
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                DashboardTopCardView(title: "Bonjour \(viewModel.sellerPublicFirstName)", subtitle: "Comparez les profils, choisissez votre expert, vendez sereinement.")

                Button {
                    viewModel.showSellerComposerSheet = true
                } label: {
                    Label("Déposer un projet de vente", systemImage: "plus.circle.fill")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                VStack(alignment: .leading, spacing: 12) {
                    Text("Mes projets")
                        .font(.title3.bold())
                    ForEach(viewModel.sortedSellerProjects) { project in
                        VStack(spacing: 0) {
                            NavigationLink(value: project.id) {
                                ProjectSummaryCardView(project: project)
                            }
                            .buttonStyle(.plain)

                            HStack {
                                Spacer()
                                Menu {
                                    Button {
                                        viewModel.editingProject = project
                                    } label: {
                                        Label("Modifier", systemImage: "pencil")
                                    }
                                    Divider()
                                    Button(role: .destructive) {
                                        viewModel.projectToDelete = project
                                    } label: {
                                        Label("Supprimer", systemImage: "trash")
                                    }
                                } label: {
                                    Label("Gérer", systemImage: "ellipsis.circle")
                                        .font(.footnote.weight(.medium))
                                        .foregroundStyle(.secondary)
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 4)
                                }
                            }
                            .padding(.horizontal, 4)
                        }
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
        .sheet(isPresented: $viewModel.showSellerComposerSheet) {
            SellerProjectComposerView()
                .presentationDetents([.large])
                .presentationContentInteraction(.scrolls)
        }
        .sheet(item: $viewModel.editingProject) { project in
            SellerProjectEditorView(project: project)
                .presentationDetents([.large])
                .presentationContentInteraction(.scrolls)
        }
        .alert("Supprimer ce projet ?", isPresented: Binding(
            get: { viewModel.projectToDelete != nil },
            set: { if !$0 { viewModel.projectToDelete = nil } }
        )) {
            Button("Annuler", role: .cancel) { viewModel.projectToDelete = nil }
            Button("Supprimer", role: .destructive) {
                if let p = viewModel.projectToDelete { viewModel.archiveProject(p) }
            }
        } message: {
            Text("Cette action est définitive. Les candidatures et conversations liées à ce projet pourront être supprimées ou archivées.")
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
        .navigationTitle("Mes projets")
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
    @State private var showingSavedProjects = false
    @State private var showingVisibleProjects = false

    var body: some View {
        @Bindable var viewModel = viewModel
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                DiscoverFeedHeroView(
                    onVisibleTap: { showingVisibleProjects = true },
                    onSavedTap: { showingSavedProjects = true }
                )

                LazyVStack(spacing: 18, pinnedViews: [.sectionHeaders]) {
                    Section {
                        ForEach(viewModel.discoverFeedProjects) { project in
                            CleanAgentProjectCardView(project: project, onOpen: {
                                selectedProject = project
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
            let newProject = await viewModel.refreshDiscoverFeed()
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
        .sheet(isPresented: $viewModel.showSubscriptionUpgradeSheet) {
            SubscriptionUpgradePromptView()
                .presentationDetents([.medium])
        }
        .sheet(isPresented: $showingSavedProjects) {
            SavedProjectsSheetView()
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingVisibleProjects) {
            VisibleProjectsSheetView()
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }
}

private struct SavedProjectsSheetView: View {
    @Environment(AppViewModel.self) private var viewModel

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.savedDiscoverProjects.isEmpty {
                    ContentUnavailableView {
                        Label("Aucun bien sauvegarde", systemImage: "heart")
                    } description: {
                        Text("Appuyez sur le coeur d un bien pour le sauvegarder.")
                    }
                } else {
                    List(viewModel.savedDiscoverProjects) { project in
                        HStack(spacing: 12) {
                            Image(systemName: "house.fill")
                                .font(.title3)
                                .foregroundStyle(StoreImmoTheme.navy)
                                .frame(width: 40, height: 40)
                                .background(StoreImmoTheme.mist, in: .circle)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(project.title)
                                    .font(.headline)
                                Text(project.city)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button {
                                viewModel.toggleSavedProject(project)
                            } label: {
                                Image(systemName: "heart.fill")
                                    .foregroundStyle(.red)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.vertical, 4)
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Biens sauvegardes")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

private struct VisibleProjectsSheetView: View {
    @Environment(AppViewModel.self) private var viewModel

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.discoverFeedProjects.isEmpty {
                    ContentUnavailableView {
                        Label("Aucun bien dans ce secteur", systemImage: "location.slash")
                    } description: {
                        Text("Elargissez votre rayon ou passez en France entiere.")
                    }
                } else {
                    List(viewModel.discoverFeedProjects) { project in
                        HStack(spacing: 12) {
                            Image(systemName: "house.fill")
                                .font(.title3)
                                .foregroundStyle(StoreImmoTheme.navy)
                                .frame(width: 40, height: 40)
                                .background(StoreImmoTheme.mist, in: .circle)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(project.title)
                                    .font(.headline)
                                    .lineLimit(1)
                                Text(project.city)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if viewModel.hasApplied(to: project) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.blue)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Biens visibles")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

private struct SubscriptionUpgradePromptView: View {
    @Environment(AppViewModel.self) private var viewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showPlans = false

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 28) {
                VStack(alignment: .leading, spacing: 12) {
                    Label("Candidature gratuite utilisée", systemImage: "sparkles")
                        .font(.title2.bold())
                    Text("Vous avez utilisé votre candidature gratuite. Souscrivez un abonnement pour continuer à candidater à de nouveaux projets.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack(spacing: 12) {
                    Button {
                        showPlans = true
                    } label: {
                        Label("Voir les offres", systemImage: "crown.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)

                    Button("Plus tard") {
                        viewModel.showSubscriptionUpgradeSheet = false
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity)
                    .controlSize(.large)
                }

                Spacer()
            }
            .padding(28)
            .navigationDestination(isPresented: $showPlans) {
                SubscriptionPlansView(showsCloseButton: true)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.showSubscriptionUpgradeSheet = false
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}

private struct DiscoverFeedHeroView: View {
    @Environment(AppViewModel.self) private var viewModel
    var onVisibleTap: () -> Void = {}
    var onSavedTap: () -> Void = {}

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
                Label("Galerie plein ecran", systemImage: "rectangle.on.rectangle")
                    .font(.footnote.weight(.semibold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.white.opacity(0.14), in: .capsule)
            }

            if !viewModel.isAgentSubscriptionActive {
                Label(
                    viewModel.freeApplicationUsed
                        ? "Candidature gratuite utilisée · abonnement requis"
                        : "Votre première candidature est offerte",
                    systemImage: viewModel.freeApplicationUsed ? "lock.fill" : "gift.fill"
                )
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    viewModel.freeApplicationUsed ? Color.orange.opacity(0.82) : Color.white.opacity(0.20),
                    in: .capsule
                )
            }

            HStack(spacing: 12) {
                Button { onVisibleTap() } label: {
                    ProjectMetricBadgeView(value: viewModel.discoverFeedProjects.count, label: "Biens visibles")
                }
                .buttonStyle(.plain)
                Button { onSavedTap() } label: {
                    ProjectMetricBadgeView(value: viewModel.savedDiscoverProjects.count, label: "Sauvegardes")
                }
                .buttonStyle(.plain)
                ProjectMetricBadgeView(
                    value: Int(viewModel.radiusFilter),
                    label: viewModel.radiusFilter == 0 ? "Zone" : "Rayon km",
                    valueText: viewModel.radiusFilter == 0 ? "France" : nil
                )
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

            Text("Le feed Découvrir n'affiche que les biens de votre périmètre. Changez votre ville ou votre rayon depuis le profil pour basculer vers une autre zone.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                ProjectMetricBadgeView(value: viewModel.discoverFeedProjects.count, label: "Biens visibles")
                ProjectMetricBadgeView(
                    value: Int(viewModel.radiusFilter),
                    label: viewModel.radiusFilter == 0 ? "Zone" : "Rayon km",
                    valueText: viewModel.radiusFilter == 0 ? "France" : nil
                )
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
                Text(viewModel.radiusFilter == 0 ? "France entière" : "\(Int(viewModel.radiusFilter)) km")
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(StoreImmoTheme.navy)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color(.secondarySystemBackground), in: .capsule)
            }

            Slider(
                value: Binding(
                    get: {
                        Double(viewModel.discoverRadiusOptions.firstIndex(of: Int(viewModel.radiusFilter)) ?? 2)
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
            Text("Rayon d'intervention")
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
                        subtitle: project.locationLabel,
                        priceText: project.formattedPrice,
                        height: 430,
                        trailingCaptionPadding: 100
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
    /// Extra trailing clearance for the caption block. Pass ~100 when an overlay button
    /// (e.g. "Voir") sits in the bottom-trailing corner of the same parent view.
    var trailingCaptionPadding: CGFloat = 18

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
        // maxWidth anchors the ZStack to the available width so scaledToFill()
        // never pushes the left edge off-screen. clipped() prevents pixel overflow.
        .frame(maxWidth: .infinity, minHeight: height, maxHeight: height)
        .clipped()
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
                    .lineLimit(1)
                    .truncationMode(.tail)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.88))
                    .lineLimit(1)
                    .truncationMode(.tail)
                Text(priceText)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
            }
            // leading: standard padding from card edge
            // bottom: 36pt clears the TabView page indicator dots (~12-16pt from bottom)
            // trailing: trailingCaptionPadding reserves space for any overlaid button
            .padding(.leading, 18)
            .padding(.bottom, 36)
            .padding(.trailing, trailingCaptionPadding)
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
        ZStack(alignment: .top) {
            Color.black.ignoresSafeArea()

            if project.photos.isEmpty {
                placeholderView
            } else {
                TabView(selection: Binding(
                    get: { selectedPhotoID ?? project.photos.first?.id ?? UUID() },
                    set: { selectedPhotoID = $0 }
                )) {
                    ForEach(project.photos) { photo in
                        GeometryReader { proxy in
                            ZStack {
                                Color.black
                                if let urlString = photo.url, let url = URL(string: urlString) {
                                    AsyncImage(url: url) { phase in
                                        switch phase {
                                        case .success(let image):
                                            image
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: proxy.size.width, height: proxy.size.height)
                                        default:
                                            Image(systemName: photo.systemName)
                                                .font(.system(size: 72, weight: .light))
                                                .foregroundStyle(.white.opacity(0.55))
                                        }
                                    }
                                } else {
                                    Image(systemName: photo.systemName)
                                        .font(.system(size: 72, weight: .light))
                                        .foregroundStyle(.white.opacity(0.55))
                                }
                            }
                            .frame(width: proxy.size.width, height: proxy.size.height)
                        }
                        .tag(photo.id)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .automatic))
                .indexViewStyle(.page(backgroundDisplayMode: .always))
                .ignoresSafeArea()
            }

            overlayBar
        }
        .ignoresSafeArea()
        .onAppear {
            print("📸 Gallery opened project:", project.id)
            print("📸 Gallery photos:", project.photos.map { $0.url ?? "no-url" })
        }
    }

    private var placeholderView: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: project.photos.first?.systemName ?? "photo.on.rectangle")
                .font(.system(size: 80, weight: .light))
                .foregroundStyle(.white.opacity(0.35))
            Text("Aucune photo disponible")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.55))
            Text("Les photos seront ajoutées par le vendeur.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.38))
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var overlayBar: some View {
        VStack(spacing: 0) {
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(12)
                        .background(.black.opacity(0.5), in: .circle)
                }

                Spacer()

                Button {
                    viewModel.toggleSavedProject(project)
                } label: {
                    Image(systemName: viewModel.isProjectSaved(project) ? "heart.fill" : "heart")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(viewModel.isProjectSaved(project) ? .red : .white)
                        .padding(12)
                        .background(.black.opacity(0.5), in: .circle)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 60)

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
                    if !project.photos.isEmpty {
                        Text("\(project.photos.count) photo\(project.photos.count > 1 ? "s" : "")")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.88))
                    }
                }
                Text(project.feedHighlight)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)
                Text(project.title)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.78))
                    .lineLimit(1)
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.black.opacity(0.5))
        }
        .allowsHitTesting(true)
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

    private var newCount: Int { project.applications.filter { !$0.sellerHasSeen }.count }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            PropertyHeroImageView(photo: project.photos.first, height: 230) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(alignment: .top) {
                        StatusBadgeView(text: project.status.accentLabel)

                        Spacer()

                        VStack(alignment: .trailing, spacing: 8) {
                            Text(project.propertyType.rawValue)
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 7)
                                .background(.black.opacity(0.22), in: .capsule)

                            if newCount > 0 {
                                ApplicationCountDotView(count: newCount)
                            }
                        }
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

private struct ApplicationCountDotView: View {
    let count: Int
    @State private var scale: CGFloat = 0.01

    private var label: String { count > 9 ? "9+" : "+\(count)" }

    var body: some View {
        Text(label)
            .font(.system(size: 12, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
            .frame(minWidth: 28, minHeight: 28)
            .padding(.horizontal, count > 9 ? 4 : 0)
            .background(Color(red: 1, green: 0.231, blue: 0.188), in: .capsule)
            .shadow(color: .black.opacity(0.28), radius: 5, y: 2)
            .scaleEffect(scale)
            .onAppear {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.52)) {
                    scale = 1
                }
            }
            .onChange(of: count) { _, _ in
                scale = 0.01
                withAnimation(.spring(response: 0.35, dampingFraction: 0.52)) {
                    scale = 1
                }
            }
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
                        Text(project.locationLabel)
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

private struct AgentApplyButton: View {
    let project: PropertyProject
    var onApply: () -> Void = {}
    var showsConfirmation: Bool = false
    @State private var pendingConfirm = false
    @Environment(AppViewModel.self) private var viewModel

    private enum ApplyState {
        case canApply
        case alreadyApplied
        case upgradeRequired
    }

    private var applyState: ApplyState {
        if viewModel.hasApplied(to: project) { return .alreadyApplied }
        if !viewModel.isAgentSubscriptionActive {
            return viewModel.freeApplicationUsed ? .upgradeRequired : .canApply
        }
        return viewModel.applicationsTodayRemaining <= 0 ? .upgradeRequired : .canApply
    }

    var body: some View {
        Group {
            switch applyState {
            case .canApply:
                Button {
                    if showsConfirmation {
                        pendingConfirm = true
                    } else {
                        onApply()
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "paperplane.fill")
                        Text("Candidater").fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .contentShape(Rectangle())

            case .alreadyApplied:
                Button { } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Candidaté").fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(true)

            case .upgradeRequired:
                Button { viewModel.showSubscriptionUpgradeSheet = true } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.up.circle.fill")
                        Text("Passer à l'offre sup.").fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .contentShape(Rectangle())
            }
        }
        .alert("Envoyer votre candidature ?", isPresented: $pendingConfirm) {
            Button("Annuler", role: .cancel) { }
            Button("Confirmer") {
                viewModel.submitAgentApplication(for: project)
            }
        } message: {
            Text("Êtes-vous sûr de vouloir candidater pour ce projet ? Cette action utilisera une candidature disponible de votre compte.")
        }
    }
}

// MARK: - Clean Agent Card (rebuilt from scratch)

private struct CleanAgentProjectCardView: View {
    let project: PropertyProject
    let onOpen: () -> Void
    @Environment(AppViewModel.self) private var viewModel
    @State private var pendingConfirm = false

    private enum ApplyState { case canApply, alreadyApplied, upgradeRequired }

    private var applyState: ApplyState {
        if viewModel.hasApplied(to: project) { return .alreadyApplied }
        if !viewModel.isAgentSubscriptionActive {
            return viewModel.freeApplicationUsed ? .upgradeRequired : .canApply
        }
        return viewModel.applicationsTodayRemaining <= 0 ? .upgradeRequired : .canApply
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            imageZone
            metaInfo
            mainButton
        }
        .padding(16)
        .background(Color(.secondarySystemBackground), in: .rect(cornerRadius: 24))
        .alert("Envoyer votre candidature ?", isPresented: $pendingConfirm) {
            Button("Annuler", role: .cancel) { }
            Button("Confirmer") {
                print("📩 CANDIDATER CONFIRM project:", project.id)
                viewModel.submitAgentApplication(for: project)
            }
        } message: {
            Text("Cette action utilisera une candidature disponible de votre compte.")
        }
    }

    // MARK: Image zone

    private var imageZone: some View {
        ZStack {
            // Layer 1 — Photo (non-interactive)
            photoContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .allowsHitTesting(false)

            // Layer 2 — Gradient (non-interactive)
            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0.25),
                    .init(color: .black.opacity(0.65), location: 1.0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .allowsHitTesting(false)

            // Layer 3 — Badges + text (non-interactive)
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top) {
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
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .padding(.trailing, 80)
                    Text(project.locationLabel)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.88))
                        .lineLimit(1)
                        .padding(.trailing, 80)
                    Text(project.formattedPrice)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.white)
                }
            }
            .padding(16)
            .allowsHitTesting(false)

            // Layer 4 — Heart button (interactive, top-right)
            VStack {
                HStack {
                    Spacer()
                    Button {
                        print("⭐ FAVORI TAP project:", project.id)
                        viewModel.toggleSavedProject(project)
                    } label: {
                        Image(systemName: viewModel.isProjectSaved(project) ? "heart.fill" : "heart")
                            .font(.headline)
                            .foregroundStyle(viewModel.isProjectSaved(project) ? .red : .white)
                            .frame(width: 42, height: 42)
                            .background(.black.opacity(0.26), in: .circle)
                    }
                }
                .padding(.top, 58)
                .padding(.trailing, 14)
                Spacer()
            }

            // Layer 5 — Voir button (interactive, bottom-right)
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button {
                        print("👁 VOIR TAP project:", project.id)
                        onOpen()
                    } label: {
                        Text("Voir").fontWeight(.semibold)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
                .padding(.bottom, 14)
                .padding(.trailing, 14)
            }
        }
        .frame(height: 230)
        .clipShape(.rect(cornerRadius: 22))
    }

    // MARK: Photo

    @ViewBuilder
    private var photoContent: some View {
        if let urlString = project.photos.first?.url, let url = URL(string: urlString) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFill()
                default:
                    symbolBackground
                }
            }
        } else {
            symbolBackground
        }
    }

    private var symbolBackground: some View {
        Color(StoreImmoTheme.navy)
            .overlay {
                Image(systemName: project.photos.first?.systemName ?? "house")
                    .font(.system(size: 56, weight: .light))
                    .foregroundStyle(.white.opacity(0.45))
            }
    }

    // MARK: Meta info

    private var metaInfo: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                StatusBadgeView(text: project.districtLabel)
                StatusBadgeView(text: project.typology.rawValue)
                Text(project.propertyType.rawValue)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Text(project.description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)
            Label(project.city, systemImage: "location")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: Main button

    @ViewBuilder
    private var mainButton: some View {
        switch applyState {
        case .canApply:
            Button {
                print("📩 CANDIDATER TAP project:", project.id)
                pendingConfirm = true
            } label: {
                Label("Candidater", systemImage: "paperplane.fill")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .contentShape(Rectangle())

        case .alreadyApplied:
            Button { } label: {
                Label("Candidaté", systemImage: "checkmark.circle.fill")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(true)

        case .upgradeRequired:
            Button {
                viewModel.showSubscriptionUpgradeSheet = true
            } label: {
                Label("Passer à l'offre sup.", systemImage: "arrow.up.circle.fill")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .contentShape(Rectangle())
        }
    }
}

private struct DiscoverPropertyCardView: View {
    let project: PropertyProject
    let onOpen: () -> Void
    @Environment(AppViewModel.self) private var viewModel

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
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .padding(.trailing, 72)
                        Text(project.locationLabel)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.88))
                            .lineLimit(1)
                            .padding(.trailing, 72)
                        Text(project.formattedPrice)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                    }
                }
            }
            .overlay(alignment: .topTrailing) {
                Button {
                    viewModel.toggleSavedProject(project)
                } label: {
                    Image(systemName: viewModel.isProjectSaved(project) ? "heart.fill" : "heart")
                        .font(.headline)
                        .foregroundStyle(viewModel.isProjectSaved(project) ? .red : .white)
                        .frame(width: 42, height: 42)
                        .background(.black.opacity(0.26), in: .circle)
                }
                .padding(.top, 68)
                .padding(.trailing, 16)
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
                        StatusBadgeView(text: project.typology.rawValue)
                        Text(project.propertyType.rawValue)
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    Text(project.description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                    Label(project.city, systemImage: "location")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            AgentApplyButton(project: project, showsConfirmation: true)
                .zIndex(10)
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
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    case .failure(let error):
                        let _ = print("🚨 AsyncImage echec:", url.absoluteString, "-", error.localizedDescription)
                        symbolBackground
                    default:
                        symbolBackground
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                symbolBackground
            }
        }
        .frame(maxWidth: .infinity, minHeight: height, maxHeight: height)
        .clipped()
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
                .allowsHitTesting(false)
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
    var valueText: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(valueText ?? value.formatted(.number.grouping(.automatic)))
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
    @State private var selectedApplication: AgentApplication?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                ProjectSummaryCardView(project: currentProject)

                PropertyPhotoStripView(photos: currentProject.photos, height: 210)


                VStack(alignment: .leading, spacing: 12) {

                    Text("Candidatures")
                        .font(.title3.bold())

                    let pendingApplications = currentProject.applications
                        .sorted { $0.appliedAt > $1.appliedAt }

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
                                    selectedApplication = application
                                },
                                onChoose: {
                                    viewModel.chooseAgent(application)
                                }
                            )
                        }
                    }
                }
            }
            .padding(20)
        }
        .onDisappear { viewModel.markAllApplicationsSeenForProject(currentProject) }
        .navigationTitle(currentProject.title)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedApplication) { application in
            AgentProfileSheetView(agent: application.agent, appliedAt: application.appliedAt)
                .presentationDetents([.medium, .large])
                .presentationContentInteraction(.scrolls)
        }
    }
}
        
private struct AgentAvatarView: View {
    let agent: AgentProfile
    var size: CGFloat = 52

    var body: some View {
        if let urlString = agent.profilePhotoURL, let url = URL(string: urlString) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: size, height: size)
                        .clipShape(.circle)
                default:
                    fallbackView
                }
            }
            .frame(width: size, height: size)
        } else {
            fallbackView
        }
    }

    private var fallbackView: some View {
        Image(systemName: agent.photoSymbol)
            .font(.system(size: size * 0.54))
            .foregroundStyle(StoreImmoTheme.navy)
            .frame(width: size, height: size)
            .background(StoreImmoTheme.mist, in: .circle)
    }
}

struct AgentApplicationCardView: View {
    let application: AgentApplication
    let onProfile: () -> Void
    let onChoose: () -> Void

    private var agencyDisplay: String {
        application.agent.agencyName.isEmpty ? "Indépendant" : application.agent.agencyName
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {

            // Header : avatar · identité · badge carte pro
            HStack(alignment: .top, spacing: 14) {
                AgentAvatarView(agent: application.agent, size: 52)

                VStack(alignment: .leading, spacing: 4) {
                    Text(application.agent.fullName)
                        .font(.headline)

                    Text(agencyDisplay)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Divider()
                        .padding(.vertical, 2)

                    Label(application.agent.trustIndicators.memberSince, systemImage: "calendar")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Label(application.agent.trustIndicators.responseTime, systemImage: "clock")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
                StatusBadgeView(text: application.agent.badge.title)
            }

            // Description de l'agent
            Text(application.customMessage)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .lineLimit(3)

            // Date de candidature
            HStack(spacing: 4) {
                Image(systemName: "clock")
                    .font(.caption2)
                Text(application.appliedAt.candidatureRelativeLabel)
                    .font(.caption)
            }
            .foregroundStyle(.secondary)

            // Actions
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
        .overlay(alignment: .topTrailing) {
            if !application.sellerHasSeen {
                Circle()
                    .fill(Color(red: 1, green: 0.231, blue: 0.188))
                    .frame(width: 11, height: 11)
                    .shadow(color: .black.opacity(0.28), radius: 3, y: 1)
                    .padding(11)
            }
        }
    }
}

private extension Date {
    var candidatureRelativeLabel: String {
        let seconds = Date().timeIntervalSince(self)
        if seconds < 60 { return "Il vient de candidater" }
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.unitsStyle = .full
        formatter.dateTimeStyle = .named
        return "A candidaté \(formatter.localizedString(for: self, relativeTo: Date()))"
    }
}

private struct AgentTrustChip: View {
    let icon: String
    let text: String

    var body: some View {
        Label(text, systemImage: icon)
            .font(.caption2.weight(.medium))
            .foregroundStyle(StoreImmoTheme.navy)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(StoreImmoTheme.mist, in: .capsule)
            .lineLimit(1)
    }
}

private struct AgentTrustRowView: View {
    let indicators: AgentTrustIndicators

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(indicators.memberSince, systemImage: "calendar")
                .font(.footnote)
                .foregroundStyle(.secondary)
            Label(indicators.responseTime, systemImage: "clock")
                .font(.footnote)
                .foregroundStyle(.secondary)
            Label(indicators.recentActivity, systemImage: "bolt.circle")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.tertiarySystemBackground), in: .rect(cornerRadius: 14))
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
    let appliedAt: Date
    @State private var fullIndicators: AgentTrustIndicators?

    private var displayedIndicators: AgentTrustIndicators {
        fullIndicators ?? agent.trustIndicators
    }

    private var agencyDisplay: String {
        agent.agencyName.isEmpty ? "Indépendant" : agent.agencyName
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    // Header — même hiérarchie que la carte candidature
                    HStack(alignment: .top, spacing: 14) {
                        AgentAvatarView(agent: agent, size: 60)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(agent.fullName)
                                .font(.headline)
                            Text(agencyDisplay)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()
                        StatusBadgeView(text: agent.badge.title)
                    }

                    // Description
                    if !agent.bio.isEmpty {
                        Text(agent.bio)
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                    }

                    // Informations du profil
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Informations du profil")
                            .font(.headline)

                        Label(displayedIndicators.memberSince, systemImage: "calendar")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Label(displayedIndicators.responseTime, systemImage: "clock")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Label(appliedAt.candidatureRelativeLabel, systemImage: "paperplane")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    // Zones d'intervention (si existantes)
                    if !agent.interventionZones.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Zones d'intervention")
                                .font(.headline)
                            ForEach(agent.interventionZones) { zone in
                                Text("• \(zone.city) · \(zone.radiusKilometers) km")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .padding(20)
            }
            .navigationTitle("Profil agent")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                fullIndicators = await SupabaseRepository.shared.buildAgentTrustIndicators(agent: agent)
            }
        }
    }
}

private struct SellerPhotoPicker: View {
    @Binding var photoSlotDatas: [Data?]
    @State private var pickerItems: [PhotosPickerItem] = []
    @State private var isLoading = false

    private let specs = AppViewModel.photoSlotSpecs
    private var filledCount: Int { photoSlotDatas.compactMap { $0 }.count }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                PhotosPicker(
                    selection: $pickerItems,
                    maxSelectionCount: specs.count,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    HStack(spacing: 12) {
                        Image(systemName: filledCount > 0 ? "photo.stack.fill" : "photo.badge.plus")
                            .font(.system(size: 16))
                            .foregroundStyle(Color(StoreImmoTheme.navy))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(filledCount > 0 ? "Photos du bien · Modifier" : "Ajouter des photos")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.primary)
                            Text("Facade, salon, cuisine, chambre...")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if isLoading {
                            ProgressView().controlSize(.small)
                        } else if filledCount > 0 {
                            Text("\(filledCount)/\(specs.count)")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color(StoreImmoTheme.navy))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color(StoreImmoTheme.navy).opacity(0.1), in: .capsule)
                        } else {
                            Text("Optionnel")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(14)
                    .background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)

                if filledCount > 0 {
                    Button {
                        photoSlotDatas = Array(repeating: nil, count: specs.count)
                        pickerItems = []
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            if filledCount > 0 {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Array(photoSlotDatas.enumerated()), id: \.offset) { i, data in
                            if let data, let img = UIImage(data: data) {
                                ZStack(alignment: .bottomLeading) {
                                    Image(uiImage: img)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 80, height: 80)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                    Text(specs[i].label)
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 4)
                                        .padding(.vertical, 2)
                                        .background(.black.opacity(0.55), in: .capsule)
                                        .padding(5)
                                }
                            }
                        }
                    }
                }
            }
        }
        .onChange(of: pickerItems) { _, items in
            guard !items.isEmpty else { return }
            isLoading = true
            Task {
                defer { isLoading = false }
                var newDatas = Array(repeating: nil as Data?, count: specs.count)
                for (i, item) in items.prefix(specs.count).enumerated() {
                    do {
                        if let raw = try await item.loadTransferable(type: Data.self) {
                            if let img = UIImage(data: raw),
                               let jpeg = img.jpegData(compressionQuality: 0.75) {
                                newDatas[i] = jpeg
                                print("📷 Photo[\(i)] chargee: \(jpeg.count / 1024)KB")
                            } else {
                                newDatas[i] = raw
                                print("📷 Photo[\(i)] chargee brute: \(raw.count / 1024)KB")
                            }
                        } else {
                            print("⚠️ Photo[\(i)] loadTransferable retourne nil")
                        }
                    } catch {
                        print("🚨 Photo[\(i)] loadTransferable erreur:", error)
                    }
                }
                photoSlotDatas = newDatas
            }
        }
    }
}

private struct SellerProjectComposerView: View {
    @Environment(AppViewModel.self) private var viewModel
    @Environment(\.dismiss) private var dismiss

    @State private var photoSlotDatas: [Data?] = Array(repeating: nil, count: 6)

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

                    Picker("Typologie", selection: $viewModel.sellerLeadDraft.typology) {
                        ForEach(PropertyTypology.allCases) { t in
                            Text(t.rawValue).tag(t)
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

                    SellerPhotoPicker(photoSlotDatas: $photoSlotDatas)
                }
                .padding(20)
            }
            .navigationTitle("Nouveau projet")
            .navigationBarTitleDisplayMode(.inline)
            .environment(\.locale, Locale(identifier: "fr_FR"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Publier") {
                        viewModel.submitSellerLead(photoDatas: photoSlotDatas)
                        dismiss()
                    }
                }
            }
        }
    }
}

private struct SellerPhotoEditorPicker: View {
    @Binding var existingURLs: [String?]
    @Binding var newDatas: [Data?]
    @State private var pickerItems: [PhotosPickerItem] = []
    @State private var isLoading = false

    private let specs = AppViewModel.photoSlotSpecs

    private var filledCount: Int {
        (0..<specs.count).filter { i in
            (newDatas.indices.contains(i) && newDatas[i] != nil) ||
            (existingURLs.indices.contains(i) && existingURLs[i] != nil)
        }.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                PhotosPicker(
                    selection: $pickerItems,
                    maxSelectionCount: specs.count,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    HStack(spacing: 12) {
                        Image(systemName: filledCount > 0 ? "photo.stack.fill" : "photo.badge.plus")
                            .font(.system(size: 16))
                            .foregroundStyle(Color(StoreImmoTheme.navy))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(filledCount > 0 ? "Photos du bien · Modifier" : "Ajouter des photos")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.primary)
                            Text("Façade, salon, cuisine, chambre...")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if isLoading {
                            ProgressView().controlSize(.small)
                        } else if filledCount > 0 {
                            Text("\(filledCount)/\(specs.count)")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color(StoreImmoTheme.navy))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color(StoreImmoTheme.navy).opacity(0.1), in: .capsule)
                        } else {
                            Text("Optionnel")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(14)
                    .background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }

            if filledCount > 0 {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(0..<specs.count, id: \.self) { i in
                            let hasNew = newDatas.indices.contains(i) && newDatas[i] != nil
                            let hasExisting = existingURLs.indices.contains(i) && existingURLs[i] != nil
                            if hasNew || hasExisting {
                                ZStack(alignment: .topTrailing) {
                                    if hasNew, let data = newDatas[i], let img = UIImage(data: data) {
                                        Image(uiImage: img)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 80, height: 80)
                                            .clipShape(RoundedRectangle(cornerRadius: 10))
                                    } else if hasExisting, let urlStr = existingURLs[i], let url = URL(string: urlStr) {
                                        AsyncImage(url: url) { phase in
                                            switch phase {
                                            case .success(let img): img.resizable().scaledToFill()
                                            default: Color(.systemGray5)
                                            }
                                        }
                                        .frame(width: 80, height: 80)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                    }
                                    Button {
                                        if newDatas.indices.contains(i) { newDatas[i] = nil }
                                        if existingURLs.indices.contains(i) { existingURLs[i] = nil }
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.system(size: 18))
                                            .symbolRenderingMode(.palette)
                                            .foregroundStyle(.white, Color.black.opacity(0.55))
                                    }
                                    .padding(3)
                                    Text(specs[i].label)
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 4)
                                        .padding(.vertical, 2)
                                        .background(.black.opacity(0.55), in: .capsule)
                                        .padding(5)
                                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                                }
                                .frame(width: 80, height: 80)
                            }
                        }
                    }
                }
            }
        }
        .onChange(of: pickerItems) { _, items in
            guard !items.isEmpty else { return }
            isLoading = true
            Task {
                defer { isLoading = false }
                var loaded = Array(repeating: nil as Data?, count: specs.count)
                for (i, item) in items.prefix(specs.count).enumerated() {
                    if let raw = try? await item.loadTransferable(type: Data.self) {
                        loaded[i] = UIImage(data: raw)?.jpegData(compressionQuality: 0.75) ?? raw
                    }
                }
                newDatas = loaded
                pickerItems = []
            }
        }
    }
}

private struct SellerProjectEditorView: View {
    let project: PropertyProject
    @Environment(AppViewModel.self) private var viewModel
    @Environment(\.dismiss) private var dismiss

    @State private var address: String
    @State private var city: String
    @State private var postalCode: String
    @State private var propertyType: PropertyType
    @State private var typology: PropertyTypology
    @State private var desiredPriceText: String
    @State private var idealListingDate: Date
    @State private var description: String
    @State private var extraInformation: String
    @State private var existingPhotoURLs: [String?]
    @State private var newPhotoDatas: [Data?]

    init(project: PropertyProject) {
        self.project = project
        _address = State(initialValue: project.fullAddress)
        _city = State(initialValue: project.city)
        _postalCode = State(initialValue: project.postalCode)
        _propertyType = State(initialValue: project.propertyType)
        _typology = State(initialValue: project.typology)
        _desiredPriceText = State(initialValue: project.desiredPrice > 0 ? "\(project.desiredPrice)" : "")
        _idealListingDate = State(initialValue: project.idealListingDate)
        _description = State(initialValue: project.description)
        _extraInformation = State(initialValue: project.extraInformation)
        let slotCount = AppViewModel.photoSlotSpecs.count
        _existingPhotoURLs = State(initialValue: (0..<slotCount).map { i in
            project.photos.indices.contains(i) ? project.photos[i].url : nil
        })
        _newPhotoDatas = State(initialValue: Array(repeating: nil, count: slotCount))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    TextField("Adresse complète", text: $address)
                        .textFieldStyle(.roundedBorder)
                    HStack {
                        TextField("Ville", text: $city)
                            .textFieldStyle(.roundedBorder)
                        TextField("Code postal", text: $postalCode)
                            .textFieldStyle(.roundedBorder)
                    }
                    Picker("Type de bien", selection: $propertyType) {
                        ForEach(PropertyType.allCases) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.menu)
                    Picker("Typologie", selection: $typology) {
                        ForEach(PropertyTypology.allCases) { t in
                            Text(t.rawValue).tag(t)
                        }
                    }
                    .pickerStyle(.menu)
                    TextField("Prix souhaité", text: $desiredPriceText)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.numberPad)
                    DatePicker("Date idéale", selection: $idealListingDate, displayedComponents: .date)
                    TextField("Description", text: $description, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(4, reservesSpace: true)
                    TextField("Informations complémentaires", text: $extraInformation, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(3, reservesSpace: true)
                    SellerPhotoEditorPicker(existingURLs: $existingPhotoURLs, newDatas: $newPhotoDatas)
                }
                .padding(20)
            }
            .navigationTitle("Modifier le projet")
            .navigationBarTitleDisplayMode(.inline)
            .environment(\.locale, Locale(identifier: "fr_FR"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Enregistrer") {
                        let price = Int(desiredPriceText.replacingOccurrences(of: " ", with: "")) ?? project.desiredPrice
                        viewModel.updateProject(
                            project,
                            address: address,
                            city: city,
                            postalCode: postalCode,
                            propertyType: propertyType,
                            typology: typology,
                            desiredPrice: price,
                            idealListingDate: idealListingDate,
                            description: description,
                            extraInformation: extraInformation,
                            existingPhotoURLs: existingPhotoURLs,
                            newPhotoDatas: newPhotoDatas
                        )
                        dismiss()
                    }
                    .fontWeight(.semibold)
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
                        Text("L'abonnement est obligatoire pour activer votre compte agent et candidater sur les projets vendeurs.")
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
                            // chooseSubscription sets showSubscriptionUpgradeSheet = false,
                            // which auto-dismisses the upgrade sheet. For onboarding
                            // (showsCloseButton = false), the view transition is handled
                            // by hasChosenAgentSubscription flipping.
                            if showsCloseButton { dismiss() }
                        }
                    }

                    if !viewModel.isAgentSubscriptionActive {
                        HStack(spacing: 10) {
                            Image(systemName: "lock.fill")
                                .foregroundStyle(.orange)
                            Text("Les fonctionnalités agent sont bloquées tant qu'aucun abonnement n'est actif.")
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

                    if SupabaseService.shared.isConfigured {
                        Text("Abonnement activé pour la session TestFlight.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 4)
                            .padding(.bottom, 12)
                    }
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
        @Bindable var viewModel = viewModel
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                ProjectOpportunityCardView(project: project)

                VStack(alignment: .leading, spacing: 10) {
                    Text("Détails du bien")
                        .font(.title3.bold())
                    HStack(spacing: 8) {
                        Text(project.propertyType.rawValue)
                            .font(.headline)
                        Text("·")
                            .foregroundStyle(.secondary)
                        Text(project.typology.rawValue)
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                    Label(project.locationLabel, systemImage: "mappin.circle")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(project.description)
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                .storeImmoCardStyle()

                PropertyPhotoStripView(photos: project.photos, height: 220)

                AgentApplyButton(project: project, onApply: { showApplicationSheet = true })
            }
            .padding(20)
        }
        .navigationTitle(project.title)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $viewModel.showSubscriptionUpgradeSheet) {
            SubscriptionUpgradePromptView()
                .presentationDetents([.medium])
        }
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

    @Environment(AppViewModel.self) private var viewModel

    private var chosenApplications: [AgentApplication] {
        project.applications.filter { $0.status.lowercased() == "chosen" }
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

                    let count = chosenApplications.count
                    Text(isExpanded
                         ? "Masquer les details"
                         : (count == 1 ? "1 agent selectionne" : "\(count) agents selectionnes"))
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.plain)

            if isExpanded {
                if chosenApplications.isEmpty {
                    Divider()
                    Text("Aucun agent selectionne pour ce projet.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)
                } else {
                    ForEach(chosenApplications) { application in
                        Divider()
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 12) {
                                AgentAvatarView(agent: application.agent, size: 46)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(application.agent.fullName)
                                        .font(.headline)
                                    Text(application.agent.agencyName)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                StatusBadgeView(text: "Selectionne")
                            }

                            HStack(spacing: 6) {
                                Label(
                                    String(format: "%.1f %%", application.proposedCommission),
                                    systemImage: "percent"
                                )
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(.secondary)
                                Text("·")
                                    .foregroundStyle(.secondary)
                                Label(application.agent.trustIndicators.memberSince, systemImage: "calendar")
                                    .font(.footnote.weight(.semibold))
                                    .foregroundStyle(.secondary)
                            }

                            Text(application.customMessage)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)

                            Button {
                                viewModel.openOrCreateConversation(application: application, project: project)
                            } label: {
                                let firstName = application.agent.fullName.components(separatedBy: " ").first ?? application.agent.fullName
                                Label(
                                    "Conversation avec \(firstName)",
                                    systemImage: "bubble.left.and.bubble.right.fill"
                                )
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
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

private struct ConversationAvatarView: View {
    let photoURL: String?
    var size: CGFloat = 46

    var body: some View {
        if let urlString = photoURL, let url = URL(string: urlString) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: size, height: size)
                        .clipShape(.circle)
                case .failure:
                    premiumDefaultAvatar
                default:
                    Circle()
                        .fill(Color(.systemGray5))
                        .frame(width: size, height: size)
                        .overlay {
                            Image(systemName: "person.fill")
                                .font(.system(size: size * 0.42))
                                .foregroundStyle(Color(.systemGray3))
                        }
                }
            }
            .frame(width: size, height: size)
        } else {
            premiumDefaultAvatar
        }
    }

    private var premiumDefaultAvatar: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [
                        StoreImmoTheme.navy,
                        Color(red: 25 / 255, green: 59 / 255, blue: 97 / 255)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: size, height: size)
            .overlay {
                Image(systemName: "person.fill")
                    .font(.system(size: size * 0.46))
                    .foregroundStyle(.white.opacity(0.92))
            }
    }
}

private struct MessagingHubView: View {
    @Environment(AppViewModel.self) private var viewModel

    var body: some View {
        Group {
            if viewModel.conversations.isEmpty {
                ContentUnavailableView {
                    Label("Aucune conversation", systemImage: "bubble.left.and.bubble.right")
                } description: {
                    Text(viewModel.selectedRole == .agent
                         ? "Lorsqu un vendeur vous selectionnera, vos echanges apparaitront ici."
                         : "Choisissez un agent pour demarrer une discussion.")
                }
            } else {
                List(viewModel.conversations) { conversation in
                    NavigationLink(value: conversation.id) {
                        HStack(alignment: .center, spacing: 12) {
                            ConversationAvatarView(
                                photoURL: conversation.participantPhotoURL,
                                size: 46
                            )
                            VStack(alignment: .leading, spacing: 4) {
                                Text(conversation.title)
                                    .font(conversation.unreadCount > 0 ? .headline.bold() : .headline)
                                Text(conversation.projectTitle)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Text(
                                    viewModel.selectedRole == .agent &&
                                    conversation.lastMessagePreview.contains("agent")
                                    ? "Commencez la discussion avec le vendeur."
                                    : conversation.lastMessagePreview
                                )
                                .font(conversation.unreadCount > 0 ? .footnote.bold() : .footnote)
                                .foregroundStyle(conversation.unreadCount > 0 ? .primary : .secondary)
                                .lineLimit(1)
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
                        .padding(.vertical, 2)
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
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
        liveConversation.title
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
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack(spacing: 9) {
                    ConversationAvatarView(
                        photoURL: liveConversation.participantPhotoURL,
                        size: 34
                    )
                    Text(displayedTitle)
                        .font(.headline)
                        .lineLimit(1)
                }
            }
        }
        .onAppear {
            viewModel.markConversationAsRead(liveConversation)
        }
    }
}

private struct ProfileSettingsView: View {
    let isAgent: Bool
    @Environment(AppViewModel.self) private var viewModel
    @State private var photoPickerItem: PhotosPickerItem?
    @State private var previewImage: UIImage?
    @State private var isUploadingPhoto = false
    @State private var showDeleteConfirmation = false

    private let cities: [String] = [
        "Ajaccio", "Aix-en-Provence", "Amiens", "Angers", "Annecy", "Avignon",
        "Bastia", "Bayonne", "Besançon", "Biarritz", "Bordeaux", "Brest",
        "Caen", "Cannes", "Clermont-Ferrand",
        "Dijon", "Dunkerque",
        "Grenoble",
        "Le Havre", "Libourne", "Lille", "Limoges", "Lyon",
        "Marseille", "Metz", "Montpellier", "Mulhouse",
        "Nancy", "Nantes", "Nice", "Nîmes",
        "Orléans",
        "Paris", "Pau", "Perpignan", "Poitiers",
        "Reims", "Rennes", "Rouen",
        "Saint-Étienne", "Strasbourg",
        "Toulon", "Toulouse", "Tours", "Troyes",
        "Valenciennes"
    ]

    var body: some View {
        List {
            if isAgent {
                Section("Photo de profil") {
                    if let preview = previewImage {
                        // Preview en attente de validation
                        VStack(spacing: 18) {
                            Image(uiImage: preview)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 76, height: 76)
                                .clipShape(.circle)
                                .overlay(Circle().stroke(Color(.systemGray4), lineWidth: 1))
                            HStack(spacing: 12) {
                                Button("Annuler") {
                                    previewImage = nil
                                    photoPickerItem = nil
                                }
                                .buttonStyle(.bordered)
                                .frame(maxWidth: .infinity)
                                Button {
                                    guard let data = preview.jpegData(compressionQuality: 0.8) else { return }
                                    isUploadingPhoto = true
                                    Task {
                                        await viewModel.uploadAndSaveAgentProfilePhoto(data)
                                        isUploadingPhoto = false
                                        previewImage = nil
                                    }
                                } label: {
                                    if isUploadingPhoto {
                                        ProgressView().tint(.white)
                                    } else {
                                        Text("Enregistrer")
                                    }
                                }
                                .buttonStyle(.borderedProminent)
                                .frame(maxWidth: .infinity)
                                .disabled(isUploadingPhoto)
                            }
                        }
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .transition(.opacity)
                    } else {
                        // Affichage photo actuelle + actions
                        let hasPhoto = viewModel.currentAgentProfile?.profilePhotoURL != nil
                        VStack(alignment: .leading, spacing: 14) {
                            HStack(spacing: 16) {
                                if let profile = viewModel.currentAgentProfile {
                                    AgentAvatarView(agent: profile, size: 76)
                                        .overlay(Circle().stroke(Color(.systemGray4), lineWidth: 1))
                                        .id(profile.profilePhotoURL ?? "none")
                                        .transition(.opacity)
                                }
                                VStack(alignment: .leading, spacing: 12) {
                                    PhotosPicker(selection: $photoPickerItem, matching: .images) {
                                        Text(hasPhoto ? "Modifier la photo" : "Ajouter une photo")
                                    }
                                    if hasPhoto {
                                        Button {
                                            showDeleteConfirmation = true
                                        } label: {
                                            Text("Supprimer la photo")
                                                .foregroundStyle(.red)
                                        }
                                        .font(.subheadline)
                                    }
                                }
                                Spacer()
                            }
                            .padding(.vertical, 4)
                            .animation(.easeInOut(duration: 0.25), value: viewModel.currentAgentProfile?.profilePhotoURL)

                            Text("Votre photo sera visible par les vendeurs lorsque vous candidatez.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .transition(.opacity)
                    }
                }
                .onChange(of: photoPickerItem) { _, item in
                    guard let item else { return }
                    print("[Photo profil] Sélectionnée")
                    Task {
                        guard let data = try? await item.loadTransferable(type: Data.self),
                              let image = UIImage(data: data) else {
                            print("[Photo profil] Erreur: chargement image impossible")
                            return
                        }
                        withAnimation(.easeInOut(duration: 0.2)) {
                            previewImage = image
                        }
                        photoPickerItem = nil
                    }
                }
            }

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

            Section(isAgent ? "Mon abonnement" : "Confiance") {
                if isAgent {
                    if viewModel.hasChosenAgentSubscription {
                        Label("Plan \(viewModel.selectedPlan.title) · actif", systemImage: viewModel.selectedPlan.iconName)
                        Label(viewModel.selectedPlan.activeApplicationsLabel, systemImage: "person.badge.plus")
                    } else {
                        Label(
                            viewModel.freeApplicationUsed
                                ? "Candidature gratuite utilisée"
                                : "1 candidature gratuite disponible",
                            systemImage: viewModel.freeApplicationUsed ? "sparkles.slash" : "sparkles"
                        )
                        .foregroundStyle(viewModel.freeApplicationUsed ? .orange : .primary)
                        Label("Sans abonnement actif", systemImage: "xmark.circle")
                            .foregroundStyle(.secondary)
                    }
                    NavigationLink {
                        SubscriptionPlansView(showsCloseButton: true)
                    } label: {
                        Label("Gérer mon abonnement", systemImage: "creditcard")
                    }
                } else {
                    Label("RGPD friendly", systemImage: "lock.shield")
                    Label("Avis vérifiés en fin de mandat", systemImage: "star.bubble")
                }
            }

            #if DEBUG
            if isAgent {
                Section("Tables Supabase à créer") {
                    NavigationLink("Voir le schéma nécessaire") {
                        SupabaseRequirementsView()
                    }
                }
            }
            #endif

            Section("Notifications") {
                if viewModel.notifications.isEmpty {
                    Text("Aucune notification")
                        .foregroundStyle(.secondary)
                        .font(.subheadline)
                } else {
                    ForEach(viewModel.notifications) { item in
                        Button {
                            viewModel.openFromNotification(item)
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: item.symbolName)
                                    .font(.title3)
                                    .foregroundStyle(item.isRead ? Color(.secondaryLabel) : Color.blue)
                                    .frame(width: 28)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(item.title)
                                        .font(item.isRead ? .subheadline : .subheadline.bold())
                                        .foregroundStyle(.primary)
                                    Text(item.body)
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(2)
                                }
                                Spacer()
                                if !item.isRead {
                                    Circle()
                                        .fill(.blue)
                                        .frame(width: 8, height: 8)
                                }
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
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
        .confirmationDialog(
            "Supprimer la photo ?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Supprimer", role: .destructive) {
                Task { await viewModel.removeAgentProfilePhoto() }
            }
            Button("Annuler", role: .cancel) {}
        } message: {
            Text("Cette action rétablira votre avatar par défaut.")
        }
    }
}

private struct OTPVerificationView: View {
    @Environment(AppViewModel.self) private var viewModel
    @Environment(\.dismiss) private var dismiss
    @State private var canResend = false

    var body: some View {
        @Bindable var viewModel = viewModel
        NavigationStack {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Vérification par email")
                        .font(.largeTitle.bold())
                    if let email = viewModel.pendingOTPEmail {
                        Text("Un code de verification a ete envoye a **\(email)**.")
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                    Text("Vérifiez aussi votre dossier spams.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Code de vérification")
                        .font(.subheadline.weight(.semibold))
                    TextField("Code de verification", text: $viewModel.otpCode)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.numberPad)
                        .textContentType(.oneTimeCode)
                        .font(.title2.monospacedDigit())
                        .multilineTextAlignment(.center)
                }
                .padding(16)
                .background(Color(.secondarySystemBackground), in: .rect(cornerRadius: 16))

                if let message = viewModel.appStatusMessage {
                    Text(message)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(message.lowercased().contains("erreur") || message.lowercased().contains("trop") || message.lowercased().contains("impossible") ? .red : StoreImmoTheme.navy)
                        .padding(.horizontal, 4)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Button {
                    viewModel.submitOTPCode()
                } label: {
                    Group {
                        if viewModel.isVerifyingOTP {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Label("Vérifier le code", systemImage: "checkmark.shield.fill")
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(viewModel.otpCode.trimmingCharacters(in: .whitespaces).count < 4 || viewModel.isVerifyingOTP)

                Button {
                    viewModel.resendOTP()
                    canResend = false
                    Task {
                        try? await Task.sleep(for: .seconds(30))
                        canResend = true
                    }
                } label: {
                    Text(canResend ? "Renvoyer le code" : "Renvoyer le code (30s)")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .disabled(!canResend || viewModel.isVerifyingOTP)

                Spacer()
            }
            .padding(24)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") {
                        viewModel.cancelOTP()
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
        .onAppear {
            canResend = false
            Task {
                try? await Task.sleep(for: .seconds(30))
                canResend = true
            }
        }
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
