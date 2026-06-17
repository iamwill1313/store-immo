import Foundation
import Observation

@Observable
@MainActor
final class AppViewModel {
    var selectedRole: UserRole?
    var isAuthenticated: Bool = false
    var registeredEmails: Set<String> = []
    var sellerTab: AppTabSeller = .dashboard
    var agentTab: AppTabAgent = .discover
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
    var sellerPhoneNumber: String = "+33 6 84 21 55 30"
    var agentBaseCity: String = "Paris"
    var isDiscoverFeedRefreshing: Bool = false
    let discoverRadiusOptions: [Int] = [5, 10, 20, 50, 100]

    private var sellerProfileFirstName: String = "Camille"
    private var sellerProfileLastName: String = "Bernard"
    private var discoverFeedPage: Int = 1
    private let discoverFeedPageSize: Int = 4
    private var discoverFeedSource: [PropertyProject]

    init() {
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

        Task {
            await loadSellerProjectsFromSupabase()
        }
        }
    
    func loadSellerProjectsFromSupabase() async {
        let rows = await SupabaseService.shared.fetch(
            from: "sellers_projects",
            as: SellerProjectRow.self
        )
        
        let applicationRows = await SupabaseService.shared.fetch(
            from: "applications",
            as: ApplicationRow.self
        )
        
        let agentRows = await SupabaseService.shared.fetch(
            from: "agents_profiles",
            as: AgentProfileRow.self
        )

        print("📦 Projets chargés :", rows.count)
        print("📦 Première ligne Supabase :", rows.first as Any)
        let formatter = ISO8601DateFormatter()

        let projects: [PropertyProject] = rows.map { row in
            return PropertyProject(
                id: UUID(uuidString: row.id) ?? UUID(),
                title: "\(row.property_type) à \(row.city)",
                fullAddress: row.address,
                city: row.city,
                postalCode: row.postal_code,
                propertyType: PropertyType(rawValue: row.property_type) ?? .apartment,
                description: row.description,
                desiredPrice: row.desired_price,
                idealListingDate: formatter.date(from: row.ideal_listing_date) ?? Date(),
                extraInformation: "",
                photos: {
                    if let photoURL = row.photo_url, !photoURL.isEmpty {
                        return [PhotoAsset(
                            systemName: "building.2.crop.circle",
                            label: "\(row.property_type) à \(row.city)",
                            accentName: "sparkles",
                            url: photoURL
                        )]
                    }
                    return [PhotoAsset(
                        systemName: "building.2.crop.circle",
                        label: "\(row.property_type) à \(row.city)"
                    )]
                }(),
                status: ProjectStatus(rawValue: row.status) ?? .published,
                applications: applicationRows
                    .filter { $0.project_id == row.id }
                    .map { applicationRow in
                        let agentRow = agentRows.first { $0.user_id == applicationRow.agent_id }

                        let agent = AgentProfile(
                            id: UUID(uuidString: agentRow?.user_id ?? applicationRow.agent_id ?? "") ?? UUID(),
                            fullName: "\(agentRow?.first_name ?? "Agent") \(agentRow?.last_name ?? "Supabase")",
                            agencyName: agentRow?.agency ?? "Agence non renseignée",
                            city: agentRow?.city ?? "Ville non renseignée",
                            badge: .professionalCard(number: "Supabase"),
                            bio: agentRow?.description ?? "Agent candidat via Supabase.",
                            averageRating: 0,
                            reviewCount: 0,
                            salesLast12Months: 0,
                            soldRate: 0,
                            averageSalePrice: 0,
                            averageDelayDays: 0,
                            commissionPercent: applicationRow.commission_percent,
                            interventionZones: [],
                            reviews: [],
                            photoSymbol: "person.crop.circle.fill",
                            plan: .starter
                        )

                        return AgentApplication(
                            id: UUID(uuidString: applicationRow.id) ?? UUID(),
                            projectID: UUID(uuidString: applicationRow.project_id) ?? UUID(),
                            agent: agent,
                            proposedCommission: applicationRow.commission_percent,
                            customMessage: applicationRow.message,
                            status: applicationRow.status ?? "pending",
                            appliedAt: Date()
                        )
                    },
                selectedAgentID: UUID(uuidString: row.selected_agent_id ?? ""),
                requiredRegion: row.city,
                districtLabel: row.postal_code,
                feedHighlight: "Projet Supabase"
            )
        }
            if !projects.isEmpty {
                self.sellerProjects = projects
                self.discoverFeedSource = projects
                self.agentOpportunities = Array(projects.prefix(discoverFeedPageSize))
                if let selectedProject {
                    self.selectedProject = projects.first { $0.id == selectedProject.id } ?? projects.first
                } else {
                    self.selectedProject = projects.first
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
        switch selectedPlan {
        case .starter:
            return 2
        case .pro:
            return 9
        case .elite:
            return 999
        }
    }

    var isAgentSubscriptionActive: Bool {
        hasChosenAgentSubscription
    }

    var hasUnlimitedApplications: Bool {
        hasChosenAgentSubscription && selectedPlan == .elite
    }

    var agentSectorSummary: String {
        "\(agentBaseCity) · rayon \(Int(radiusFilter)) km"
    }

    var savedDiscoverProjects: [PropertyProject] {
        discoverFeedProjects.filter { savedProjectIDs.contains($0.id) }
    }

    var hasCompletedAgentOnboarding: Bool {
        hasCompletedAgentProfileOnboarding && hasChosenAgentSubscription
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
    }

    func completeAuthentication() {
        isAuthenticated = true

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
        selectedRole = role
        isAuthenticated = true

        switch role {
        case .seller:
            hasCompletedSellerOnboarding = true
            appStatusMessage = "Connexion vendeur réussie."

        case .agent:
            hasCompletedAgentProfileOnboarding = true
            hasChosenAgentSubscription = true
            appStatusMessage = "Connexion agent réussie."
        }
    }
    
    func saveSellerOnboarding() {
        let email = sellerOnboardingDraft.email
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        if registeredEmails.contains(email) {
            appStatusMessage = "Cet email est déjà utilisé. Utilisez « Se connecter »."
            return
        }
        guard sellerOnboardingDraft.isComplete else {
            appStatusMessage = "Complétez tous les champs obligatoires du profil vendeur."
            return
        }
        sellerProfileFirstName = sellerOnboardingDraft.firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        sellerProfileLastName = sellerOnboardingDraft.lastName.trimmingCharacters(in: .whitespacesAndNewlines)
        sellerPhoneNumber = sellerOnboardingDraft.phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        hasCompletedSellerOnboarding = true
        registeredEmails.insert(email)
        appStatusMessage = "Profil vendeur enregistré. Bienvenue, \(sellerPublicFirstName)."
        let draft = sellerOnboardingDraft
        Task { @MainActor in
            _ = await SupabaseRepository.shared.upsertUser(role: "seller", email: draft.email, phone: draft.phoneNumber)
            let ok = await SupabaseRepository.shared.saveSellerProfile(draft)
            if !ok, let err = SupabaseRepository.shared.lastError {
                appStatusMessage = "Supabase: \(err)"
            }
        }
    }

    func saveAgentProfileOnboarding() {
        let email = agentOnboardingDraft.email
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        if registeredEmails.contains(email) {
            appStatusMessage = "Cet email est déjà utilisé. Utilisez « Se connecter »."
            return
        }
        guard agentOnboardingDraft.isComplete else {
            appStatusMessage = "Complétez tous les champs obligatoires du profil agent."
            return
        }
        let fullName = "\(agentOnboardingDraft.firstName) \(agentOnboardingDraft.lastName)"
        let description = agentOnboardingDraft.professionalDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        currentAgentProfile = AgentProfile(
            fullName: fullName,
            agencyName: agentOnboardingDraft.agency.isEmpty ? "Indépendant" : agentOnboardingDraft.agency,
            city: agentOnboardingDraft.city,
            badge: .professionalCard(number: "Vérification en cours"),
            bio: description.isEmpty ? "Agent immobilier vérifié sur Store Immo." : description,
            averageRating: 0,
            reviewCount: 0,
            salesLast12Months: 0,
            soldRate: 0,
            averageSalePrice: 0,
            averageDelayDays: 0,
            commissionPercent: 4.5,
            interventionZones: [CityZone(city: agentOnboardingDraft.city, region: agentOnboardingDraft.city, radiusKilometers: Int(radiusFilter))],
            reviews: [],
            photoSymbol: agentOnboardingDraft.photoSymbol,
            plan: selectedPlan
        )
        agentBaseCity = agentOnboardingDraft.city
        hasCompletedAgentProfileOnboarding = true
        registeredEmails.insert(email)
        resetAgentFeed()
        appStatusMessage = "Profil agent enregistré. Choisissez maintenant votre abonnement."
        let draft = agentOnboardingDraft
        Task { @MainActor in
            _ = await SupabaseRepository.shared.upsertUser(role: "agent", email: draft.email, phone: draft.phoneNumber)
            let ok = await SupabaseRepository.shared.saveAgentProfile(draft)
            if !ok, let err = SupabaseRepository.shared.lastError {
                appStatusMessage = "Supabase: \(err)"
            }
        }
    }

    func chooseSubscription(_ plan: SubscriptionPlan) {
        selectedPlan = plan
        hasChosenAgentSubscription = true
        appStatusMessage = "Abonnement \(plan.title) activé pour la démo. En production, ce choix doit créer une session Stripe Checkout."
        Task { @MainActor in
            let okSub = await SupabaseRepository.shared.saveSubscription(plan: plan)
            _ = await SupabaseRepository.shared.recordPayment(plan: plan)
            if !okSub, let err = SupabaseRepository.shared.lastError {
                appStatusMessage = "Supabase: \(err)"
            }
        }
    }

    func signOut() {
        isAuthenticated = false
        selectedRole = nil
        revealPhoneNumber = false
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
                return item
            },
            selectedAgentID: application.agent.id,
            requiredRegion: project.requiredRegion,
            districtLabel: project.districtLabel,
            feedHighlight: project.feedHighlight
        )
        print("🟡 AVANT :", sellerProjects[currentIndex].status)
        sellerProjects[currentIndex] = updatedProject
        Task {
            print("🟢 APRES :", sellerProjects[currentIndex].status)

            async let updateProject = SupabaseRepository.shared.updateProjectSelectedAgent(
                projectID: project.id,
                selectedAgentID: application.agent.id
            )

            async let updateApplication = SupabaseRepository.shared.updateApplicationStatus(
                applicationID: application.id,
                status: "chosen"
            )

            let projectOK = await updateProject
            let applicationOK = await updateApplication

            print("🔥 PROJECT OK =", projectOK)
            print("🔥 APPLICATION OK =", applicationOK)
        }
        print("🟢 APRES :", sellerProjects[currentIndex].status)
        if let feedIndex = agentOpportunities.firstIndex(where: { $0.id == project.id }) {
            agentOpportunities[feedIndex] = updatedProject
        }

        selectedProject = updatedProject
        selectedApplication = application
        
        let conversationID = UUID()

        let newConversation = Conversation(
            id: conversationID,
            title: application.agent.fullName,
            subtitle: application.agent.agencyName,
            lastMessagePreview: "Commencez la discussion avec l'agent.",
            unreadCount: 1,
            projectTitle: updatedProject.title,
            messages: [
                ChatMessage(
                    senderName: sellerPublicFirstName,
                    senderRole: .seller,
                    text: "Commencez la discussion avec l'agent.",
                    sentAt: .now
                )
            ]
        )

        conversations.insert(newConversation, at: 0)
        
        print("💬 CONVERSATION CREEE :", newConversation.title)
        print("💬 TOTAL CONVERSATIONS :", conversations.count)
        
        selectedConversation = newConversation


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
        
        notifications.insert(
            NotificationItem(
                title: "Agent retenu",
                body: "Vous avez choisi \(application.agent.fullName) pour \(project.title).",
                symbolName: "checkmark.seal.fill",
                date: .now
            ),
            at: 0
        )
        
    }

    func revealPhone() {
        revealPhoneNumber = true
    }

    func sendCurrentMessage(_ text: String) {
        guard let conversation = selectedConversation, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        let senderName = selectedRole == .seller ? sellerPublicFirstName : (currentAgentProfile?.fullName ?? "Agent")

        let message = ChatMessage(
            senderName: senderName,
            senderRole: selectedRole ?? .seller,
            text: text,
            sentAt: .now
        )
        let updated = Conversation(
            id: conversation.id,
            title: conversation.title,
            subtitle: conversation.subtitle,
            lastMessagePreview: text,
            unreadCount: 0,
            projectTitle: conversation.projectTitle,
            messages: conversation.messages + [message]
        )
        replaceConversation(updated)
        let convID = conversation.id
        Task { @MainActor in
            let ok = await SupabaseRepository.shared.sendMessage(
                conversationID: convID,
                projectID: nil,
                receiverID: nil,
                body: text
            )
            if !ok, let err = SupabaseRepository.shared.lastError {
                appStatusMessage = "Supabase: \(err)"
            }
        }
    }

    func submitSellerLead(photoData: Data? = nil) {
        guard !sellerLeadDraft.address.isEmpty, !sellerLeadDraft.city.isEmpty else { return }
        let generatedProject = PropertyProject(
            title: "Nouveau projet à \(sellerLeadDraft.city)",
            fullAddress: sellerLeadDraft.address,
            city: sellerLeadDraft.city,
            postalCode: sellerLeadDraft.postalCode,
            propertyType: sellerLeadDraft.propertyType,
            description: sellerLeadDraft.description,
            desiredPrice: Int(sellerLeadDraft.desiredPrice) ?? 480_000,
            idealListingDate: sellerLeadDraft.idealListingDate,
            extraInformation: sellerLeadDraft.extraInformation,
            photos: [
                PhotoAsset(systemName: "building.2.crop.circle", label: "Façade", accentName: "sparkles"),
                PhotoAsset(systemName: "sofa.fill", label: "Salon", accentName: "lamp.floor.fill"),
                PhotoAsset(systemName: "tree.fill", label: "Jardin", accentName: "sun.max.fill")
            ],
            status: .published,
            applications: [],
            selectedAgentID: nil,
            requiredRegion: sellerLeadDraft.city,
            districtLabel: sellerLeadDraft.city,
            feedHighlight: "Nouveau mandat vendeur"
        )
        sellerProjects.insert(generatedProject, at: 0)
        selectedProject = generatedProject
        let draftCopy = sellerLeadDraft
        let pid = generatedProject.id
        sellerLeadDraft = SellerLeadDraft()
        notifications.insert(
            NotificationItem(
                title: "Projet publié",
                body: "Votre bien est désormais visible par les agents de votre zone.",
                symbolName: "house.badge.checkmark",
                date: .now
            ),
            at: 0
        )
        Task { @MainActor in
            let userOK = await SupabaseRepository.shared.upsertUser(
                role: "seller",
                email: sellerOnboardingDraft.email,
                phone: sellerPhoneNumber
            )

            print("👤 USER OK AVANT CREATE PROJECT =", userOK)

            let ok = await SupabaseRepository.shared.createProject(from: draftCopy, projectID: pid)
            if ok, let photoData {
                if let photoURL = await SupabaseRepository.shared.uploadProjectPhoto(
                    projectID: pid,
                    imageData: photoData
                ),
                let idx = sellerProjects.firstIndex(where: { $0.id == pid }) {
                    let p = sellerProjects[idx]
                    let photoAsset = PhotoAsset(
                        systemName: "photo",
                        label: p.title,
                        accentName: "sparkles",
                        url: photoURL
                    )
                    sellerProjects[idx] = PropertyProject(
                        id: p.id,
                        title: p.title,
                        fullAddress: p.fullAddress,
                        city: p.city,
                        postalCode: p.postalCode,
                        propertyType: p.propertyType,
                        description: p.description,
                        desiredPrice: p.desiredPrice,
                        idealListingDate: p.idealListingDate,
                        extraInformation: p.extraInformation,
                        photos: [photoAsset],
                        status: p.status,
                        applications: p.applications,
                        selectedAgentID: p.selectedAgentID,
                        requiredRegion: p.requiredRegion,
                        districtLabel: p.districtLabel,
                        feedHighlight: p.feedHighlight
                    )
                    if selectedProject?.id == pid {
                        selectedProject = sellerProjects[idx]
                    }
                }
            }
            _ = await SupabaseRepository.shared.createNotification(
                title: "Projet publié",
                body: "Votre bien est désormais visible.",
                type: "project_published"
            )

            if !ok, let err = SupabaseRepository.shared.lastError {
                appStatusMessage = "Supabase: \(err)"
            }
        }
    }

    func submitAgentApplication(for project: PropertyProject) {
        guard applicationsTodayRemaining > 0 else {
            appStatusMessage = "Limite de candidatures atteinte pour votre abonnement."
            return
        }
        let firstAgent = currentAgentProfile ?? featuredAgents.first
        guard let firstAgent else { return }
        let application = AgentApplication(
            projectID: project.id,
            agent: firstAgent,
            proposedCommission: Double(agentApplicationDraft.commissionText.replacingOccurrences(of: ",", with: ".")) ?? 4.5,
            customMessage: agentApplicationDraft.message.isEmpty ? "Je peux lancer un plan de commercialisation premium en 7 jours." : agentApplicationDraft.message,
            appliedAt: .now
        )
        if let sellerProjectIndex = sellerProjects.firstIndex(where: { $0.id == project.id }) {
            var applications = sellerProjects[sellerProjectIndex].applications
            guard !applications.contains(where: { $0.agent.id == application.agent.id }) else { return }
            applications.insert(application, at: 0)
            let original = sellerProjects[sellerProjectIndex]
            let updated = PropertyProject(
                id: original.id,
                title: original.title,
                fullAddress: original.fullAddress,
                city: original.city,
                postalCode: original.postalCode,
                propertyType: original.propertyType,
                description: original.description,
                desiredPrice: original.desiredPrice,
                idealListingDate: original.idealListingDate,
                extraInformation: original.extraInformation,
                photos: original.photos,
                status: .reviewing,
                applications: applications,
                selectedAgentID: original.selectedAgentID,
                requiredRegion: original.requiredRegion,
                districtLabel: original.districtLabel,
                feedHighlight: original.feedHighlight
            )
            sellerProjects[sellerProjectIndex] = updated
            if let agentIndex = agentOpportunities.firstIndex(where: { $0.id == project.id }) {
                agentOpportunities[agentIndex] = updated
            }
            selectedProject = updated
            appliedProjectIDs.insert(project.id)
            print("📩 CANDIDATURE AJOUTEE :", project.id)
            print("📩 TOTAL :", appliedProjectIDs.count)
            notifications.insert(
                NotificationItem(
                    title: "Candidature envoyée",
                    body: "Votre proposition a été envoyée pour \(project.title).",
                    symbolName: "paperplane.fill",
                    date: .now
                ),
                at: 0
            )
            let commission = application.proposedCommission
            let message = application.customMessage
            let projectID = project.id
            let projectTitle = project.title
            Task { @MainActor in
                let ok = await SupabaseRepository.shared.createApplication(projectID: projectID, commission: commission, message: message)
                _ = await SupabaseRepository.shared.createNotification(title: "Candidature envoyée", body: "Proposition envoyée pour \(projectTitle).", type: "application_sent")
                if !ok, let err = SupabaseRepository.shared.lastError {
                    appStatusMessage = "Supabase: \(err)"
                }
            }
        }
        agentApplicationDraft = AgentApplicationDraft()
    }

    func selectConversation(_ conversation: Conversation) {
        selectedConversation = conversation
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
    }

    func updateRadiusFilter(to radius: Int) {
        let clampedRadius = discoverRadiusOptions.min(by: { abs($0 - radius) < abs($1 - radius) }) ?? 50
        guard Int(radiusFilter) != clampedRadius else { return }
        radiusFilter = Double(clampedRadius)
        resetAgentFeed()
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

    func refreshDiscoverFeed() -> PropertyProject? {
        isDiscoverFeedRefreshing = true
        let freshProject = DemoDataFactory.makeIncomingProject(for: agentBaseCity)
        guard filteredDiscoverFeedSource(for: [freshProject] + discoverFeedSource).contains(where: { $0.id == freshProject.id }) else {
            isDiscoverFeedRefreshing = false
            return nil
        }
        agentOpportunities.insert(freshProject, at: 0)
        sellerProjects.insert(freshProject, at: 0)
        notifications.insert(
            NotificationItem(
                title: "Nouveau bien dans votre secteur",
                body: "\(freshProject.title) vient d’arriver dans le feed \(agentBaseCity).",
                symbolName: "bell.badge.fill",
                date: .now
            ),
            at: 0
        )
        isDiscoverFeedRefreshing = false
        return freshProject
    }

    private func replaceConversation(_ conversation: Conversation) {
        guard let index = conversations.firstIndex(where: { $0.id == conversation.id }) else { return }
        conversations[index] = conversation
        selectedConversation = conversation
    }

    private func filteredDiscoverFeedSource() -> [PropertyProject] {
        filteredDiscoverFeedSource(for: discoverFeedSource)
    }

    private func filteredDiscoverFeedSource(for source: [PropertyProject]) -> [PropertyProject] {
        source.filter { project in
            distanceToProject(project) <= Int(radiusFilter)
        }
    }

    private func distanceToProject(_ project: PropertyProject) -> Int {
        let baseCity = normalizedLocation(agentBaseCity)
        let projectCity = normalizedLocation(project.city)
        let district = normalizedLocation(project.districtLabel)

        switch baseCity {
        case "paris":
            if district.contains("paris 17") || project.fullAddress.contains("75017") {
                return 5
            }
            if district.contains("paris") || project.fullAddress.contains("75116") {
                return 9
            }
            if projectCity == "nimes" {
                return 580
            }
            if projectCity == "bordeaux" {
                return 585
            }
            if projectCity == "lyon" {
                return 465
            }
            if projectCity == "ajaccio" {
                return 915
            }
        case "bordeaux":
            if district.contains("bordeaux") || projectCity == "bordeaux" {
                return 8
            }
            if district.contains("arcachon") {
                return 68
            }
            if projectCity == "paris" {
                return 585
            }
            if projectCity == "nimes" {
                return 470
            }
            if projectCity == "lyon" {
                return 555
            }
            if projectCity == "ajaccio" {
                return 910
            }
        case "lyon":
            if district.contains("lyon") || projectCity == "lyon" {
                return 7
            }
            if district.contains("villeurbanne") {
                return 12
            }
            if projectCity == "paris" {
                return 465
            }
            if projectCity == "nimes" {
                return 250
            }
            if projectCity == "bordeaux" {
                return 555
            }
            if projectCity == "ajaccio" {
                return 725
            }
        case "nimes":
            if district.contains("nimes") || projectCity == "nimes" {
                return 6
            }
            if projectCity == "lyon" {
                return 250
            }
            if projectCity == "paris" {
                return 580
            }
            if projectCity == "bordeaux" {
                return 470
            }
            if projectCity == "ajaccio" {
                return 620
            }
        case "ajaccio":
            if district.contains("ajaccio") || projectCity == "ajaccio" {
                return 8
            }
            if projectCity == "paris" {
                return 915
            }
            if projectCity == "nimes" {
                return 620
            }
            if projectCity == "lyon" {
                return 725
            }
            if projectCity == "bordeaux" {
                return 910
            }
        default:
            break
        }

        if projectCity == baseCity || district.contains(baseCity) {
            return 12
        }

        return 999
    }

    private func normalizedLocation(_ value: String) -> String {
        value
            .folding(options: .diacriticInsensitive, locale: .current)
            .lowercased()
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
            bio: "Ancien notaire conseil, j’accompagne les vendeurs premium avec une stratégie très éditoriale et des acquéreurs qualifiés.",
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
            AgentApplication(projectID: project1ID, agent: agentC, proposedCommission: 4.1, customMessage: "Je peux positionner votre bien rapidement grâce à un portefeuille d’acheteurs qualifiés sur le 17e.", appliedAt: .now.addingTimeInterval(-3600 * 10))
        ]

        let applications2 = [
            AgentApplication(projectID: project2ID, agent: agentB, proposedCommission: 4.5, customMessage: "J’ai déjà trois acquéreurs actifs sur ce secteur et un réseau local très engagé.", appliedAt: .now.addingTimeInterval(-3600 * 8))
        ]

        let project1 = PropertyProject(
            id: project1ID,
            title: "Appartement familial lumineux",
            fullAddress: "12 rue Ampère, 75017 Paris",
            city: "Paris",
            postalCode: "75017",
            propertyType: .apartment,
            description: "5 pièces, balcon filant, étage élevé, rénovation récente. Objectif : mise en vente avant l’été.",
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
                    Appointment(title: "Signature mandat", date: .now.addingTimeInterval(86400 * 4), location: "Visio sécurisée", note: "Pièces d’identité validées.")
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
