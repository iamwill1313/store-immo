import Foundation
import Observation

@Observable
@MainActor
final class AppViewModel {

    static let photoSlotSpecs: [(systemName: String, label: String, accentName: String)] = [
        ("house.fill",             "Façade",        "sparkles"),
        ("sofa.fill",              "Salon",         "lamp.floor.fill"),
        ("fork.knife.circle.fill", "Cuisine",       "sparkles"),
        ("bed.double.fill",        "Chambre",       "sparkles"),
        ("drop.fill",              "Salle de bain", "sparkles"),
        ("tree.fill",              "Extérieur",     "leaf.fill"),
    ]

    var selectedRole: UserRole?
    var isAuthenticated: Bool = false
    var registeredEmails: Set<String> = []
    var isCheckingAccount: Bool = false
    var sellerTab: AppTabSeller = .dashboard
    var agentTab: AppTabAgent = .discover
    var sellerMessagesNavPath: [UUID] = []
    var agentMessagesNavPath: [UUID] = []

    /// Total unread messages across all conversations.
    var unreadConversationCount: Int {
        conversations.reduce(0) { $0 + $1.unreadCount }
    }

    /// Notifications not yet read by the current user.
    var unreadNotificationCount: Int {
        notifications.filter { !$0.isRead }.count
    }
    var sellerProjects: [PropertyProject]
    var agentOpportunities: [PropertyProject]
    var sellerMandates: [Mandate]
    var agentMandates: [Mandate]
    var conversations: [Conversation]
    var notifications: [NotificationItem]
    var sellerLeadDraft: SellerLeadDraft = SellerLeadDraft()
    var agentApplicationDraft: AgentApplicationDraft = AgentApplicationDraft()
    var selectedProject: PropertyProject?
    var selectedApplication: AgentApplication?
    var selectedConversation: Conversation?
    
    /// The ID of the conversation currently visible on screen (in ConversationView).
    /// Set to non-nil when ConversationView appears, reset to nil when it disappears.
    /// Used to determine if in-app notification banners should be shown.
    var currentVisibleConversationID: UUID? = nil
    
    var selectedMandate: Mandate?
    var selectedPlan: SubscriptionPlan = .pro
    var hasCompletedAgentProfileOnboarding: Bool = false
    var hasChosenAgentSubscription: Bool = false
    var hasCompletedSellerOnboarding: Bool = false
    var agentOnboardingDraft: AgentOnboardingDraft = AgentOnboardingDraft()
    var sellerOnboardingDraft: SellerOnboardingDraft = SellerOnboardingDraft()
    var currentAgentProfile: AgentProfile?
    var appStatusMessage: String?
    var revealPhoneNumber: Bool = false
    var isPushEnabled: Bool = true
    var radiusFilter: Double = 50
    var savedProjectIDs: Set<UUID> = []
    var appliedProjectIDs: Set<UUID> = []
    var freeApplicationUsed: Bool = false
    var showSubscriptionUpgradeSheet: Bool = false
    var pendingPlan: SubscriptionPlan? = nil
    var showSellerComposerSheet: Bool = false
    var editingProject: PropertyProject? = nil
    var projectToDelete: PropertyProject? = nil
    var sellerPhoneNumber: String = ""
    var agentBaseCity: String = "Paris"
    var isDiscoverFeedRefreshing: Bool = false
    let discoverRadiusOptions: [Int] = [10, 25, 50, 100, 250, 0]
    var pendingOTPEmail: String? = nil
    var otpCode: String = ""
    var isVerifyingOTP: Bool = false
    var inAppBanner: NotificationItem? = nil

    private var sellerProfileFirstName: String = ""
    private var sellerProfileLastName: String = ""
    private var discoverFeedPage: Int = 1
    private let discoverFeedPageSize: Int = 4
    private var discoverFeedSource: [PropertyProject]
    private let analyticsSessionID = UUID().uuidString
    private var realtimeApplicationTask: Task<Void, Never>? = nil
    private var realtimeNotificationTask: Task<Void, Never>? = nil
    private var realtimeMessagesTask: Task<Void, Never>? = nil
    private var pendingOTPAction: PendingOTPAction? = nil
    private let selfNotificationTypes: Set<String> = ["application_sent", "project_published"]

    private enum PendingOTPAction {
        case loginSeller(email: String)
        case loginAgent(email: String)
        case registerSeller
        case registerAgent
    }

    init() {
        if SupabaseService.shared.isConfigured {
            self.sellerProjects = []
            self.discoverFeedSource = []
            self.agentOpportunities = []
            self.sellerMandates = []
            self.agentMandates = []
            self.conversations = []
            self.notifications = []
            self.selectedProject = nil
            self.selectedApplication = nil
            self.selectedConversation = nil
            self.selectedMandate = nil
        } else {
            let sample = DemoDataFactory.make()
            self.sellerProjects = sample.projects
            self.discoverFeedSource = sample.feedProjects
            self.agentOpportunities = []
            self.sellerMandates = sample.sellerMandates
            self.agentMandates = sample.agentMandates
            self.conversations = sample.conversations
            self.notifications = sample.notifications
            self.selectedProject = sample.projects.first
            self.selectedApplication = sample.projects.first?.applications.first
            self.selectedConversation = sample.conversations.first
            self.selectedMandate = sample.sellerMandates.first
        }
        loadPersistedSession()
        Task {
            // Pre-load the public project feed regardless of auth state.
            // User-specific data (seller projects, conversations…) is loaded in chooseRole().
            await loadSellerProjectsFromSupabase()
        }
    }

    func loadSellerProjectsFromSupabase() async {
        guard SupabaseRepository.shared.isConfigured else { return }

        await SupabaseRepository.shared.bootstrapAuth()

        let isoFormatter = ISO8601DateFormatter()
        let dateOnlyFormatter: DateFormatter = {
            let f = DateFormatter()
            f.dateFormat = "yyyy-MM-dd"
            f.locale = Locale(identifier: "en_US_POSIX")
            return f
        }()

        func buildProjects(from rows: [SellerProjectRow], applicationRows: [ApplicationRow], agentRows: [AgentProfileRow]) -> [PropertyProject] {
            rows.map { row in
                let mainURL = row.photo_url.flatMap { $0.isEmpty ? nil : $0 }
                let projectID = row.id.lowercased()
                print("📷 buildProjects \(projectID.prefix(8)): photo_url =", mainURL ?? "nil")
                return PropertyProject(
                    id: UUID(uuidString: row.id) ?? UUID(),
                    title: "\(row.property_type) à \(row.city)",
                    fullAddress: row.address,
                    city: row.city,
                    postalCode: row.postal_code,
                    propertyType: PropertyType(rawValue: row.property_type) ?? .apartment,
                    typology: PropertyTypology(rawValue: row.typology ?? "") ?? .autre,
                    description: row.description,
                    desiredPrice: row.desired_price,
                    idealListingDate: isoFormatter.date(from: row.ideal_listing_date)
                        ?? dateOnlyFormatter.date(from: row.ideal_listing_date)
                        ?? Date(),
                    extraInformation: "",
                    photos: AppViewModel.photoSlotSpecs.enumerated().map { i, spec in
                        let derivedURL: String?
                        if i == 0 {
                            derivedURL = mainURL
                        } else if let base = mainURL, base.contains("\(projectID).jpg") {
                            derivedURL = base.replacingOccurrences(of: "\(projectID).jpg", with: "\(projectID)_\(i).jpg")
                        } else {
                            derivedURL = nil
                        }
                        return PhotoAsset(systemName: spec.systemName, label: spec.label, accentName: spec.accentName, url: derivedURL)
                    },
                    status: ProjectStatus(rawValue: row.status) ?? .published,
                    applications: applicationRows
                        .filter { $0.project_id == row.id }
                        .map { appRow in
                            let agentRow = agentRows.first { $0.user_id == appRow.agent_id }
                            let agent = AgentProfile(
                                id: UUID(uuidString: agentRow?.user_id ?? appRow.agent_id ?? "") ?? UUID(),
                                fullName: "\(agentRow?.first_name ?? "Agent") \(agentRow?.last_name ?? "")".trimmingCharacters(in: .whitespaces),
                                agencyName: agentRow?.agency ?? "Independant",
                                city: agentRow?.city ?? "",
                                badge: .professionalCard(number: "Verifie"),
                                bio: agentRow?.description ?? "Agent immobilier.",
                                averageRating: 0, reviewCount: 0, salesLast12Months: 0,
                                soldRate: 0, averageSalePrice: 0, averageDelayDays: 0,
                                commissionPercent: appRow.commission_percent,
                                interventionZones: [], reviews: [],
                                photoSymbol: "person.crop.circle.fill",
                                plan: .starter,
                                memberSinceDate: agentRow?.created_at.flatMap { ISO8601DateFormatter().date(from: $0) },
                                profilePhotoURL: agentRow?.profile_photo_url
                            )
                            return AgentApplication(
                                id: UUID(uuidString: appRow.id) ?? UUID(),
                                projectID: UUID(uuidString: appRow.project_id) ?? UUID(),
                                agent: agent,
                                proposedCommission: appRow.commission_percent,
                                customMessage: appRow.message,
                                status: appRow.status,
                                appliedAt: appRow.created_at.flatMap { ISO8601DateFormatter().date(from: $0) } ?? Date(),
                                sellerHasSeen: appRow.seller_has_seen ?? false
                            )
                        },
                    selectedAgentID: UUID(uuidString: row.selected_agent_id ?? ""),
                    requiredRegion: row.city,
                    districtLabel: row.postal_code,
                    feedHighlight: row.property_type.capitalized,
                    sellerID: row.seller_id
                )
            }
        }

        // Seller: only own projects filtered by seller_id, with only their applications
        if selectedRole == .seller {
            let sellerRows = await SupabaseRepository.shared.fetchSellerProjects(
                sellerID: SupabaseRepository.shared.currentUserID
            )
            print("📦 Projets vendeur chargés :", sellerRows.count)
            let sellerProjectIDs = sellerRows.map { $0.id }
            let filteredApplicationRows = await SupabaseRepository.shared.fetchApplicationsForProjects(projectIDs: sellerProjectIDs)
            let applicantIDs = Array(Set(filteredApplicationRows.compactMap { $0.agent_id }))
            let filteredAgentRows = await SupabaseRepository.shared.fetchAgentProfilesByUserIDs(applicantIDs)
            let projects = buildProjects(from: sellerRows, applicationRows: filteredApplicationRows, agentRows: filteredAgentRows)
            self.sellerProjects = projects
            if let prev = selectedProject {
                self.selectedProject = projects.first { $0.id == prev.id } ?? projects.first
            } else {
                self.selectedProject = projects.first
            }
        }

        // Agent (or unauthenticated on launch): all projects for discover feed, no application data needed
        if selectedRole == .agent || selectedRole == nil {
            let allRows = await SupabaseService.shared.fetch(from: "sellers_projects", as: SellerProjectRow.self)
                .filter { $0.status != ProjectStatus.deleted.rawValue }
            print("📦 Projets feed agent chargés :", allRows.count)
            if !allRows.isEmpty {
                let projects = buildProjects(from: allRows, applicationRows: [], agentRows: [])
                self.discoverFeedSource = projects
                let prevID = selectedProject?.id
                resetAgentFeed()
                if selectedRole == .agent, let prevID {
                    self.selectedProject = projects.first { $0.id == prevID } ?? agentOpportunities.first
                }
            }
        }
    }
    var featuredAgents: [AgentProfile] {
        sellerProjects.flatMap(\.applications).map(\.agent)
    }

    var chosenApplication: AgentApplication? {
        guard let selectedProject else { return nil }
        return selectedProject.applications.first { $0.agent.id == selectedProject.selectedAgentID }
    }

    var applicationsTodayRemaining: Int {
        guard hasChosenAgentSubscription else { return 0 }
        let max = selectedPlan.maxActiveApplications
        guard max < 999 else { return 999 }
        return Swift.max(0, max - appliedProjectIDs.count)
    }

    var unreadApplicationCount: Int {
        sellerProjects.flatMap(\.applications).filter { !$0.sellerHasSeen }.count
    }

    var sortedSellerProjects: [PropertyProject] {
        sellerProjects.sorted { a, b in
            let aLatest = a.applications.filter { !$0.sellerHasSeen }.map(\.appliedAt).max()
            let bLatest = b.applications.filter { !$0.sellerHasSeen }.map(\.appliedAt).max()
            if let ad = aLatest, let bd = bLatest { return ad > bd }
            if aLatest != nil { return true }
            if bLatest != nil { return false }
            return false
        }
    }
    var isAgentSubscriptionActive: Bool {
        hasChosenAgentSubscription
    }

    var hasUnlimitedApplications: Bool {
        hasChosenAgentSubscription && selectedPlan == .elite
    }

    var agentSectorSummary: String {
        radiusFilter == 0
            ? "\(agentBaseCity) · France entière"
            : "\(agentBaseCity) · rayon \(Int(radiusFilter)) km"
    }

    var savedDiscoverProjects: [PropertyProject] {
        discoverFeedProjects.filter { savedProjectIDs.contains($0.id) }
    }

    var hasCompletedAgentOnboarding: Bool {
        hasCompletedAgentProfileOnboarding
    }

    var sellerPublicFirstName: String {
        sellerProfileFirstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Vendeur" : sellerProfileFirstName
    }

    var supabaseRequirements: [SupabaseTableRequirement] {
        [
            SupabaseTableRequirement(name: "users", purpose: "Compte commun vendeur/agent relié à Supabase Auth.", requiredColumns: ["id uuid primary key references auth.users", "role text", "email text", "phone text", "created_at timestamptz"]),
            SupabaseTableRequirement(name: "sellers_profiles", purpose: "Profil vendeur privé ; seul first_name est affiché publiquement.", requiredColumns: ["id uuid primary key", "user_id uuid references users", "first_name text", "last_name text", "email text", "phone text", "created_at timestamptz"]),
            SupabaseTableRequirement(name: "agents_profiles", purpose: "Profil agent vérifié et paramètres de feed.", requiredColumns: ["id uuid primary key", "user_id uuid references users", "photo_url text", "first_name text", "last_name text", "email text", "city text", "agency text", "description text", "phone text", "verification_type text", "verification_number text", "verification_file_url text", "feed_radius_km int default 50"]),
            SupabaseTableRequirement(name: "sellers_projects", purpose: "Biens publiés par les vendeurs.", requiredColumns: ["id uuid primary key", "seller_id uuid references users", "address text", "city text", "postal_code text", "property_type text", "description text", "desired_price int", "ideal_listing_date date", "status text", "latitude double precision", "longitude double precision"]),
            SupabaseTableRequirement(name: "project_photos", purpose: "Photos multi-upload des biens via Supabase Storage.", requiredColumns: ["id uuid primary key", "project_id uuid references sellers_projects", "storage_path text", "sort_order int"]),
            SupabaseTableRequirement(name: "applications", purpose: "Candidatures agents, une seule par agent/projet.", requiredColumns: ["id uuid primary key", "project_id uuid references sellers_projects", "agent_id uuid references agents_profiles", "message text", "commission_percent numeric", "status text", "created_at timestamptz", "unique(project_id, agent_id)"]),
            SupabaseTableRequirement(name: "subscriptions", purpose: "Plan actif agent et limites quotidiennes.", requiredColumns: ["id uuid primary key", "agent_id uuid references agents_profiles", "plan text", "status text", "stripe_customer_id text", "stripe_subscription_id text", "current_period_end timestamptz"]),
            SupabaseTableRequirement(name: "payments", purpose: "Historique de paiement Stripe.", requiredColumns: ["id uuid primary key", "subscription_id uuid references subscriptions", "stripe_payment_intent_id text", "amount_cents int", "currency text", "status text", "paid_at timestamptz"]),
            SupabaseTableRequirement(name: "conversations", purpose: "Fil de discussion vendeur-agent par projet.", requiredColumns: ["id uuid primary key", "project_id uuid references sellers_projects", "seller_id uuid references users", "agent_id uuid references agents_profiles", "created_at timestamptz"]),
            SupabaseTableRequirement(name: "messages", purpose: "Messages temps réel via Supabase Realtime.", requiredColumns: ["id uuid primary key", "conversation_id uuid references conversations", "sender_id uuid references users", "body text", "read_at timestamptz", "created_at timestamptz"]),
            SupabaseTableRequirement(name: "reviews", purpose: "Avis vérifiés après fin de mandat.", requiredColumns: ["id uuid primary key", "project_id uuid references sellers_projects", "agent_id uuid references agents_profiles", "seller_id uuid references users", "rating numeric", "comment text", "outcome_tag text", "created_at timestamptz"]),
            SupabaseTableRequirement(name: "notifications", purpose: "Notifications transactionnelles in-app et push.", requiredColumns: ["id uuid primary key", "user_id uuid references users", "title text", "body text", "type text", "is_read boolean default false", "created_at timestamptz"]),
            SupabaseTableRequirement(name: "appointments", purpose: "RDV liés aux mandats.", requiredColumns: ["id uuid primary key", "project_id uuid references sellers_projects", "title text", "scheduled_at timestamptz", "location text", "note text", "reminder_at timestamptz"]),
            SupabaseTableRequirement(name: "mandates", purpose: "Mandats digitaux et suivi commercialisation.", requiredColumns: ["id uuid primary key", "project_id uuid references sellers_projects", "agent_id uuid references agents_profiles", "seller_id uuid references users", "status text", "valuation_notice text", "mandate_file_url text", "signed_at timestamptz"])
        ]
    }

    var discoverFeedProjects: [PropertyProject] {
        agentOpportunities
    }

    func chooseRole(_ role: UserRole) {
        selectedRole = role
        // If the user already has an active session, load their data immediately so the
        // dashboard is populated when ContentView navigates to it.
        if isAuthenticated && SupabaseRepository.shared.isConfigured {
            Task { @MainActor in
                await loadUserDataFromSupabase()
            }
        }
    }

    func completeAuthentication() {
        isAuthenticated = true
        saveSession()

        if selectedRole == .seller {
            appStatusMessage = hasCompletedSellerOnboarding
            ? "Compte vendeur activé. Vous pouvez publier un projet."
            : "Complétez votre profil vendeur pour continuer."
        }

        if selectedRole == .agent {
            appStatusMessage = hasCompletedAgentProfileOnboarding
            ? "Compte agent activé."
            : "Complétez votre profil agent pour continuer."
        }
    }

    func loginExistingAccount(role: UserRole, email: String, phone: String) {
        guard !isCheckingAccount else { return }
        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !normalizedEmail.isEmpty else {
            appStatusMessage = "Veuillez saisir un email valide."
            return
        }
        isCheckingAccount = true
        Task { @MainActor in
            defer { isCheckingAccount = false }

            if SupabaseRepository.shared.isConfigured {
                let exists = await SupabaseRepository.shared.emailExists(email: normalizedEmail)
                guard exists else {
                    appStatusMessage = "Aucun compte trouvé pour cet email. Créez d'abord un compte."
                    return
                }
                // Send OTP for verification
                let sentLogin = await SupabaseService.shared.signInWithOTP(email: normalizedEmail)
                guard sentLogin else {
                    appStatusMessage = otpSendErrorMessage(SupabaseService.shared.lastError)
                    return
                }
                pendingOTPAction = role == .seller ? .loginSeller(email: normalizedEmail) : .loginAgent(email: normalizedEmail)
                pendingOTPEmail = normalizedEmail
                appStatusMessage = nil
            } else {
                // Demo mode: skip OTP
                selectedRole = role
                isAuthenticated = true
                registeredEmails.insert(normalizedEmail)
                switch role {
                case .seller:
                    hasCompletedSellerOnboarding = true
                    appStatusMessage = "Connexion vendeur réussie."
                case .agent:
                    hasCompletedAgentProfileOnboarding = true
                    hasChosenAgentSubscription = true
                    appStatusMessage = "Connexion agent réussie."
                }
                saveSession()
            }
        }
    }
    
    func saveSellerOnboarding() {
        guard !isCheckingAccount else { return }
        let email = sellerOnboardingDraft.email
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        // Fast local check (same session, instant feedback)
        if registeredEmails.contains(email) {
            appStatusMessage = "Cet email est déjà associé à un compte. Utilisez « Se connecter »."
            return
        }
        guard sellerOnboardingDraft.isComplete else {
            appStatusMessage = "Complétez tous les champs obligatoires du profil vendeur."
            return
        }

        isCheckingAccount = true
        let draft = sellerOnboardingDraft
        Task { @MainActor in
            defer { isCheckingAccount = false }

            // Persistent Supabase check (cross-device, cross-session)
            if SupabaseRepository.shared.isConfigured {
                let exists = await SupabaseRepository.shared.emailExists(email: email)
                if exists {
                    appStatusMessage = "Cet email est déjà associé à un compte. Utilisez « Se connecter »."
                    return
                }
            }

            sellerProfileFirstName = draft.firstName.trimmingCharacters(in: .whitespacesAndNewlines)
            sellerProfileLastName = draft.lastName.trimmingCharacters(in: .whitespacesAndNewlines)
            sellerPhoneNumber = draft.phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines)
            registeredEmails.insert(email)

            // upsertUser and saveSellerProfile are deferred to completePendingOTPAction.
            // Calling them here (before OTP) produces a random UUID (no auth session yet),
            // which creates a stale users row that breaks sellers_projects FK constraints.

            if SupabaseRepository.shared.isConfigured {
                let sentSeller = await SupabaseService.shared.signInWithOTP(email: email)
                guard sentSeller else {
                    appStatusMessage = otpSendErrorMessage(SupabaseService.shared.lastError)
                    return
                }
                pendingOTPAction = .registerSeller
                pendingOTPEmail = email
                appStatusMessage = nil
            } else {
                hasCompletedSellerOnboarding = true
                isAuthenticated = true
                appStatusMessage = "Profil vendeur enregistré. Bienvenue, \(sellerPublicFirstName)."
                saveSession()
            }
        }
    }

    func saveAgentProfileOnboarding() {
        guard !isCheckingAccount else { return }
        let email = agentOnboardingDraft.email
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        // Fast local check (same session, instant feedback)
        if registeredEmails.contains(email) {
            appStatusMessage = "Cet email est déjà associé à un compte. Utilisez « Se connecter »."
            return
        }
        guard agentOnboardingDraft.isComplete else {
            appStatusMessage = "Complétez tous les champs obligatoires du profil agent."
            return
        }

        isCheckingAccount = true
        let draft = agentOnboardingDraft
        Task { @MainActor in
            defer { isCheckingAccount = false }

            // Persistent Supabase check (cross-device, cross-session)
            if SupabaseRepository.shared.isConfigured {
                let exists = await SupabaseRepository.shared.emailExists(email: email)
                if exists {
                    appStatusMessage = "Cet email est déjà associé à un compte. Utilisez « Se connecter »."
                    return
                }
            }

            let fullName = "\(draft.firstName) \(draft.lastName)"
            let description = draft.professionalDescription.trimmingCharacters(in: .whitespacesAndNewlines)
            currentAgentProfile = AgentProfile(
                fullName: fullName,
                agencyName: draft.agency.isEmpty ? "Indépendant" : draft.agency,
                city: draft.city,
                badge: .professionalCard(number: "Vérification en cours"),
                bio: description.isEmpty ? "Agent immobilier vérifié sur Store Immo." : description,
                averageRating: 0,
                reviewCount: 0,
                salesLast12Months: 0,
                soldRate: 0,
                averageSalePrice: 0,
                averageDelayDays: 0,
                commissionPercent: 4.5,
                interventionZones: [CityZone(city: draft.city, region: draft.city, radiusKilometers: Int(radiusFilter))],
                reviews: [],
                photoSymbol: draft.photoSymbol,
                plan: selectedPlan
            )
            agentBaseCity = draft.city
            registeredEmails.insert(email)

            // upsertUser and saveAgentProfile are deferred to completePendingOTPAction.
            // Calling them here (before OTP) produces a random UUID (no auth session yet).

            if SupabaseRepository.shared.isConfigured {
                let sentAgent = await SupabaseService.shared.signInWithOTP(email: email)
                guard sentAgent else {
                    appStatusMessage = otpSendErrorMessage(SupabaseService.shared.lastError)
                    return
                }
                pendingOTPAction = .registerAgent
                pendingOTPEmail = email
                appStatusMessage = nil
            } else {
                hasCompletedAgentProfileOnboarding = true
                resetAgentFeed()
                appStatusMessage = "Profil agent enregistre. Bienvenue sur Store Immo !"
                saveSession()
            }
        }
    }

    func chooseSubscription(_ plan: SubscriptionPlan) {
        selectedPlan = plan
        pendingPlan = nil
        hasChosenAgentSubscription = true
        // Dismiss the upgrade sheet immediately so the agent lands back on the feed
        // with the button already in "Candidater" state.
        showSubscriptionUpgradeSheet = false
        appStatusMessage = "Abonnement \(plan.title) activé."
        saveSession()
        Task { @MainActor in
            let okSub = await SupabaseRepository.shared.saveSubscription(plan: plan)
            _ = await SupabaseRepository.shared.recordPayment(plan: plan)
            await SupabaseRepository.shared.logAnalyticsEvent(name: "subscription_chosen", sessionID: analyticsSessionID)
            if !okSub, let err = SupabaseRepository.shared.lastError {
                appStatusMessage = "Supabase: \(err)"
            }
        }
    }

    func signOut() {
        clearUserData()
        isAuthenticated = false
        selectedRole = nil
        hasCompletedSellerOnboarding = false
        hasCompletedAgentProfileOnboarding = false
        hasChosenAgentSubscription = false
        revealPhoneNumber = false
        sellerProfileFirstName = ""
        sellerProfileLastName = ""
        pendingOTPEmail = nil
        otpCode = ""
        SupabaseRepository.shared.resetUserID()
        clearPersistedSession()
        Task { await SupabaseService.shared.signOut() }
    }

    private func clearUserData() {
        stopApplicationsRealtime()
        stopNotificationsRealtime()
        stopMessagesRealtime()
        inAppBanner = nil
        sellerProjects = []
        conversations = []
        notifications = []
        appliedProjectIDs = []
        savedProjectIDs = []
        freeApplicationUsed = false
        currentAgentProfile = nil
        discoverFeedSource = []
        agentOpportunities = []
        selectedProject = nil
        selectedApplication = nil
        selectedConversation = nil
    }

    func submitOTPCode() {
        guard let email = pendingOTPEmail, !otpCode.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let code = otpCode.trimmingCharacters(in: .whitespaces)
        isVerifyingOTP = true
        Task { @MainActor in
            defer { isVerifyingOTP = false }
            let success = await SupabaseService.shared.verifyOTP(email: email, token: code)
            if success {
                otpCode = ""
                pendingOTPEmail = nil
                await completePendingOTPAction(email: email)
            } else {
                appStatusMessage = otpVerifyErrorMessage(SupabaseService.shared.lastError)
            }
        }
    }

    func cancelOTP() {
        pendingOTPEmail = nil
        otpCode = ""
        pendingOTPAction = nil
        appStatusMessage = nil
    }

    func resendOTP() {
        guard let email = pendingOTPEmail, !isVerifyingOTP else { return }
        isVerifyingOTP = true
        Task { @MainActor in
            defer { isVerifyingOTP = false }
            let sent = await SupabaseService.shared.signInWithOTP(email: email)
            appStatusMessage = sent
                ? "Nouveau code envoyé à \(email). Vérifiez vos spams."
                : otpSendErrorMessage(SupabaseService.shared.lastError)
        }
    }

    private func otpSendErrorMessage(_ raw: String?) -> String {
        guard let raw else { return "Impossible d'envoyer le code. Vérifiez votre connexion." }
        let lower = raw.lowercased()
        if lower.contains("rate") || lower.contains("too many") || lower.contains("429") || lower.contains("60 second") {
            return "Trop de tentatives. Attendez quelques minutes avant de réessayer."
        }
        if lower.contains("invalid") && lower.contains("email") {
            return "Adresse email invalide."
        }
        if lower.contains("not found") || lower.contains("does not exist") {
            return "Aucun compte trouvé pour cet email."
        }
        return "Erreur Supabase : \(raw)"
    }

    private func otpVerifyErrorMessage(_ raw: String?) -> String {
        guard let raw else { return "Code invalide ou expiré. Réessayez." }
        let lower = raw.lowercased()
        if lower.contains("rate") || lower.contains("too many") || lower.contains("429") {
            return "Trop de tentatives. Attendez avant de réessayer."
        }
        if lower.contains("expired") || lower.contains("expiré") {
            return "Code expiré. Renvoyez un nouveau code."
        }
        if lower.contains("invalid") || lower.contains("incorrect") {
            return "Code incorrect. Vérifiez le code reçu par email."
        }
        return "Code invalide ou expiré. \(raw)"
    }

    private func completePendingOTPAction(email: String) async {
        guard let action = pendingOTPAction else { return }
        pendingOTPAction = nil
        // Wipe any in-memory data from a previous account before loading the new one.
        clearUserData()
        SupabaseRepository.shared.resetUserID()
        await SupabaseRepository.shared.bootstrapAuth()

        switch action {
        case .registerSeller:
            // auth session is now active — safe to write with the real auth.uid()
            _ = await SupabaseRepository.shared.upsertUser(role: "seller", email: email, phone: sellerPhoneNumber)
            _ = await SupabaseRepository.shared.saveSellerProfile(sellerOnboardingDraft)
            hasCompletedSellerOnboarding = true
            isAuthenticated = true
            appStatusMessage = "Profil vendeur vérifié. Bienvenue, \(sellerPublicFirstName) !"
            saveSession()
            Task {
                await SupabaseRepository.shared.logAnalyticsEvent(name: "seller_registered", sessionID: analyticsSessionID)
                await loadUserDataFromSupabase()
            }
        case .registerAgent:
            // auth session is now active — safe to write with the real auth.uid()
            _ = await SupabaseRepository.shared.upsertUser(role: "agent", email: email, phone: agentOnboardingDraft.phoneNumber)
            _ = await SupabaseRepository.shared.saveAgentProfile(agentOnboardingDraft)
            isAuthenticated = true
            hasCompletedAgentProfileOnboarding = true
            resetAgentFeed()
            appStatusMessage = "Profil agent enregistré. Bienvenue sur Store Immo !"
            saveSession()
            Task {
                await SupabaseRepository.shared.logAnalyticsEvent(name: "agent_registered", sessionID: analyticsSessionID)
                await loadUserDataFromSupabase()
            }
        case .loginSeller(let loginEmail):
            // Ensure users row has the real auth.uid() (self-heals stale rows from old registrations)
            _ = await SupabaseRepository.shared.upsertUser(role: "seller", email: loginEmail, phone: sellerPhoneNumber)
            isAuthenticated = true
            hasCompletedSellerOnboarding = true
            if let profile = await SupabaseRepository.shared.fetchSellerProfile(byEmail: loginEmail) {
                sellerProfileFirstName = profile.first_name
                sellerProfileLastName = profile.last_name
                sellerPhoneNumber = profile.phone
            }
            appStatusMessage = "Connexion vendeur réussie."
            saveSession()
            Task {
                await SupabaseRepository.shared.logAnalyticsEvent(name: "seller_logged_in", sessionID: analyticsSessionID)
                await loadUserDataFromSupabase()
            }
        case .loginAgent(let loginEmail):
            // Ensure users row has the real auth.uid() (self-heals stale rows from old registrations)
            _ = await SupabaseRepository.shared.upsertUser(role: "agent", email: loginEmail, phone: nil)
            isAuthenticated = true
            hasCompletedAgentProfileOnboarding = true
            hasChosenAgentSubscription = false  // will be verified from Supabase
            appStatusMessage = "Connexion agent réussie."
            saveSession()
            Task {
                await SupabaseRepository.shared.logAnalyticsEvent(name: "agent_logged_in", sessionID: analyticsSessionID)
                await loadUserDataFromSupabase()
            }
        }
    }

    func selectProject(_ project: PropertyProject) {
        selectedProject = project
        selectedApplication = project.applications.first
        if let mandate = sellerMandates.first(where: { $0.projectID == project.id }) {
            selectedMandate = mandate
        }
    }

    func selectApplication(_ application: AgentApplication) {
        selectedApplication = application
    }

    func chooseAgent(_ application: AgentApplication) {
        print("🔵 CLIC CHOISIR AGENT :", application.agent.fullName)
        
        guard let currentIndex = sellerProjects.firstIndex(where: { $0.id == application.projectID }) else { return }
        let project = sellerProjects[currentIndex]

        // Guard: prevent re-choosing an already chosen agent on this project
        guard !project.applications.contains(where: { $0.id == application.id && $0.status.lowercased() == "chosen" }) else {
            appStatusMessage = "\(application.agent.fullName) est déjà sélectionné pour ce projet."
            return
        }

        // Only write selected_agent_id to Supabase on the first selection
        let isFirstSelection = project.selectedAgentID == nil

        let updatedProject = PropertyProject(
            id: project.id,
            title: project.title,
            fullAddress: project.fullAddress,
            city: project.city,
            postalCode: project.postalCode,
            propertyType: project.propertyType,
            description: project.description,
            desiredPrice: project.desiredPrice,
            idealListingDate: project.idealListingDate,
            extraInformation: project.extraInformation,
            photos: project.photos,
            status: .agentChosen,
            applications: project.applications.map { item in
                if item.id == application.id {
                    return AgentApplication(
                        id: item.id,
                        projectID: item.projectID,
                        agent: item.agent,
                        proposedCommission: item.proposedCommission,
                        customMessage: item.customMessage,
                        status: "chosen",
                        appliedAt: item.appliedAt
                    )
                }
                return item  // Preserve existing "chosen" statuses
            },
            selectedAgentID: isFirstSelection ? application.agent.id : project.selectedAgentID,
            requiredRegion: project.requiredRegion,
            districtLabel: project.districtLabel,
            feedHighlight: project.feedHighlight
        )
        print("🟡 AVANT :", sellerProjects[currentIndex].status)
        sellerProjects[currentIndex] = updatedProject
        
        Task { @MainActor in
            let applicationOK = await SupabaseRepository.shared.updateApplicationStatus(
                applicationID: application.id,
                status: "chosen"
            )
            if isFirstSelection {
                let projectOK = await SupabaseRepository.shared.updateProjectSelectedAgent(
                    projectID: project.id,
                    selectedAgentID: application.agent.id
                )
                print("🔥 PROJECT OK =", projectOK, "APPLICATION OK =", applicationOK)
            } else {
                print("🔥 APPLICATION OK (multi-sélection) =", applicationOK)
            }
            
            // IMPORTANT: Create conversation in Supabase FIRST and get the real ID
            let tentativeID = UUID()
            let finalConvIDStr = await SupabaseRepository.shared.findOrCreateConversation(
                projectID: project.id,
                sellerID: SupabaseRepository.shared.currentUserID,
                agentID: application.agent.id.uuidString.lowercased(),
                newID: tentativeID
            )
            
            guard let finalConvIDStr, let finalConvID = UUID(uuidString: finalConvIDStr) else {
                print("🚨 [chooseAgent] Échec récupération conversation ID depuis Supabase")
                return
            }
            
            print("💬 [chooseAgent] Conversation ID final:", finalConvID.uuidString.prefix(8))
            
            // Notify the chosen agent with the REAL conversation ID
            await SupabaseRepository.shared.createNotificationForUser(
                userID: application.agent.id.uuidString,
                title: "Vous avez été sélectionné",
                body: "Le vendeur vous a choisi pour son projet.",
                type: "agent_chosen",
                relatedProjectId: project.id.uuidString,
                relatedConversationId: finalConvIDStr
            )
            await SupabaseRepository.shared.logAnalyticsEvent(name: "agent_chosen", sessionID: analyticsSessionID)
            
            // NOW create the local conversation with the REAL ID from Supabase
            let sellerUUID = UUID(uuidString: SupabaseRepository.shared.currentUserID)
            let newConversation = Conversation(
                id: finalConvID,
                title: application.agent.fullName,
                subtitle: application.agent.agencyName,
                lastMessagePreview: "Commencez la discussion avec l'agent.",
                unreadCount: 0,
                projectTitle: updatedProject.title,
                messages: [],
                agentId: application.agent.id,
                sellerId: sellerUUID,
                projectId: updatedProject.id,
                participantPhotoURL: application.agent.profilePhotoURL
            )

            conversations.insert(newConversation, at: 0)
            
            print("💬 CONVERSATION CREEE :", newConversation.title)
            print("💬 CONVERSATION ID:", newConversation.id.uuidString.prefix(8))
            print("💬 TOTAL CONVERSATIONS :", conversations.count)
            
            selectedConversation = newConversation
        }
        
        print("🟢 APRES :", sellerProjects[currentIndex].status)
        if let feedIndex = agentOpportunities.firstIndex(where: { $0.id == project.id }) {
            agentOpportunities[feedIndex] = updatedProject
        }

        selectedProject = updatedProject
        selectedApplication = application

        let newMandate = Mandate(
            projectID: updatedProject.id,
            propertyTitle: updatedProject.title,
            status: "Mandat gagné",
            estimatedRange: "\(updatedProject.desiredPrice) €",
            valuationNotice: "Projet attribué à \(application.agent.fullName).",
            digitalMandateName: "Mandat_en_preparation.pdf",
            appointments: [],
            photos: updatedProject.photos
        )

        if !agentMandates.contains(where: { $0.projectID == updatedProject.id }) {
            agentMandates.insert(newMandate, at: 0)
        }
        
        let chosenNotif = NotificationItem(
            title: "Agent retenu",
            body: "Vous avez choisi \(application.agent.fullName) pour \(project.title).",
            symbolName: "checkmark.seal.fill",
            date: .now
        )
        notifications.insert(chosenNotif, at: 0)
        showInAppBanner(chosenNotif)

    }

    func revealPhone() {
        revealPhoneNumber = true
    }

    func updateProject(
        _ project: PropertyProject,
        address: String,
        city: String,
        postalCode: String,
        propertyType: PropertyType,
        typology: PropertyTypology,
        desiredPrice: Int,
        idealListingDate: Date,
        description: String,
        extraInformation: String,
        existingPhotoURLs: [String?] = [],
        newPhotoDatas: [Data?] = []
    ) {
        // Optimistic update: reflect any photo deletions the user made immediately
        let optimisticPhotos = AppViewModel.photoSlotSpecs.enumerated().map { i, spec in
            PhotoAsset(
                systemName: spec.systemName,
                label: spec.label,
                accentName: spec.accentName,
                url: existingPhotoURLs.indices.contains(i) ? existingPhotoURLs[i]
                    : project.photos.indices.contains(i) ? project.photos[i].url : nil
            )
        }
        let updated = PropertyProject(
            id: project.id,
            title: "\(propertyType.rawValue) à \(city)",
            fullAddress: address,
            city: city,
            postalCode: postalCode,
            propertyType: propertyType,
            typology: typology,
            description: description,
            desiredPrice: desiredPrice,
            idealListingDate: idealListingDate,
            extraInformation: extraInformation,
            photos: optimisticPhotos,
            status: project.status,
            applications: project.applications,
            selectedAgentID: project.selectedAgentID,
            requiredRegion: city,
            districtLabel: postalCode,
            feedHighlight: project.feedHighlight,
            sellerID: project.sellerID
        )
        if let idx = sellerProjects.firstIndex(where: { $0.id == project.id }) {
            sellerProjects[idx] = updated
        }
        if let idx = discoverFeedSource.firstIndex(where: { $0.id == project.id }) {
            discoverFeedSource[idx] = updated
        }
        if selectedProject?.id == project.id { selectedProject = updated }
        editingProject = nil

        let pid = project.id
        let dateFormatter: DateFormatter = {
            let f = DateFormatter()
            f.dateFormat = "yyyy-MM-dd"
            f.locale = Locale(identifier: "en_US_POSIX")
            return f
        }()
        Task { @MainActor in
            let ok = await SupabaseRepository.shared.updateSellerProject(
                projectID: pid,
                address: address,
                city: city,
                postalCode: postalCode,
                propertyType: propertyType.rawValue,
                typology: typology.rawValue,
                description: description,
                desiredPrice: desiredPrice,
                idealListingDate: dateFormatter.string(from: idealListingDate)
            )
            if !ok {
                appStatusMessage = SupabaseRepository.shared.lastError ?? "Mise à jour échouée."
            }
            guard newPhotoDatas.contains(where: { $0 != nil }) else { return }
            let urls = await SupabaseRepository.shared.uploadProjectPhotos(
                projectID: pid,
                photoDatas: newPhotoDatas
            )
            // Merge: new upload URL > existing kept URL > nil (user deleted)
            if let idx = sellerProjects.firstIndex(where: { $0.id == pid }) {
                let p = sellerProjects[idx]
                let mergedPhotos = AppViewModel.photoSlotSpecs.enumerated().map { i, spec in
                    let newURL: String? = urls.indices.contains(i) ? urls[i] : nil
                    let keptURL: String? = existingPhotoURLs.indices.contains(i) ? existingPhotoURLs[i] : nil
                    return PhotoAsset(
                        systemName: spec.systemName,
                        label: spec.label,
                        accentName: spec.accentName,
                        url: newURL ?? keptURL
                    )
                }
                let patched = PropertyProject(
                    id: p.id, title: p.title, fullAddress: p.fullAddress,
                    city: p.city, postalCode: p.postalCode,
                    propertyType: p.propertyType, description: p.description,
                    desiredPrice: p.desiredPrice, idealListingDate: p.idealListingDate,
                    extraInformation: p.extraInformation, photos: mergedPhotos,
                    status: p.status, applications: p.applications,
                    selectedAgentID: p.selectedAgentID, requiredRegion: p.requiredRegion,
                    districtLabel: p.districtLabel, feedHighlight: p.feedHighlight,
                    sellerID: p.sellerID
                )
                sellerProjects[idx] = patched
                if selectedProject?.id == pid { selectedProject = patched }
                if let feedIdx = discoverFeedSource.firstIndex(where: { $0.id == pid }) {
                    discoverFeedSource[feedIdx] = patched
                }
            }
        }
    }

    func archiveProject(_ project: PropertyProject) {
        sellerProjects.removeAll { $0.id == project.id }
        discoverFeedSource.removeAll { $0.id == project.id }
        agentOpportunities.removeAll { $0.id == project.id }
        if selectedProject?.id == project.id { selectedProject = sellerProjects.first }
        projectToDelete = nil
        Task {
            let ok = await SupabaseRepository.shared.archiveSellerProject(projectID: project.id)
            if !ok {
                appStatusMessage = SupabaseRepository.shared.lastError ?? "Suppression échouée."
            }
        }
    }

    func sendCurrentMessage(_ text: String) {
        guard let conversation = selectedConversation, 
              !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { 
            return 
        }
        
        // Safety: Don't send messages until Realtime is active
        // This prevents race conditions where message is sent with tentativeID
        // but Realtime is listening to realID
        guard realtimeMessagesTask != nil else {
            print("💬 [SendMessage] ⚠️ Message bloqué — Realtime pas encore actif")
            print("💬 [SendMessage] ⚠️ La conversation est en cours de réconciliation avec Supabase")
            appStatusMessage = "Veuillez patienter quelques instants..."
            return
        }
        
        let senderName = selectedRole == .seller ? sellerPublicFirstName : (currentAgentProfile?.fullName ?? "Agent")

        let message = ChatMessage(
            senderName: senderName,
            senderRole: selectedRole ?? .seller,
            text: text,
            sentAt: .now
        )
        
        // Mise à jour optimiste locale
        let updated = Conversation(
            id: conversation.id,
            title: conversation.title,
            subtitle: conversation.subtitle,
            lastMessagePreview: text,
            unreadCount: 0,
            projectTitle: conversation.projectTitle,
            messages: conversation.messages + [message],
            agentId: conversation.agentId,
            sellerId: conversation.sellerId,
            projectId: conversation.projectId,
            participantPhotoURL: conversation.participantPhotoURL
        )
        replaceConversation(updated)
        
        let convID = conversation.id
        let recipientID: String?
        if selectedRole == .seller {
            recipientID = conversation.agentId?.uuidString
        } else {
            recipientID = conversation.sellerId?.uuidString
        }
        let convIDStr = conversation.id.uuidString
        
        print("💬 [SendMessage] ===== ENVOI MESSAGE =====")
        print("💬 [SendMessage] Message:", text.prefix(50))
        print("💬 [SendMessage] Conversation ID (utilisé pour INSERT):", convIDStr)
        print("💬 [SendMessage] Conversation ID (8 premiers):", convIDStr.prefix(8))
        print("💬 [SendMessage] Sender role:", selectedRole?.rawValue ?? "nil")
        print("💬 [SendMessage] Recipient user_id:", recipientID ?? "nil")
        print("💬 [SendMessage] selectedConversation.id:", selectedConversation?.id.uuidString.prefix(8) ?? "nil")
        print("💬 [SendMessage] Realtime écoute conversation_id:", realtimeMessagesTask == nil ? "❌ PAS ACTIF" : "✅ ACTIF")
        
        Task { @MainActor in
            // 1. D'abord, enregistrer le message dans la table messages
            let ok = await SupabaseRepository.shared.sendMessage(
                conversationID: convID,
                projectID: nil,
                receiverID: recipientID,
                body: text
            )
            
            if !ok {
                print("💬 [SendMessage] ❌ Échec envoi message")
                if let err = SupabaseRepository.shared.lastError {
                    appStatusMessage = "Supabase: \(err)"
                }
                // Rollback optimiste : retirer le message de la conversation
                let rolledBack = Conversation(
                    id: conversation.id,
                    title: conversation.title,
                    subtitle: conversation.subtitle,
                    lastMessagePreview: conversation.lastMessagePreview,
                    unreadCount: conversation.unreadCount,
                    projectTitle: conversation.projectTitle,
                    messages: conversation.messages,
                    agentId: conversation.agentId,
                    sellerId: conversation.sellerId,
                    projectId: conversation.projectId,
                    participantPhotoURL: conversation.participantPhotoURL
                )
                replaceConversation(rolledBack)
                return
            }
            
            print("💬 [SendMessage] ✅ Message enregistré avec succès")
            
            // 2. SEULEMENT si le message a été enregistré, créer la notification
            if let rid = recipientID {
                print("💬 [SendMessage] Création notification pour user:", rid)
                print("💬 [SendMessage] Type: new_message")
                print("💬 [SendMessage] relatedConversationId:", convIDStr)
                
                let notifCreated = await SupabaseRepository.shared.createNotificationForUser(
                    userID: rid,
                    title: "Nouveau message",
                    body: "\(senderName) : \(text.prefix(60))",
                    type: "new_message",
                    relatedProjectId: nil,
                    relatedConversationId: convIDStr
                )
                
                if notifCreated {
                    print("💬 [SendMessage] ✅ Notification créée")
                } else {
                    print("💬 [SendMessage] ⚠️ Notification non créée (mais message OK)")
                }
            } else {
                print("💬 [SendMessage] ❌ Pas de recipientID - notification non créée")
            }
        }
    }

    func submitSellerLead(photoDatas: [Data?] = []) {
        guard !sellerLeadDraft.address.isEmpty, !sellerLeadDraft.city.isEmpty else { return }
        let initialPhotos = AppViewModel.photoSlotSpecs.map { spec in
            PhotoAsset(systemName: spec.systemName, label: spec.label, accentName: spec.accentName)
        }
        let generatedProject = PropertyProject(
            title: "Nouveau projet à \(sellerLeadDraft.city)",
            fullAddress: sellerLeadDraft.address,
            city: sellerLeadDraft.city,
            postalCode: sellerLeadDraft.postalCode,
            propertyType: sellerLeadDraft.propertyType,
            typology: sellerLeadDraft.typology,
            description: sellerLeadDraft.description,
            desiredPrice: Int(sellerLeadDraft.desiredPrice) ?? 480_000,
            idealListingDate: sellerLeadDraft.idealListingDate,
            extraInformation: sellerLeadDraft.extraInformation,
            photos: initialPhotos,
            status: .published,
            applications: [],
            selectedAgentID: nil,
            requiredRegion: sellerLeadDraft.city,
            districtLabel: sellerLeadDraft.postalCode,
            feedHighlight: "Nouveau mandat vendeur"
        )
        sellerProjects.insert(generatedProject, at: 0)
        selectedProject = generatedProject
        let draftCopy = sellerLeadDraft
        let pid = generatedProject.id
        sellerLeadDraft = SellerLeadDraft()
        let publishedNotif = NotificationItem(
            title: "Projet publié",
            body: "Votre bien est désormais visible par les agents de votre zone.",
            symbolName: "house.fill",
            date: .now
        )
        notifications.insert(publishedNotif, at: 0)
        showInAppBanner(publishedNotif)
        let analyticsSessionIDForTask = analyticsSessionID
        Task { @MainActor in
            let userOK = await SupabaseRepository.shared.upsertUser(
                role: "seller",
                email: sellerOnboardingDraft.email,
                phone: sellerPhoneNumber
            )

            print("👤 USER OK AVANT CREATE PROJECT =", userOK)
            print("👤 currentUserID =", SupabaseRepository.shared.currentUserID, "isAuthenticated =", isAuthenticated)

            let ok = await SupabaseRepository.shared.createProject(from: draftCopy, projectID: pid)
            guard ok else {
                if let err = SupabaseRepository.shared.lastError {
                    appStatusMessage = "Supabase: \(err)"
                }
                // Roll back the optimistic insert so the list stays accurate
                sellerProjects.removeAll { $0.id == pid }
                if selectedProject?.id == pid { selectedProject = sellerProjects.first }
                return
            }

            // Upload photos and update photo_url in DB (both happen before the reload)
            if !photoDatas.isEmpty {
                let urls = await SupabaseRepository.shared.uploadProjectPhotos(
                    projectID: pid,
                    photoDatas: photoDatas
                )
                // Patch local copy immediately so the card shows photos during the reload
                if let idx = sellerProjects.firstIndex(where: { $0.id == pid }) {
                    let p = sellerProjects[idx]
                    let updatedPhotos = AppViewModel.photoSlotSpecs.enumerated().map { i, spec in
                        PhotoAsset(
                            systemName: spec.systemName,
                            label: spec.label,
                            accentName: spec.accentName,
                            url: urls.indices.contains(i) ? urls[i] : nil
                        )
                    }
                    let updatedProject = PropertyProject(
                        id: p.id, title: p.title, fullAddress: p.fullAddress,
                        city: p.city, postalCode: p.postalCode,
                        propertyType: p.propertyType, description: p.description,
                        desiredPrice: p.desiredPrice, idealListingDate: p.idealListingDate,
                        extraInformation: p.extraInformation, photos: updatedPhotos,
                        status: p.status, applications: p.applications,
                        selectedAgentID: p.selectedAgentID, requiredRegion: p.requiredRegion,
                        districtLabel: p.districtLabel, feedHighlight: p.feedHighlight,
                        sellerID: p.sellerID
                    )
                    sellerProjects[idx] = updatedProject
                    if selectedProject?.id == pid { selectedProject = updatedProject }
                }
            }

            // Reload ALL seller projects from DB now that the new project (+ photos) are persisted.
            // This prevents a race where a subsequent pull-to-refresh would replace sellerProjects
            // with only the DB rows written before this async write completed.
            await loadSellerProjectsFromSupabase()

            _ = await SupabaseRepository.shared.createNotification(
                title: "Projet publié",
                body: "Votre bien est désormais visible par les agents de votre zone.",
                type: "project_published"
            )
            // Notify agents whose main city matches the project city
            await SupabaseRepository.shared.notifyAgentsInCityForNewProject(
                city: draftCopy.city,
                projectID: pid.uuidString.lowercased()
            )
            await SupabaseRepository.shared.logAnalyticsEvent(name: "project_submitted", sessionID: analyticsSessionIDForTask)
            print("✅ Projet publié et confirmé en DB:", pid)
        }
    }

    func submitAgentApplication(for project: PropertyProject) {
        // Cheapest check first: never allow a duplicate application
        guard !appliedProjectIDs.contains(project.id) else { return }

        if !hasChosenAgentSubscription {
            if freeApplicationUsed {
                showSubscriptionUpgradeSheet = true
                track("subscription_upgrade_prompted")
                return
            }
            freeApplicationUsed = true
            saveSession()
        } else {
            guard applicationsTodayRemaining > 0 else {
                showSubscriptionUpgradeSheet = true
                track("subscription_upgrade_prompted")
                return
            }
        }
        // Build a minimal fallback agent profile if the async load hasn't finished yet.
        // This prevents "Profil introuvable" on fast devices right after login.
        let agentFromDraft = AgentProfile(
            fullName: "\(agentOnboardingDraft.firstName) \(agentOnboardingDraft.lastName)".trimmingCharacters(in: .whitespaces).isEmpty
                ? "Agent"
                : "\(agentOnboardingDraft.firstName) \(agentOnboardingDraft.lastName)",
            agencyName: agentOnboardingDraft.agency.isEmpty ? "Indépendant" : agentOnboardingDraft.agency,
            city: agentOnboardingDraft.city,
            badge: .professionalCard(number: "En cours"),
            bio: "", averageRating: 0, reviewCount: 0, salesLast12Months: 0,
            soldRate: 0, averageSalePrice: 0, averageDelayDays: 0,
            commissionPercent: 4.5, interventionZones: [], reviews: [],
            photoSymbol: "person.crop.circle.fill", plan: .starter
        )
        let firstAgent = currentAgentProfile ?? featuredAgents.first ?? agentFromDraft

        let commission = Double(agentApplicationDraft.commissionText.replacingOccurrences(of: ",", with: ".")) ?? 4.5
        let application = AgentApplication(
            projectID: project.id,
            agent: firstAgent,
            proposedCommission: commission,
            customMessage: agentApplicationDraft.message.isEmpty ? "Je peux lancer un plan de commercialisation premium en 7 jours." : agentApplicationDraft.message,
            appliedAt: .now
        )

        func makeUpdated(from original: PropertyProject) -> PropertyProject {
            var apps = original.applications
            apps.insert(application, at: 0)
            return PropertyProject(
                id: original.id, title: original.title, fullAddress: original.fullAddress,
                city: original.city, postalCode: original.postalCode,
                propertyType: original.propertyType, description: original.description,
                desiredPrice: original.desiredPrice, idealListingDate: original.idealListingDate,
                extraInformation: original.extraInformation, photos: original.photos,
                status: .reviewing, applications: apps,
                selectedAgentID: original.selectedAgentID, requiredRegion: original.requiredRegion,
                districtLabel: original.districtLabel, feedHighlight: original.feedHighlight,
                sellerID: original.sellerID
            )
        }

        // Search in sellerProjects first (demo mode), then discoverFeedSource (Supabase agent mode)
        if let idx = sellerProjects.firstIndex(where: { $0.id == project.id }) {
            guard !sellerProjects[idx].applications.contains(where: { $0.agent.id == firstAgent.id }) else { return }
            let updated = makeUpdated(from: sellerProjects[idx])
            sellerProjects[idx] = updated
            if let oppIdx = agentOpportunities.firstIndex(where: { $0.id == project.id }) { agentOpportunities[oppIdx] = updated }
            selectedProject = updated
        } else if let idx = discoverFeedSource.firstIndex(where: { $0.id == project.id }) {
            guard !discoverFeedSource[idx].applications.contains(where: { $0.agent.id == firstAgent.id }) else { return }
            let updated = makeUpdated(from: discoverFeedSource[idx])
            discoverFeedSource[idx] = updated
            if let oppIdx = agentOpportunities.firstIndex(where: { $0.id == project.id }) { agentOpportunities[oppIdx] = updated }
            selectedProject = updated
        }

        // Mark applied immediately so the button reflects the state while the async write runs.
        appliedProjectIDs.insert(project.id)
        saveSession()
        print("📩 CANDIDATURE en cours d'envoi — project:", project.id)
        let appliedNotif = NotificationItem(
            title: "Candidature envoyée",
            body: "Votre proposition a été envoyée pour \(project.title).",
            symbolName: "paperplane.fill",
            date: .now
        )
        notifications.insert(appliedNotif, at: 0)
        showInAppBanner(appliedNotif)
        let projectID = project.id
        let projectTitle = project.title
        let agentName = firstAgent.fullName
        let isSubscribed = hasChosenAgentSubscription
        let message = application.customMessage
        Task { @MainActor in
            // Ensure we have the real auth.uid() before any Supabase call.
            await SupabaseRepository.shared.bootstrapAuth()

            // Guard against duplicate submissions: if the row already exists in DB,
            // keep the button gray and return silently.
            let alreadyExists = await SupabaseRepository.shared.checkApplicationExists(projectID: projectID)
            if alreadyExists {
                print("ℹ️ Candidature déjà présente en DB — aucun doublon inséré, project:", projectID)
                appliedProjectIDs.insert(projectID)
                saveSession()
                return
            }

            let ok = await SupabaseRepository.shared.createApplication(
                projectID: projectID,
                commission: commission,
                message: message
            )
            if ok {
                print("✅ Candidature confirmée en DB — project:", projectID)
                saveSession()
                _ = await SupabaseRepository.shared.createNotification(
                    title: "Candidature envoyée",
                    body: "Proposition envoyée pour \(projectTitle).",
                    type: "application_sent"
                )
                // Notify the seller about the new application (include agent name)
                if let sellerIDStr = project.sellerID, !sellerIDStr.isEmpty {
                    await SupabaseRepository.shared.createNotificationForUser(
                        userID: sellerIDStr,
                        title: "Nouvelle candidature",
                        body: "\(agentName) vient de candidater à votre projet.",
                        type: "new_application",
                        relatedProjectId: projectID.uuidString,
                        relatedConversationId: nil
                    )
                }
                await SupabaseRepository.shared.logAnalyticsEvent(
                    name: isSubscribed ? "candidature_submitted" : "free_candidature_used",
                    sessionID: analyticsSessionID
                )
            } else {
                // DB write failed — roll back in-memory state so the user can retry.
                appliedProjectIDs.remove(projectID)
                // If we consumed the free slot for this failed attempt, give it back.
                if !isSubscribed {
                    freeApplicationUsed = false
                }
                saveSession()
                appStatusMessage = SupabaseRepository.shared.lastError
                    ?? "Candidature non envoyée. Vérifiez votre connexion et réessayez."
                print("🚨 Candidature annulée (rollback) — project:", projectID)
            }
        }
        agentApplicationDraft = AgentApplicationDraft()
    }

    func selectConversation(_ conversation: Conversation) {
        selectedConversation = conversation
        
        // Start listening for new messages in this conversation
        startMessagesRealtime()
        
        // Reload messages from Supabase to ensure we have the latest
        Task { @MainActor in
            guard SupabaseRepository.shared.isConfigured else { return }
            print("💬 [selectConversation] Rechargement messages depuis Supabase pour:", conversation.id.uuidString.prefix(8))
            
            let msgRows = await SupabaseRepository.shared.fetchMessages(conversationID: conversation.id.uuidString.lowercased())
            
            let isoFormatter = ISO8601DateFormatter()
            let chatMessages = msgRows.map { msg -> ChatMessage in
                let senderIsMe = (msg.sender_id ?? "").lowercased() == SupabaseRepository.shared.currentUserID.lowercased()
                let senderRole: UserRole = senderIsMe
                    ? (selectedRole ?? .seller)
                    : (selectedRole == .seller ? .agent : .seller)
                let senderName: String
                if senderIsMe {
                    senderName = selectedRole == .seller
                        ? sellerPublicFirstName
                        : (currentAgentProfile?.fullName ?? "Agent")
                } else {
                    senderName = conversation.title
                }
                return ChatMessage(
                    id: UUID(uuidString: msg.id) ?? UUID(),
                    senderName: senderName,
                    senderRole: senderRole,
                    text: msg.body,
                    sentAt: msg.created_at.flatMap { isoFormatter.date(from: $0) } ?? Date()
                )
            }

            // Update the conversation with fresh messages
            let updated = Conversation(
                id: conversation.id,
                title: conversation.title,
                subtitle: conversation.subtitle,
                lastMessagePreview: msgRows.last?.body ?? conversation.lastMessagePreview,
                unreadCount: conversation.unreadCount,
                projectTitle: conversation.projectTitle,
                messages: chatMessages,
                agentId: conversation.agentId,
                sellerId: conversation.sellerId,
                projectId: conversation.projectId,
                participantPhotoURL: conversation.participantPhotoURL
            )
            
            replaceConversation(updated)
            print("💬 [selectConversation] Messages rechargés — total:", chatMessages.count)
        }
    }
    
    /// Call this from ConversationView's onAppear to mark the conversation as currently visible.
    /// This prevents in-app notification banners from appearing for messages in this conversation.
    func markConversationAsVisible(_ conversationID: UUID) {
        currentVisibleConversationID = conversationID
        print("👁️ [AppVM] Conversation visible à l'écran:", conversationID.uuidString.prefix(8))
    }
    
    /// Call this from ConversationView's onDisappear to mark that no conversation is currently visible.
    /// This allows in-app notification banners to appear again.
    func markConversationAsHidden() {
        print("👁️ [AppVM] Conversation cachée — bannières réactivées")
        print("👁️ [AppVM]   (était:", currentVisibleConversationID?.uuidString.prefix(8) ?? "nil", ")")
        currentVisibleConversationID = nil
    }

    /// Opens the existing conversation between the seller and this agent for this project,
    /// or creates one (in memory + Supabase) if none exists yet.
    /// Uses findOrCreateConversation to guarantee no duplicates in Supabase.
    func openOrCreateConversation(application: AgentApplication, project: PropertyProject) {
        // 1. Check in-memory cache first (fast path).
        if let existing = conversations.first(where: { conv in
            if let aid = conv.agentId, let pid = conv.projectId {
                return aid == application.agent.id && pid == project.id
            }
            return conv.title == application.agent.fullName && conv.projectTitle == project.title
        }) {
            sellerMessagesNavPath = [existing.id]
            sellerTab = .messages
            selectConversation(existing)  // This will start Realtime and reload messages
            return
        }

        // 2. Not in memory — reconcile with Supabase FIRST, THEN show the conversation.
        let tentativeID = UUID()
        let sellerID = SupabaseRepository.shared.currentUserID
        let agentIDStr = application.agent.id.uuidString.lowercased()

        // Show a placeholder conversation immediately (optimistic UI)
        let newConversation = Conversation(
            id: tentativeID,
            title: application.agent.fullName,
            subtitle: application.agent.agencyName,
            lastMessagePreview: "Commencez la discussion avec l'agent.",
            unreadCount: 0,
            projectTitle: project.title,
            messages: [
                ChatMessage(
                    senderName: sellerPublicFirstName,
                    senderRole: .seller,
                    text: "Commencez la discussion avec l'agent.",
                    sentAt: .now
                )
            ],
            agentId: application.agent.id,
            projectId: project.id,
            participantPhotoURL: application.agent.profilePhotoURL
        )
        conversations.insert(newConversation, at: 0)
        sellerMessagesNavPath = [tentativeID]
        sellerTab = .messages
        
        // IMPORTANT: Do NOT call selectConversation yet!
        // We must wait for Supabase to return the real ID first.
        selectedConversation = newConversation

        // 3. Persist to Supabase and get the real ID (find-or-create prevents any duplicate).
        Task { @MainActor in
            await SupabaseRepository.shared.bootstrapAuth()
            let realIDStr = await SupabaseRepository.shared.findOrCreateConversation(
                projectID: project.id,
                sellerID: sellerID,
                agentID: agentIDStr,
                newID: tentativeID
            )
            
            guard let realIDStr, let realID = UUID(uuidString: realIDStr) else {
                print("🚨 [openOrCreateConversation] Échec récupération conversation ID depuis Supabase")
                return
            }
            
            // If Supabase returned a different (pre-existing) ID, update our in-memory conversation.
            if realID != tentativeID {
                print("💬 [openOrCreateConversation] Conversation existante détectée — mise à jour de tentativeID vers realID")
                print("💬   tentativeID:", tentativeID.uuidString.prefix(8))
                print("💬   realID:", realID.uuidString.prefix(8))
                
                if let idx = conversations.firstIndex(where: { $0.id == tentativeID }) {
                    let fixed = Conversation(
                        id: realID,
                        title: newConversation.title,
                        subtitle: newConversation.subtitle,
                        lastMessagePreview: newConversation.lastMessagePreview,
                        unreadCount: 0,
                        projectTitle: newConversation.projectTitle,
                        messages: newConversation.messages,
                        agentId: newConversation.agentId,
                        projectId: newConversation.projectId,
                        participantPhotoURL: newConversation.participantPhotoURL
                    )
                    conversations[idx] = fixed
                    sellerMessagesNavPath = [realID]
                    // NOW call selectConversation with the real ID from Supabase
                    selectConversation(fixed)
                }
            } else {
                // The tentative ID was accepted by Supabase — it's the real ID now
                print("💬 [openOrCreateConversation] Nouvelle conversation créée avec ID:", realID.uuidString.prefix(8))
                // NOW call selectConversation to start Realtime with the correct ID
                selectConversation(newConversation)
            }
        }
    }

    func selectMandate(_ mandate: Mandate) {
        selectedMandate = mandate
    }

    func resetAgentFeed() {
        discoverFeedPage = 1
        let filteredSource = filteredDiscoverFeedSource()
        agentOpportunities = Array(filteredSource.prefix(discoverFeedPage * discoverFeedPageSize))
        selectedProject = agentOpportunities.first ?? sellerProjects.first
    }

    func loadMoreDiscoverProjectsIfNeeded(currentProject project: PropertyProject) {
        guard project.id == agentOpportunities.last?.id else { return }
        let filteredSource = filteredDiscoverFeedSource()
        guard agentOpportunities.count < filteredSource.count else { return }
        discoverFeedPage += 1
        agentOpportunities = Array(filteredSource.prefix(discoverFeedPage * discoverFeedPageSize))
    }

    func updateAgentLocation(city: String) {
        agentBaseCity = city
        resetAgentFeed()
        saveSession()
    }

    func updateRadiusFilter(to radius: Int) {
        let clampedRadius = discoverRadiusOptions.min(by: { abs($0 - radius) < abs($1 - radius) }) ?? 50
        guard Int(radiusFilter) != clampedRadius else { return }
        radiusFilter = Double(clampedRadius)
        resetAgentFeed()
        saveSession()
    }

    func toggleSavedProject(_ project: PropertyProject) {
        if savedProjectIDs.contains(project.id) {
            savedProjectIDs.remove(project.id)
        } else {
            savedProjectIDs.insert(project.id)
        }
    }

    func isProjectSaved(_ project: PropertyProject) -> Bool {
        savedProjectIDs.contains(project.id)
    }
    
    func hasApplied(to project: PropertyProject) -> Bool {
        appliedProjectIDs.contains(project.id)
    }

    func refreshDiscoverFeed() async -> PropertyProject? {
        isDiscoverFeedRefreshing = true
        defer { isDiscoverFeedRefreshing = false }

        if SupabaseService.shared.isConfigured {
            await loadSellerProjectsFromSupabase()
            return nil
        }

        // Demo mode only
        let freshProject = DemoDataFactory.makeIncomingProject(for: agentBaseCity)
        guard filteredDiscoverFeedSource(for: [freshProject] + discoverFeedSource).contains(where: { $0.id == freshProject.id }) else {
            return nil
        }
        agentOpportunities.insert(freshProject, at: 0)
        sellerProjects.insert(freshProject, at: 0)
        let feedNotif = NotificationItem(
            title: "Nouveau bien dans votre secteur",
            body: "\(freshProject.title) vient d'arriver dans le feed \(agentBaseCity).",
            symbolName: "bell.badge.fill",
            date: .now
        )
        notifications.insert(feedNotif, at: 0)
        showInAppBanner(feedNotif)
        return freshProject
    }

    private func replaceConversation(_ conversation: Conversation) {
        guard let index = conversations.firstIndex(where: { $0.id == conversation.id }) else { return }
        conversations[index] = conversation
        selectedConversation = conversation
    }

    // MARK: - Supabase data loading

    func loadUserDataFromSupabase() async {
        guard SupabaseRepository.shared.isConfigured, isAuthenticated else { return }
        // Load agent profile first so agentBaseCity is set before resetAgentFeed() runs
        if selectedRole == .agent {
            await loadAgentSubscriptionFromSupabase()
            await loadAgentApplicationsFromSupabase()
            await loadAgentProfileFromSupabase()
        }
        await loadSellerProjectsFromSupabase()
        await loadConversationsFromSupabase()
        await loadNotificationsFromSupabase()
        if selectedRole == .seller {
            startApplicationsRealtime()
        }
        startNotificationsRealtime()
    }

    func loadConversationsFromSupabase() async {
        guard SupabaseRepository.shared.isConfigured else { return }
        await SupabaseRepository.shared.bootstrapAuth()

        // Normalize uid once — lowercase, trimmed — to make comparisons robust.
        let uid = SupabaseRepository.shared.currentUserID
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)

        print("💬 LOAD CONV — CURRENT USER ID:", uid)
        print("💬 LOAD CONV — CURRENT USER ROLE:", selectedRole?.rawValue ?? "nil")

        let convRows = await SupabaseRepository.shared.fetchConversationsForUser(userID: uid)

        print("💬 LOAD CONV — ROWS COUNT:", convRows.count)

        // Always clear stale conversations so a previous role's data never bleeds through.
        if convRows.isEmpty {
            conversations = []
            return
        }

        let agentRows = await SupabaseService.shared.fetch(from: "agents_profiles", as: AgentProfileRow.self)
        let sellerIDs = convRows.compactMap { $0.seller_id }
        let sellerRows = sellerIDs.isEmpty ? [] : await SupabaseRepository.shared.fetchSellerProfilesByUserIDs(sellerIDs)

        print("💬 LOAD CONV — agentRows count:", agentRows.count)
        print("💬 LOAD CONV — sellerRows count:", sellerRows.count)

        let isoFormatter = ISO8601DateFormatter()
        var built: [Conversation] = []

        for conv in convRows {
            let convAgentID = (conv.agent_id ?? "").lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            let convSellerID = (conv.seller_id ?? "").lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

            print("💬 CONVERSATION agent_id:", convAgentID)
            print("💬 CONVERSATION seller_id:", convSellerID)

            // Determine role by ID match first; fall back to selectedRole as a tiebreaker.
            let matchesAsAgent = !convAgentID.isEmpty && convAgentID == uid
            let matchesAsSeller = !convSellerID.isEmpty && convSellerID == uid
            // If both or neither match (shouldn't happen), trust selectedRole.
            let currentUserIsAgent: Bool
            if matchesAsAgent && !matchesAsSeller {
                currentUserIsAgent = true
            } else if matchesAsSeller && !matchesAsAgent {
                currentUserIsAgent = false
            } else {
                // Fallback: use selectedRole
                currentUserIsAgent = (selectedRole == .agent)
            }

            print("💬 CONVERSATION currentUserIsAgent:", currentUserIsAgent)

            let title: String
            let subtitle: String
            if currentUserIsAgent {
                // Current user is the agent → show the seller's name.
                let seller = sellerRows.first {
                    $0.user_id.lowercased() == convSellerID
                }
                let computed = seller.map {
                    "\($0.first_name) \($0.last_name)".trimmingCharacters(in: .whitespaces)
                } ?? "Vendeur"
                print("💬 DISPLAY NAME BEFORE: agent branch")
                print("💬 DISPLAY NAME FINAL:", computed)
                title = computed
                subtitle = ""
            } else {
                // Current user is the seller → show the agent's name.
                let agent = agentRows.first {
                    $0.user_id.lowercased() == convAgentID
                }
                let computed = agent.map {
                    "\($0.first_name) \($0.last_name)".trimmingCharacters(in: .whitespaces)
                } ?? "Agent"
                print("💬 DISPLAY NAME BEFORE: seller branch")
                print("💬 DISPLAY NAME FINAL:", computed)
                title = computed
                subtitle = agent?.agency ?? ""
            }

            let msgRows = await SupabaseRepository.shared.fetchMessages(conversationID: conv.id)

            // Count messages sent by the other participant that haven't been read yet.
            let unread = msgRows.filter { msg in
                let senderIsMe = (msg.sender_id ?? "").lowercased() == uid
                return !senderIsMe && !(msg.is_read ?? false)
            }.count

            let projectTitle = (sellerProjects + discoverFeedSource)
                .first { $0.id.uuidString.lowercased() == conv.project_id?.lowercased() }?.title ?? "Projet"

            let chatMessages = msgRows.map { msg -> ChatMessage in
                let senderIsMe = (msg.sender_id ?? "").lowercased() == uid
                let senderRole: UserRole = senderIsMe
                    ? (selectedRole ?? .seller)
                    : (selectedRole == .seller ? .agent : .seller)
                let senderName: String
                if senderIsMe {
                    senderName = selectedRole == .seller
                        ? sellerPublicFirstName
                        : (currentAgentProfile?.fullName ?? "Agent")
                } else {
                    senderName = title
                }
                return ChatMessage(
                    id: UUID(uuidString: msg.id) ?? UUID(),
                    senderName: senderName,
                    senderRole: senderRole,
                    text: msg.body,
                    sentAt: msg.created_at.flatMap { isoFormatter.date(from: $0) } ?? Date()
                )
            }

            // Photo of the OTHER participant:
            // - Seller viewing → show agent's profile photo
            // - Agent viewing → sellers have no profile photo
            let participantPhoto: String? = currentUserIsAgent
                ? nil
                : agentRows.first { $0.user_id.lowercased() == convAgentID }?.profile_photo_url

            built.append(Conversation(
                id: UUID(uuidString: conv.id) ?? UUID(),
                title: title,
                subtitle: subtitle,
                lastMessagePreview: msgRows.last?.body ?? "Démarrez la discussion.",
                unreadCount: unread,
                projectTitle: projectTitle,
                messages: chatMessages,
                agentId: UUID(uuidString: convAgentID),
                sellerId: UUID(uuidString: convSellerID),
                projectId: conv.project_id.flatMap { UUID(uuidString: $0) },
                participantPhotoURL: participantPhoto
            ))
        }

        conversations = built
    }

    func loadNotificationsFromSupabase() async {
        guard SupabaseRepository.shared.isConfigured else { return }
        let rows = await SupabaseRepository.shared.fetchNotifications()
        guard !rows.isEmpty else {
            notifications = []
            return
        }
        let isoFormatter = ISO8601DateFormatter()
        notifications = rows.map { row in
            NotificationItem(
                id: UUID(uuidString: row.id) ?? UUID(),
                title: row.title,
                body: row.body,
                symbolName: notificationSymbol(for: row.type),
                date: row.created_at.flatMap { isoFormatter.date(from: $0) } ?? Date(),
                type: row.type,
                isRead: row.is_read,
                relatedProjectId: row.related_project_id.flatMap { UUID(uuidString: $0) },
                relatedConversationId: row.related_conversation_id.flatMap { UUID(uuidString: $0) }
            )
        }
    }

    func markConversationAsRead(_ conversation: Conversation) {
        guard let idx = conversations.firstIndex(where: { $0.id == conversation.id }),
              conversations[idx].unreadCount > 0 else { return }
        let c = conversations[idx]
        conversations[idx] = Conversation(
            id: c.id, title: c.title, subtitle: c.subtitle,
            lastMessagePreview: c.lastMessagePreview, unreadCount: 0,
            projectTitle: c.projectTitle, messages: c.messages,
            agentId: c.agentId, sellerId: c.sellerId, projectId: c.projectId,
            participantPhotoURL: c.participantPhotoURL
        )
        let convID = conversation.id
        Task {
            await SupabaseRepository.shared.markMessagesRead(conversationID: convID)
        }
    }

    func markNotificationRead(_ notification: NotificationItem) {
        guard !notification.isRead,
              let idx = notifications.firstIndex(where: { $0.id == notification.id }) else { return }
        let n = notifications[idx]
        notifications[idx] = NotificationItem(
            id: n.id, title: n.title, body: n.body,
            symbolName: n.symbolName, date: n.date,
            type: n.type, isRead: true,
            relatedProjectId: n.relatedProjectId,
            relatedConversationId: n.relatedConversationId
        )
        let nid = notification.id
        Task {
            await SupabaseRepository.shared.markNotificationRead(id: nid.uuidString)
        }
    }

    func openFromNotification(_ notification: NotificationItem) {
        markNotificationRead(notification)
        switch notification.type {
        case "new_application":
            if let pid = notification.relatedProjectId,
               let project = sellerProjects.first(where: { $0.id == pid }) {
                selectedProject = project
                sellerTab = .dashboard
            }
        case "agent_chosen", "new_message":
            if let cid = notification.relatedConversationId {
                // Try to find the conversation locally first
                if let conv = conversations.first(where: { $0.id == cid }) {
                    selectConversation(conv)  // This will start Realtime and reload messages
                    if selectedRole == .agent {
                        agentMessagesNavPath = [conv.id]
                        agentTab = .messages
                    } else {
                        sellerMessagesNavPath = [conv.id]
                        sellerTab = .messages
                    }
                } else {
                    // Conversation not in memory — load from Supabase
                    print("💬 [openFromNotification] Conversation non trouvée localement — rechargement depuis Supabase")
                    print("💬 [openFromNotification] Conversation ID recherché:", cid.uuidString.prefix(8))
                    Task { @MainActor in
                        await loadConversationsFromSupabase()
                        // Try again after reload
                        if let conv = conversations.first(where: { $0.id == cid }) {
                            print("💬 [openFromNotification] ✅ Conversation trouvée après rechargement")
                            selectConversation(conv)
                            if selectedRole == .agent {
                                agentMessagesNavPath = [conv.id]
                                agentTab = .messages
                            } else {
                                sellerMessagesNavPath = [conv.id]
                                sellerTab = .messages
                            }
                        } else {
                            print("💬 [openFromNotification] ❌ Conversation toujours introuvable après rechargement")
                        }
                    }
                }
            }
        case "new_project":
            // Navigate agent to the discover feed
            agentTab = .discover
            if let pid = notification.relatedProjectId,
               let project = (discoverFeedSource + agentOpportunities).first(where: { $0.id == pid }) {
                selectedProject = project
            }
        default:
            break
        }
    }

    // MARK: - Application seen tracking

    func markApplicationSeenBySeller(_ application: AgentApplication, inProject project: PropertyProject) {
        guard !application.sellerHasSeen else { return }
        rebuildProject(project.id) { apps in
            apps.map { app in
                guard app.id == application.id else { return app }
                return AgentApplication(id: app.id, projectID: app.projectID, agent: app.agent,
                    proposedCommission: app.proposedCommission, customMessage: app.customMessage,
                    status: app.status, appliedAt: app.appliedAt, sellerHasSeen: true)
            }
        }
        let appID = application.id
        Task { await SupabaseRepository.shared.markApplicationSeenBySeller(applicationID: appID) }
    }

    func markAllApplicationsSeenForProject(_ project: PropertyProject) {
        let unseenIDs = project.applications.filter { !$0.sellerHasSeen }.map(\.id)
        guard !unseenIDs.isEmpty else { return }
        rebuildProject(project.id) { apps in
            apps.map { app in
                guard !app.sellerHasSeen else { return app }
                return AgentApplication(id: app.id, projectID: app.projectID, agent: app.agent,
                    proposedCommission: app.proposedCommission, customMessage: app.customMessage,
                    status: app.status, appliedAt: app.appliedAt, sellerHasSeen: true)
            }
        }
        for id in unseenIDs {
            Task { await SupabaseRepository.shared.markApplicationSeenBySeller(applicationID: id) }
        }
    }

    private func rebuildProject(_ projectID: UUID, transformApps: ([AgentApplication]) -> [AgentApplication]) {
        guard let idx = sellerProjects.firstIndex(where: { $0.id == projectID }) else { return }
        let old = sellerProjects[idx]
        sellerProjects[idx] = PropertyProject(
            id: old.id, title: old.title, fullAddress: old.fullAddress,
            city: old.city, postalCode: old.postalCode, propertyType: old.propertyType,
            typology: old.typology, description: old.description, desiredPrice: old.desiredPrice,
            idealListingDate: old.idealListingDate, extraInformation: old.extraInformation,
            photos: old.photos, status: old.status,
            applications: transformApps(old.applications),
            selectedAgentID: old.selectedAgentID, requiredRegion: old.requiredRegion,
            districtLabel: old.districtLabel, feedHighlight: old.feedHighlight, sellerID: old.sellerID
        )
    }

    // MARK: - Real-time applications subscription

    func startApplicationsRealtime() {
        guard selectedRole == .seller, SupabaseRepository.shared.isConfigured else { return }
        let projectIDs = sellerProjects.map { $0.id.uuidString.lowercased() }
        guard !projectIDs.isEmpty else { return }
        stopApplicationsRealtime()
        realtimeApplicationTask = SupabaseRepository.shared.startApplicationsRealtime(
            projectIDs: projectIDs,
            onNewApplication: { [weak self] in
                await self?.onNewApplicationReceived()
            }
        )
    }

    func stopApplicationsRealtime() {
        realtimeApplicationTask?.cancel()
        realtimeApplicationTask = nil
    }

    @MainActor
    private func onNewApplicationReceived() async {
        await loadSellerProjectsFromSupabase()
    }

    // MARK: - Real-time messages subscription

    /// Starts listening for new messages in the currently open conversation.
    /// Call this whenever selectedConversation changes.
    func startMessagesRealtime() {
        guard let conv = selectedConversation, SupabaseRepository.shared.isConfigured else { return }
        stopMessagesRealtime()
        let convID = conv.id.uuidString.lowercased()
        print("💬 [AppVM] ===== DÉMARRAGE REALTIME MESSAGES =====")
        print("💬 [AppVM] Conversation ID (complet):", convID)
        print("💬 [AppVM] Conversation ID (8 premiers):", convID.prefix(8))
        print("💬 [AppVM] Conversation title:", conv.title)
        realtimeMessagesTask = SupabaseRepository.shared.startMessagesRealtime(
            conversationID: convID,
            onNewMessage: { [weak self] in
                await self?.onNewMessageReceived()
            }
        )
    }

    func stopMessagesRealtime() {
        realtimeMessagesTask?.cancel()
        realtimeMessagesTask = nil
    }

    @MainActor
    private func onNewMessageReceived() async {
        guard let conv = selectedConversation else { return }
        print("💬 [AppVM] onNewMessageReceived — rechargement messages pour conversation:", conv.id.uuidString.prefix(8))
        
        // Reload messages from Supabase
        let msgRows = await SupabaseRepository.shared.fetchMessages(conversationID: conv.id.uuidString.lowercased())
        
        let isoFormatter = ISO8601DateFormatter()
        let chatMessages = msgRows.map { msg -> ChatMessage in
            let senderIsMe = (msg.sender_id ?? "").lowercased() == SupabaseRepository.shared.currentUserID.lowercased()
            let senderRole: UserRole = senderIsMe
                ? (selectedRole ?? .seller)
                : (selectedRole == .seller ? .agent : .seller)
            let senderName: String
            if senderIsMe {
                senderName = selectedRole == .seller
                    ? sellerPublicFirstName
                    : (currentAgentProfile?.fullName ?? "Agent")
            } else {
                senderName = conv.title
            }
            return ChatMessage(
                id: UUID(uuidString: msg.id) ?? UUID(),
                senderName: senderName,
                senderRole: senderRole,
                text: msg.body,
                sentAt: msg.created_at.flatMap { isoFormatter.date(from: $0) } ?? Date()
            )
        }

        // Update the conversation in memory
        let updated = Conversation(
            id: conv.id,
            title: conv.title,
            subtitle: conv.subtitle,
            lastMessagePreview: msgRows.last?.body ?? conv.lastMessagePreview,
            unreadCount: conv.unreadCount,
            projectTitle: conv.projectTitle,
            messages: chatMessages,
            agentId: conv.agentId,
            sellerId: conv.sellerId,
            projectId: conv.projectId,
            participantPhotoURL: conv.participantPhotoURL
        )
        
        replaceConversation(updated)
        print("💬 [AppVM] Messages rechargés — total:", chatMessages.count)
    }

    private func notificationSymbol(for type: String) -> String {
        switch type {
        case "application_sent": return "paperplane.fill"
        case "project_published": return "house.fill"
        case "agent_chosen": return "checkmark.seal.fill"
        case "new_message": return "message.badge.fill"
        case "new_application": return "bell.badge.fill"
        case "new_project": return "house.fill"
        default: return "bell.badge.fill"
        }
    }

    // MARK: - In-app notification banner

    private func showInAppBanner(_ notification: NotificationItem) {
        print("🔔 [showInAppBanner] Affichage bannière:")
        print("🔔   - ID:", notification.id)
        print("🔔   - Type:", notification.type)
        print("🔔   - Title:", notification.title)
        print("🔔   - Body:", notification.body)
        
        inAppBanner = notification
        let notifID = notification.id
        Task { [weak self] in
            try? await Task.sleep(nanoseconds: 4_000_000_000)
            guard let self else { return }
            if inAppBanner?.id == notifID {
                print("🔔 [showInAppBanner] Auto-masquage bannière après 4s")
                inAppBanner = nil
            }
        }
    }

    func startNotificationsRealtime() {
        guard SupabaseRepository.shared.isConfigured else { return }
        stopNotificationsRealtime()
        let userID = SupabaseRepository.shared.currentUserID
        
        print("🔔 [startNotificationsRealtime] Démarrage abonnement pour user:", userID)
        
        realtimeNotificationTask = SupabaseRepository.shared.startNotificationsRealtime(
            userID: userID,
            onNew: { [weak self] in
                await self?.onNewNotificationReceived()
            }
        )
    }

    func stopNotificationsRealtime() {
        realtimeNotificationTask?.cancel()
        realtimeNotificationTask = nil
    }

    @MainActor
    private func onNewNotificationReceived() async {
        print("🔔 [AppVM] onNewNotificationReceived appelé")
        let previousIDs = Set(notifications.map { $0.id })
        print("🔔 [AppVM] Notifications avant rechargement:", previousIDs.count)
        
        await loadNotificationsFromSupabase()
        
        print("🔔 [AppVM] Notifications après rechargement:", notifications.count)
        
        if let newNotif = notifications.first(where: {
            !previousIDs.contains($0.id) && !selfNotificationTypes.contains($0.type)
        }) {
            print("🔔 [AppVM] ===== NOUVELLE NOTIFICATION DÉTECTÉE =====")
            print("🔔 [AppVM] ID:", newNotif.id)
            print("🔔 [AppVM] Type:", newNotif.type)
            print("🔔 [AppVM] Title:", newNotif.title)
            print("🔔 [AppVM] relatedConversationId:", newNotif.relatedConversationId?.uuidString.prefix(8) ?? "nil")
            
            // LOGS DIAGNOSTIQUES DÉTAILLÉS
            print("🔔 [AppVM] ===== ÉTAT DES VARIABLES =====")
            print("🔔 [AppVM] selectedConversation:", selectedConversation?.id.uuidString.prefix(8) ?? "nil")
            print("🔔 [AppVM] currentVisibleConversationID:", currentVisibleConversationID?.uuidString.prefix(8) ?? "nil")
            
            // Décision d'affichage de la bannière
            let isConversationVisible: Bool
            let shouldShowBanner: Bool
            
            if newNotif.type == "new_message",
               let notifConvID = newNotif.relatedConversationId,
               let visibleConvID = currentVisibleConversationID,
               notifConvID == visibleConvID {
                // L'utilisateur regarde actuellement cette conversation → pas de bannière
                isConversationVisible = true
                shouldShowBanner = false
                print("🔔 [AppVM] isConversationVisible: true")
                print("🔔 [AppVM] shouldShowBanner: false")
                print("🔔 [AppVM] currentVisibleConversationID:", visibleConvID.uuidString.prefix(8))
                print("🔔 [AppVM] notification relatedConversationId:", notifConvID.uuidString.prefix(8))
                print("🔔 [AppVM] ❌ Bannière ignorée (utilisateur regarde cette conversation)")
            } else {
                // Tous les autres cas → afficher la bannière
                isConversationVisible = false
                shouldShowBanner = true
                print("🔔 [AppVM] isConversationVisible: false")
                print("🔔 [AppVM] shouldShowBanner: true")
                print("🔔 [AppVM] currentVisibleConversationID:", currentVisibleConversationID?.uuidString.prefix(8) ?? "nil")
                print("🔔 [AppVM] notification relatedConversationId:", newNotif.relatedConversationId?.uuidString.prefix(8) ?? "nil")
                print("🔔 [AppVM] ✅ Affichage bannière")
            }
            
            print("🔔 [AppVM] ===== RÉSUMÉ DÉCISION =====")
            print("🔔 [AppVM] Type notification:", newNotif.type)
            print("🔔 [AppVM] selectedConversation:", selectedConversation?.id.uuidString.prefix(8) ?? "nil")
            print("🔔 [AppVM] currentVisibleConversationID:", currentVisibleConversationID?.uuidString.prefix(8) ?? "nil")
            print("🔔 [AppVM] isConversationVisible:", isConversationVisible)
            print("🔔 [AppVM] shouldShowBanner:", shouldShowBanner)
            
            if shouldShowBanner {
                showInAppBanner(newNotif)
            }
        } else {
            print("🔔 [AppVM] ❌ Aucune nouvelle notification à afficher")
            print("🔔 [AppVM]   - Raison: notification self-type ou déjà vue")
        }
    }

    func loadAgentSubscriptionFromSupabase() async {
        guard SupabaseRepository.shared.isConfigured else { return }
        let agentID = SupabaseRepository.shared.currentUserID
        guard let sub = await SupabaseRepository.shared.fetchActiveSubscription(agentID: agentID) else { return }
        if let plan = SubscriptionPlan(rawValue: sub.plan) {
            selectedPlan = plan
            hasChosenAgentSubscription = true
            saveSession()
        }
    }

    func loadAgentProfileFromSupabase() async {
        guard SupabaseRepository.shared.isConfigured else { return }
        let agentID = SupabaseRepository.shared.currentUserID
        guard let row = await SupabaseRepository.shared.fetchAgentProfile(agentID: agentID) else {
            if currentAgentProfile == nil {
                appStatusMessage = "Profil agent introuvable. Vérifiez votre inscription."
            }
            return
        }
        currentAgentProfile = AgentProfile(
            id: UUID(uuidString: row.user_id) ?? UUID(),
            fullName: "\(row.first_name) \(row.last_name)",
            agencyName: row.agency ?? "Indépendant",
            city: row.city,
            badge: .professionalCard(number: "Vérifié"),
            bio: row.description ?? "Agent immobilier vérifié sur Store Immo.",
            averageRating: 0, reviewCount: 0, salesLast12Months: 0,
            soldRate: 0, averageSalePrice: 0, averageDelayDays: 0,
            commissionPercent: 4.5,
            interventionZones: [CityZone(city: row.city, region: row.city, radiusKilometers: Int(radiusFilter))],
            reviews: [],
            photoSymbol: "person.crop.circle.fill",
            plan: selectedPlan,
            memberSinceDate: row.created_at.flatMap { ISO8601DateFormatter().date(from: $0) },
            profilePhotoURL: row.profile_photo_url
        )
        agentBaseCity = row.city
    }

    func uploadAndSaveAgentProfilePhoto(_ data: Data) async {
        print("[Photo profil] Upload démarré")
        let agentID = SupabaseRepository.shared.currentUserID
        guard let urlString = await SupabaseRepository.shared.uploadAgentProfilePhoto(data, agentID: agentID) else {
            print("[Photo profil] Erreur: upload échoué")
            return
        }
        print("[Photo profil] URL enregistrée:", urlString)
        currentAgentProfile = currentAgentProfile.map { profile in
            AgentProfile(
                id: profile.id,
                fullName: profile.fullName,
                agencyName: profile.agencyName,
                city: profile.city,
                badge: profile.badge,
                bio: profile.bio,
                averageRating: profile.averageRating,
                reviewCount: profile.reviewCount,
                salesLast12Months: profile.salesLast12Months,
                soldRate: profile.soldRate,
                averageSalePrice: profile.averageSalePrice,
                averageDelayDays: profile.averageDelayDays,
                commissionPercent: profile.commissionPercent,
                interventionZones: profile.interventionZones,
                reviews: profile.reviews,
                photoSymbol: profile.photoSymbol,
                plan: profile.plan,
                memberSinceDate: profile.memberSinceDate,
                profilePhotoURL: urlString
            )
        }
        print("[Photo profil] Mise à jour réussie")
    }

    func removeAgentProfilePhoto() async {
        print("[Photo profil] Suppression démarrée")
        let agentID = SupabaseRepository.shared.currentUserID
        await SupabaseRepository.shared.updateAgentProfilePhotoURL(nil, agentID: agentID)
        currentAgentProfile = currentAgentProfile.map { profile in
            AgentProfile(
                id: profile.id,
                fullName: profile.fullName,
                agencyName: profile.agencyName,
                city: profile.city,
                badge: profile.badge,
                bio: profile.bio,
                averageRating: profile.averageRating,
                reviewCount: profile.reviewCount,
                salesLast12Months: profile.salesLast12Months,
                soldRate: profile.soldRate,
                averageSalePrice: profile.averageSalePrice,
                averageDelayDays: profile.averageDelayDays,
                commissionPercent: profile.commissionPercent,
                interventionZones: profile.interventionZones,
                reviews: profile.reviews,
                photoSymbol: profile.photoSymbol,
                plan: profile.plan,
                memberSinceDate: profile.memberSinceDate,
                profilePhotoURL: nil
            )
        }
        print("[Photo profil] Suppression réussie")
    }

    func loadAgentApplicationsFromSupabase() async {
        guard SupabaseRepository.shared.isConfigured else { return }
        await SupabaseRepository.shared.bootstrapAuth()
        let agentID = SupabaseRepository.shared.currentUserID
        let rows = await SupabaseRepository.shared.fetchAgentApplications(agentID: agentID)
        let ids = Set(rows.compactMap { UUID(uuidString: $0.project_id) })
        if !ids.isEmpty {
            appliedProjectIDs = appliedProjectIDs.union(ids)
            if !freeApplicationUsed {
                freeApplicationUsed = true
                saveSession()
            }
        }
    }

    private func filteredDiscoverFeedSource() -> [PropertyProject] {
        filteredDiscoverFeedSource(for: discoverFeedSource)
    }

    private func filteredDiscoverFeedSource(for source: [PropertyProject]) -> [PropertyProject] {
        if radiusFilter == 0 {
            return source.sorted { distanceToProject($0) < distanceToProject($1) }
        }
        return source
            .filter { distanceToProject($0) <= Int(radiusFilter) }
            .sorted { distanceToProject($0) < distanceToProject($1) }
    }

    // MARK: - Session persistence

    private func loadPersistedSession() {
        let d = UserDefaults.standard
        isAuthenticated = d.bool(forKey: "si_isAuthenticated")
        // selectedRole is intentionally NOT restored: the app always starts on RoleSelectionView.
        // When the user taps Vendeur or Agent, chooseRole() navigates to the right dashboard.
        hasCompletedSellerOnboarding = d.bool(forKey: "si_hasCompletedSellerOnboarding")
        hasCompletedAgentProfileOnboarding = d.bool(forKey: "si_hasCompletedAgentProfileOnboarding")
        hasChosenAgentSubscription = d.bool(forKey: "si_hasChosenAgentSubscription")
        if let raw = d.string(forKey: "si_selectedPlan"), let plan = SubscriptionPlan(rawValue: raw) { selectedPlan = plan }
        if let raw = d.string(forKey: "si_pendingPlan"), let plan = SubscriptionPlan(rawValue: raw) { pendingPlan = plan }
        agentBaseCity = d.string(forKey: "si_agentBaseCity") ?? "Paris"
        let r = d.double(forKey: "si_radiusFilter")
        let raw = r == 0 ? 50 : Int(r)
        let clamped = discoverRadiusOptions.min(by: { abs($0 - raw) < abs($1 - raw) }) ?? 50
        radiusFilter = Double(clamped)
        sellerProfileFirstName = d.string(forKey: "si_sellerFirstName") ?? ""
        sellerProfileLastName = d.string(forKey: "si_sellerLastName") ?? ""
        sellerPhoneNumber = d.string(forKey: "si_sellerPhone") ?? ""
        freeApplicationUsed = d.bool(forKey: "si_freeApplicationUsed")
        if let rawIDs = d.stringArray(forKey: "si_appliedProjectIDs") {
            appliedProjectIDs = Set(rawIDs.compactMap { UUID(uuidString: $0) })
        }
    }

    func saveSession() {
        let d = UserDefaults.standard
        d.set(isAuthenticated, forKey: "si_isAuthenticated")
        d.set(selectedRole?.rawValue, forKey: "si_selectedRole")
        d.set(hasCompletedSellerOnboarding, forKey: "si_hasCompletedSellerOnboarding")
        d.set(hasCompletedAgentProfileOnboarding, forKey: "si_hasCompletedAgentProfileOnboarding")
        d.set(hasChosenAgentSubscription, forKey: "si_hasChosenAgentSubscription")
        d.set(selectedPlan.rawValue, forKey: "si_selectedPlan")
        d.set(pendingPlan?.rawValue, forKey: "si_pendingPlan")
        d.set(agentBaseCity, forKey: "si_agentBaseCity")
        d.set(radiusFilter, forKey: "si_radiusFilter")
        d.set(sellerProfileFirstName, forKey: "si_sellerFirstName")
        d.set(sellerProfileLastName, forKey: "si_sellerLastName")
        d.set(sellerPhoneNumber, forKey: "si_sellerPhone")
        d.set(freeApplicationUsed, forKey: "si_freeApplicationUsed")
        d.set(appliedProjectIDs.map { $0.uuidString }, forKey: "si_appliedProjectIDs")
    }

    private func clearPersistedSession() {
        let keys = ["si_isAuthenticated", "si_selectedRole", "si_hasCompletedSellerOnboarding",
                    "si_hasCompletedAgentProfileOnboarding", "si_hasChosenAgentSubscription",
                    "si_selectedPlan", "si_pendingPlan", "si_sellerFirstName", "si_sellerLastName", "si_sellerPhone",
                    "si_freeApplicationUsed", "si_appliedProjectIDs"]
        keys.forEach { UserDefaults.standard.removeObject(forKey: $0) }
        // Keep si_agentBaseCity and si_radiusFilter across sign-outs
    }

    private static let cityCoordinates: [String: (lat: Double, lon: Double)] = [
        "paris": (48.8566, 2.3522),
        "marseille": (43.2965, 5.3698),
        "lyon": (45.7578, 4.8320),
        "toulouse": (43.6047, 1.4442),
        "nice": (43.7102, 7.2620),
        "nantes": (47.2184, -1.5536),
        "montpellier": (43.6108, 3.8767),
        "strasbourg": (48.5734, 7.7521),
        "bordeaux": (44.8378, -0.5792),
        "lille": (50.6292, 3.0573),
        "rennes": (48.1173, -1.6778),
        "reims": (49.2583, 4.0317),
        "toulon": (43.1242, 5.9280),
        "le havre": (49.4944, 0.1079),
        "saint-etienne": (45.4397, 4.3872),
        "grenoble": (45.1885, 5.7245),
        "dijon": (47.3220, 5.0415),
        "angers": (47.4784, -0.5632),
        "nimes": (43.8374, 4.3601),
        "clermont-ferrand": (45.7772, 3.0870),
        "metz": (49.1193, 6.1757),
        "nancy": (48.6921, 6.1844),
        "brest": (48.3904, -4.4861),
        "perpignan": (42.6887, 2.8948),
        "orleans": (47.9029, 1.9039),
        "tours": (47.3941, 0.6848),
        "limoges": (45.8336, 1.2611),
        "amiens": (49.8941, 2.2958),
        "annecy": (45.8992, 6.1294),
        "bayonne": (43.4923, -1.4748),
        "pau": (43.2951, -0.3708),
        "avignon": (43.9493, 4.8055),
        "ajaccio": (41.9267, 8.7369),
        "bastia": (42.7025, 9.4502),
        "rouen": (49.4432, 1.0993),
        "caen": (49.1829, -0.3707),
        "besancon": (47.2378, 6.0241),
        "poitiers": (46.5802, 0.3404),
        "la rochelle": (46.1591, -1.1520),
        "cannes": (43.5528, 7.0174),
        "aix-en-provence": (43.5297, 5.4474),
        "mulhouse": (47.7508, 7.3359),
        "valenciennes": (50.3574, 3.5238),
        "dunkerque": (51.0343, 2.3770),
        "troyes": (48.2997, 4.0794),
        "libourne": (44.9186, -0.2431),
        "biarritz": (43.4800, -1.5586),
    ]

    private func haversineDistance(lat1: Double, lon1: Double, lat2: Double, lon2: Double) -> Double {
        let R = 6371.0
        let dLat = (lat2 - lat1) * .pi / 180
        let dLon = (lon2 - lon1) * .pi / 180
        let a = sin(dLat / 2) * sin(dLat / 2) +
                cos(lat1 * .pi / 180) * cos(lat2 * .pi / 180) *
                sin(dLon / 2) * sin(dLon / 2)
        return R * 2 * atan2(sqrt(a), sqrt(1 - a))
    }

    private func distanceToProject(_ project: PropertyProject) -> Int {
        let baseCity = normalizedLocation(agentBaseCity)
        let projectCity = normalizedLocation(project.city)
        let district = normalizedLocation(project.districtLabel)

        if projectCity == baseCity || district.contains(baseCity) {
            return 5
        }

        if let agentCoords = Self.cityCoordinates[baseCity],
           let projectCoords = Self.cityCoordinates[projectCity] {
            return Int(haversineDistance(
                lat1: agentCoords.lat, lon1: agentCoords.lon,
                lat2: projectCoords.lat, lon2: projectCoords.lon
            ))
        }

        // City not in local dict: treat as France-wide (visible at 250km and France, not at smaller radii)
        return 250
    }

    private func normalizedLocation(_ value: String) -> String {
        value
            .folding(options: .diacriticInsensitive, locale: .current)
            .lowercased()
    }

    private func track(_ event: String) {
        let sid = analyticsSessionID
        Task {
            await SupabaseRepository.shared.logAnalyticsEvent(name: event, sessionID: sid)
        }
    }
}

nonisolated struct DemoDataFactory {
    let projects: [PropertyProject]
    let feedProjects: [PropertyProject]
    let sellerMandates: [Mandate]
    let agentMandates: [Mandate]
    let conversations: [Conversation]
    let notifications: [NotificationItem]

    static func make() -> DemoDataFactory {
        let zonesA = [
            CityZone(city: "Paris 17e", region: "Île-de-France", radiusKilometers: 15),
            CityZone(city: "Neuilly-sur-Seine", region: "Île-de-France", radiusKilometers: 18),
            CityZone(city: "Boulogne-Billancourt", region: "Île-de-France", radiusKilometers: 20)
        ]
        let zonesB = [
            CityZone(city: "Bordeaux Centre", region: "Nouvelle-Aquitaine", radiusKilometers: 30),
            CityZone(city: "Arcachon", region: "Nouvelle-Aquitaine", radiusKilometers: 35)
        ]
        let zonesC = [
            CityZone(city: "Lyon 6e", region: "Auvergne-Rhône-Alpes", radiusKilometers: 22),
            CityZone(city: "Villeurbanne", region: "Auvergne-Rhône-Alpes", radiusKilometers: 18)
        ]

        let reviewsA = [
            Review(author: "Claire M.", rating: 5.0, comment: "Pilotage très haut de gamme, reporting impeccable et vente signée en 19 jours.", outcomeTag: "Bien vendu", date: .now.addingTimeInterval(-86400 * 20)),
            Review(author: "Julien D.", rating: 4.8, comment: "Excellente stratégie de mise en marché, très rassurant du début à la signature.", outcomeTag: "Bien vendu", date: .now.addingTimeInterval(-86400 * 63))
        ]
        let reviewsB = [
            Review(author: "Sophie T.", rating: 4.9, comment: "Très bon sens commercial et estimations précises.", outcomeTag: "Bien vendu", date: .now.addingTimeInterval(-86400 * 42)),
            Review(author: "Marc V.", rating: 4.7, comment: "Disponible, professionnel, réseau local efficace.", outcomeTag: "Bien vendu", date: .now.addingTimeInterval(-86400 * 76))
        ]
        let reviewsC = [
            Review(author: "Nadia L.", rating: 4.6, comment: "Bonne communication, très bon suivi des visites.", outcomeTag: "Bien vendu", date: .now.addingTimeInterval(-86400 * 51))
        ]

        let agentA = AgentProfile(
            fullName: "Alexandre Morel",
            agencyName: "Maison Vendôme",
            city: "Paris",
            badge: .professionalCard(number: "CPI 7501 2025 000 112 450"),
            bio: "Ancien notaire conseil, j'accompagne les vendeurs premium avec une stratégie très éditoriale et des acquéreurs qualifiés.",
            averageRating: 4.9,
            reviewCount: 48,
            salesLast12Months: 31,
            soldRate: 88,
            averageSalePrice: 824_000,
            averageDelayDays: 37,
            commissionPercent: 4.2,
            interventionZones: zonesA,
            reviews: reviewsA,
            photoSymbol: "person.crop.square.fill",
            plan: .elite
        )

        let agentB = AgentProfile(
            fullName: "Inès Faure",
            agencyName: "Réseau Héritage",
            city: "Bordeaux",
            badge: .mandate(network: "Orpi", number: "M-NAQ-2049"),
            bio: "Spécialiste des maisons familiales en Gironde, avec un fort maillage local et une approche très transparente.",
            averageRating: 4.8,
            reviewCount: 32,
            salesLast12Months: 22,
            soldRate: 84,
            averageSalePrice: 463_000,
            averageDelayDays: 44,
            commissionPercent: 4.5,
            interventionZones: zonesB,
            reviews: reviewsB,
            photoSymbol: "person.crop.circle.badge.checkmark",
            plan: .pro
        )

        let agentC = AgentProfile(
            fullName: "Romain Costa",
            agencyName: "Century 21 Signature",
            city: "Lyon",
            badge: .professionalCard(number: "CPI 6902 2024 000 094 103"),
            bio: "Mandats exclusifs, visites qualifiées et suivi vendeur très rigoureux sur Lyon intra-muros.",
            averageRating: 4.7,
            reviewCount: 27,
            salesLast12Months: 18,
            soldRate: 79,
            averageSalePrice: 518_000,
            averageDelayDays: 41,
            commissionPercent: 4.1,
            interventionZones: zonesC,
            reviews: reviewsC,
            photoSymbol: "person.crop.circle.fill.badge.checkmark",
            plan: .starter
        )

        let project1ID = UUID()
        let project2ID = UUID()
        let project3ID = UUID()

        let applications1 = [
            AgentApplication(projectID: project1ID, agent: agentA, proposedCommission: 4.2, customMessage: "Je vous propose une stratégie premium avec shooting éditorial, base acquéreurs off-market et reporting hebdomadaire.", appliedAt: .now.addingTimeInterval(-3600 * 4)),
            AgentApplication(projectID: project1ID, agent: agentC, proposedCommission: 4.1, customMessage: "Je peux positionner votre bien rapidement grâce à un portefeuille d'acheteurs qualifiés sur le 17e.", appliedAt: .now.addingTimeInterval(-3600 * 10))
        ]

        let applications2 = [
            AgentApplication(projectID: project2ID, agent: agentB, proposedCommission: 4.5, customMessage: "J'ai déjà trois acquéreurs actifs sur ce secteur et un réseau local très engagé.", appliedAt: .now.addingTimeInterval(-3600 * 8))
        ]

        let project1 = PropertyProject(
            id: project1ID,
            title: "Appartement familial lumineux",
            fullAddress: "12 rue Ampère, 75017 Paris",
            city: "Paris",
            postalCode: "75017",
            propertyType: .apartment,
            description: "5 pièces, balcon filant, étage élevé, rénovation récente. Objectif : mise en vente avant l'été.",
            desiredPrice: 1_120_000,
            idealListingDate: .now.addingTimeInterval(86400 * 18),
            extraInformation: "Gardienne, double cave, diagnostics à jour.",
            photos: [
                PhotoAsset(systemName: "building.2.crop.circle", label: "Façade", accentName: "sun.max.fill"),
                PhotoAsset(systemName: "bed.double.fill", label: "Suite", accentName: "sparkles"),
                PhotoAsset(systemName: "chair.lounge.fill", label: "Salon", accentName: "lamp.floor.fill")
            ],
            status: .reviewing,
            applications: applications1,
            selectedAgentID: agentA.id,
            requiredRegion: "Île-de-France",
            districtLabel: "Paris 17e",
            feedHighlight: "Balcon filant · lumière ouest"
        )

        let project2 = PropertyProject(
            id: project2ID,
            title: "Maison pierre avec jardin",
            fullAddress: "44 avenue du Parc, 33200 Bordeaux",
            city: "Bordeaux",
            postalCode: "33200",
            propertyType: .house,
            description: "Maison 1930 rénovée, 4 chambres, jardin paysager, cave à vin.",
            desiredPrice: 695_000,
            idealListingDate: .now.addingTimeInterval(86400 * 27),
            extraInformation: "Extension possible, dossier urbanisme disponible.",
            photos: [
                PhotoAsset(systemName: "house.fill", label: "Façade", accentName: "leaf.fill"),
                PhotoAsset(systemName: "leaf.fill", label: "Jardin", accentName: "tree.fill"),
                PhotoAsset(systemName: "fork.knife.circle.fill", label: "Cuisine", accentName: "sparkles")
            ],
            status: .published,
            applications: applications2,
            selectedAgentID: nil,
            requiredRegion: "Nouvelle-Aquitaine",
            districtLabel: "Bordeaux Caudéran",
            feedHighlight: "Jardin paysager · cave à vin"
        )

        let project3 = PropertyProject(
            id: project3ID,
            title: "Loft avec terrasse",
            fullAddress: "8 quai de Saône, 69009 Lyon",
            city: "Lyon",
            postalCode: "69009",
            propertyType: .loft,
            description: "Volumétrie rare, verrière, terrasse 28 m², cible cadre dirigeant.",
            desiredPrice: 760_000,
            idealListingDate: .now.addingTimeInterval(86400 * 10),
            extraInformation: "Photos HD disponibles, DPE B.",
            photos: [
                PhotoAsset(systemName: "sparkles.tv.fill", label: "Pièce de vie", accentName: "sparkles"),
                PhotoAsset(systemName: "sun.max.fill", label: "Terrasse", accentName: "sun.max.fill"),
                PhotoAsset(systemName: "square.3.layers.3d.down.right", label: "Plan", accentName: "ruler")
            ],
            status: .underMandate,
            applications: [],
            selectedAgentID: agentC.id,
            requiredRegion: "Auvergne-Rhône-Alpes",
            districtLabel: "Lyon 9e",
            feedHighlight: "Terrasse 28 m² · verrière"
        )

        let sellerMandates = [
            Mandate(
                projectID: project1ID,
                propertyTitle: project1.title,
                status: "Candidature envoyée",
                estimatedRange: "1,08 M€ – 1,15 M€",
                valuationNotice: "Positionnement premium conseillé avec lancement confidentiel sur 10 jours.",
                digitalMandateName: "Mandat_exclusif_Paris17.pdf",
                appointments: [
                    Appointment(title: "Shooting photo", date: .now.addingTimeInterval(86400 * 2), location: "Sur place", note: "Prévoir home staging léger."),
                    Appointment(title: "Signature mandat", date: .now.addingTimeInterval(86400 * 4), location: "Visio sécurisée", note: "Pièces d'identité validées.")
                ],
                photos: project1.photos
            )
        ]

        let agentMandates = [
            Mandate(
                projectID: project3ID,
                propertyTitle: project3.title,
                status: "En discussion",
                estimatedRange: "740 K€ – 785 K€",
                valuationNotice: "Différenciation par mise en scène architecturale et ciblage CSP+.",
                digitalMandateName: "Mandat_loft_lyon09_signed.pdf",
                appointments: [
                    Appointment(title: "Visite acquéreur 1", date: .now.addingTimeInterval(86400 * 1), location: "Loft Lyon 9", note: "Couple en financement validé."),
                    Appointment(title: "Avis de valeur actualisé", date: .now.addingTimeInterval(86400 * 6), location: "Back-office", note: "Comparer 3 ventes récentes.")
                ],
                photos: project3.photos
            )
        ]

        let conversations = [
            Conversation(
                title: "Alexandre Morel",
                subtitle: "Maison Vendôme",
                lastMessagePreview: "Je vous envoie le projet de mandat ce soir.",
                unreadCount: 2,
                projectTitle: project1.title,
                messages: [
                    ChatMessage(senderName: "Alexandre Morel", senderRole: .agent, text: "Bonjour Camille, votre dossier est très qualitatif.", sentAt: .now.addingTimeInterval(-3600 * 18)),

                    ChatMessage(senderName: "Camille", senderRole: .seller, text: "Merci, je souhaite une mise en vente très encadrée.", sentAt: .now.addingTimeInterval(-3600 * 16)),

                    ChatMessage(senderName: "Alexandre Morel", senderRole: .agent, text: "Je vous envoie le projet de mandat ce soir.", sentAt: .now.addingTimeInterval(-3600 * 3))
                ]
            )
        ]

        let notifications = [
            NotificationItem(title: "Nouvelle candidature", body: "Alexandre Morel a proposé 4,2 % pour Appartement familial lumineux.", symbolName: "bell.badge.fill", date: .now.addingTimeInterval(-3600 * 2)),
            NotificationItem(title: "Nouveau message", body: "Maison Vendôme vous a envoyé un document mandat.", symbolName: "message.badge.fill", date: .now.addingTimeInterval(-3600 * 5)),
            NotificationItem(title: "RDV confirmé", body: "Shooting photo programmé le 17 avril à 10:00.", symbolName: "calendar.badge.clock", date: .now.addingTimeInterval(-3600 * 12))
        ]

        let feedProjects = [
            project1,
            project2,
            project3,
            PropertyProject(
                title: "Dernier étage avec terrasse filante",
                fullAddress: "18 boulevard Pereire, 75017 Paris",
                city: "Paris",
                postalCode: "75017",
                propertyType: .apartment,
                description: "Appartement traversant, vue dégagée, rénovation architecte et belle hauteur sous plafond.",
                desiredPrice: 1_340_000,
                idealListingDate: .now.addingTimeInterval(86400 * 14),
                extraInformation: "Copropriété standing, gardien, parking en option.",
                photos: [
                    PhotoAsset(systemName: "building.fill", label: "Vue rue", accentName: "sun.max.fill"),
                    PhotoAsset(systemName: "sparkles.tv.fill", label: "Séjour", accentName: "sparkles"),
                    PhotoAsset(systemName: "sun.max.fill", label: "Terrasse", accentName: "sparkles")
                ],
                status: .published,
                applications: [],
                selectedAgentID: nil,
                requiredRegion: "Île-de-France",
                districtLabel: "Paris 17e",
                feedHighlight: "Terrasse filante · rénovation architecte"
            ),
            PropertyProject(
                title: "Maison de ville avec patio",
                fullAddress: "6 rue des Récollets, 30000 Nîmes",
                city: "Nîmes",
                postalCode: "30000",
                propertyType: .house,
                description: "Maison en pierre, patio intime, volumes lumineux et potentiel locatif complémentaire.",
                desiredPrice: 438_000,
                idealListingDate: .now.addingTimeInterval(86400 * 16),
                extraInformation: "Climatisation réversible, diagnostics en cours.",
                photos: [
                    PhotoAsset(systemName: "house.lodge.fill", label: "Patio", accentName: "leaf.fill"),
                    PhotoAsset(systemName: "sofa.fill", label: "Séjour", accentName: "lamp.floor.fill"),
                    PhotoAsset(systemName: "tree.fill", label: "Extérieur", accentName: "sun.max.fill")
                ],
                status: .published,
                applications: [],
                selectedAgentID: nil,
                requiredRegion: "Occitanie",
                districtLabel: "Nîmes centre",
                feedHighlight: "Patio privé · pierre apparente"
            ),
            PropertyProject(
                title: "Villa vue mer confidentielle",
                fullAddress: "2 route des Sanguinaires, 20000 Ajaccio",
                city: "Ajaccio",
                postalCode: "20000",
                propertyType: .house,
                description: "Villa contemporaine, piscine suspendue, accès rapide aux plages et volumes ultra premium.",
                desiredPrice: 1_980_000,
                idealListingDate: .now.addingTimeInterval(86400 * 12),
                extraInformation: "Client souhaite un plan de mise en marché discret.",
                photos: [
                    PhotoAsset(systemName: "water.waves", label: "Vue mer", accentName: "sun.max.fill"),
                    PhotoAsset(systemName: "house.fill", label: "Villa", accentName: "sparkles"),
                    PhotoAsset(systemName: "drop.fill", label: "Piscine", accentName: "sparkles")
                ],
                status: .published,
                applications: [],
                selectedAgentID: nil,
                requiredRegion: "Corse",
                districtLabel: "Ajaccio route des Sanguinaires",
                feedHighlight: "Vue mer · piscine suspendue"
            ),
            PropertyProject(
                title: "Appartement haussmannien réception",
                fullAddress: "33 avenue Foch, 75116 Paris",
                city: "Paris",
                postalCode: "75116",
                propertyType: .apartment,
                description: "Réception de standing, moulures, parquet point de Hongrie et balcon filant.",
                desiredPrice: 2_480_000,
                idealListingDate: .now.addingTimeInterval(86400 * 22),
                extraInformation: "Vente préparée avec family office.",
                photos: [
                    PhotoAsset(systemName: "building.columns.fill", label: "Entrée", accentName: "sparkles"),
                    PhotoAsset(systemName: "chair.lounge.fill", label: "Réception", accentName: "lamp.floor.fill"),
                    PhotoAsset(systemName: "sun.max.fill", label: "Balcon", accentName: "sparkles")
                ],
                status: .published,
                applications: [],
                selectedAgentID: nil,
                requiredRegion: "Île-de-France",
                districtLabel: "Paris 16e",
                feedHighlight: "Balcon filant · réception"
            ),
            PropertyProject(
                title: "Duplex rooftop rive droite",
                fullAddress: "90 quai des Chartrons, 33000 Bordeaux",
                city: "Bordeaux",
                postalCode: "33000",
                propertyType: .loft,
                description: "Dernier étage avec terrasse rooftop, vue Garonne, prestations design et parking double.",
                desiredPrice: 920_000,
                idealListingDate: .now.addingTimeInterval(86400 * 19),
                extraInformation: "Vendeur souhaite une campagne digitale premium.",
                photos: [
                    PhotoAsset(systemName: "sparkles.tv.fill", label: "Séjour", accentName: "sparkles"),
                    PhotoAsset(systemName: "sun.max.fill", label: "Rooftop", accentName: "sun.max.fill"),
                    PhotoAsset(systemName: "car.fill", label: "Stationnement", accentName: "sparkles")
                ],
                status: .published,
                applications: [],
                selectedAgentID: nil,
                requiredRegion: "Nouvelle-Aquitaine",
                districtLabel: "Bordeaux Chartrons",
                feedHighlight: "Rooftop · vue Garonne"
            ),
            PropertyProject(
                title: "Appartement signature avec patio",
                fullAddress: "14 rue de la République, 69002 Lyon",
                city: "Lyon",
                postalCode: "69002",
                propertyType: .apartment,
                description: "Appartement rénové avec patio intérieur, matériaux nobles et plan optimisé.",
                desiredPrice: 642_000,
                idealListingDate: .now.addingTimeInterval(86400 * 9),
                extraInformation: "Client ouvert à une exclusivité courte.",
                photos: [
                    PhotoAsset(systemName: "square.grid.2x2.fill", label: "Patio", accentName: "leaf.fill"),
                    PhotoAsset(systemName: "bed.double.fill", label: "Suite", accentName: "sparkles"),
                    PhotoAsset(systemName: "sofa.fill", label: "Séjour", accentName: "lamp.floor.fill")
                ],
                status: .published,
                applications: [],
                selectedAgentID: nil,
                requiredRegion: "Auvergne-Rhône-Alpes",
                districtLabel: "Lyon Presqu'île",
                feedHighlight: "Patio intérieur · matériaux nobles"
            )
        ]

        return DemoDataFactory(
            projects: [project1, project2, project3],
            feedProjects: feedProjects,
            sellerMandates: sellerMandates,
            agentMandates: agentMandates,
            conversations: conversations,
            notifications: notifications
        )
    }

    static func makeIncomingProject(for city: String) -> PropertyProject {
        let normalizedCity = city.folding(options: .diacriticInsensitive, locale: .current).lowercased()
        switch normalizedCity {
        case let cityName where cityName.contains("paris"):
            return PropertyProject(
                title: "Nouveau bien confidentiel à Monceau",
                fullAddress: "5 avenue de Messine, 75008 Paris",
                city: "Paris",
                postalCode: "75008",
                propertyType: .apartment,
                description: "Appartement réception, vue dégagée, balcon et rénovation de standing.",
                desiredPrice: 1_860_000,
                idealListingDate: .now.addingTimeInterval(86400 * 7),
                extraInformation: "Publication réservée aux agents actifs sur Paris intra-muros.",
                photos: [
                    PhotoAsset(systemName: "building.columns.fill", label: "Réception", accentName: "sparkles"),
                    PhotoAsset(systemName: "sun.max.fill", label: "Balcon", accentName: "sun.max.fill"),
                    PhotoAsset(systemName: "bed.double.fill", label: "Suite", accentName: "sparkles")
                ],
                status: .published,
                applications: [],
                selectedAgentID: nil,
                requiredRegion: "Île-de-France",
                districtLabel: "Paris 8e",
                feedHighlight: "Nouveau · exclusivité Monceau"
            )
        case let cityName where cityName.contains("bordeaux"):
            return PropertyProject(
                title: "Échoppe familiale avec piscine",
                fullAddress: "11 rue Croix-de-Seguey, 33000 Bordeaux",
                city: "Bordeaux",
                postalCode: "33000",
                propertyType: .house,
                description: "Échoppe repensée par architecte, piscine et dépendance bureau.",
                desiredPrice: 812_000,
                idealListingDate: .now.addingTimeInterval(86400 * 8),
                extraInformation: "Flux acquéreurs CSP+ recherché.",
                photos: [
                    PhotoAsset(systemName: "house.fill", label: "Façade", accentName: "sparkles"),
                    PhotoAsset(systemName: "drop.fill", label: "Piscine", accentName: "sun.max.fill"),
                    PhotoAsset(systemName: "sofa.fill", label: "Pièce de vie", accentName: "lamp.floor.fill")
                ],
                status: .published,
                applications: [],
                selectedAgentID: nil,
                requiredRegion: "Nouvelle-Aquitaine",
                districtLabel: "Bordeaux centre",
                feedHighlight: "Nouveau · piscine & dépendance"
            )
        default:
            return PropertyProject(
                title: "Mandat entrant du secteur \(city)",
                fullAddress: "1 place centrale, \(city)",
                city: city,
                postalCode: "30000",
                propertyType: .apartment,
                description: "Nouveau bien entrant visible immédiatement dans le feed local des agents.",
                desiredPrice: 540_000,
                idealListingDate: .now.addingTimeInterval(86400 * 6),
                extraInformation: "Publication prioritaire dans le rayon configuré.",
                photos: [
                    PhotoAsset(systemName: "building.2.fill", label: "Façade", accentName: "sparkles"),
                    PhotoAsset(systemName: "sun.max.fill", label: "Extérieur", accentName: "sun.max.fill"),
                    PhotoAsset(systemName: "sparkles.tv.fill", label: "Intérieur", accentName: "lamp.floor.fill")
                ],
                status: .published,
                applications: [],
                selectedAgentID: nil,
                requiredRegion: city,
                districtLabel: city,
                feedHighlight: "Nouveau · dans votre rayon"
            )
        }
    }
}
