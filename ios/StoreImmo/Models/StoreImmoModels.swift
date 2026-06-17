import Foundation

nonisolated enum UserRole: String, CaseIterable, Identifiable, Sendable {
    case seller
    case agent

    var id: String { rawValue }

    var title: String {
        switch self {
        case .seller:
            "Vendeur"
        case .agent:
            "Agent"
        }
    }

    var subtitle: String {
        switch self {
        case .seller:
            "Publiez votre projet en quelques minutes"
        case .agent:
            "Développez votre portefeuille partout en France"
        }
    }

    var symbolName: String {
        switch self {
        case .seller:
            "house"
        case .agent:
            "person.badge.shield.checkmark"
        }
    }
}

nonisolated enum PropertyType: String, CaseIterable, Identifiable, Sendable {
    case apartment = "Appartement"
    case house = "Maison"
    case loft = "Loft"
    case land = "Terrain"
    case building = "Immeuble"

    var id: String { rawValue }
}

nonisolated enum ProjectStatus: String, CaseIterable, Identifiable, Sendable {
    case draft = "Brouillon"
    case published = "Publié"
    case reviewing = "En revue"
    case agentChosen = "Agent choisi"
    case underMandate = "Sous mandat"
    case sold = "Vendu"

    var id: String { rawValue }

    var accentLabel: String {
        switch self {
        case .draft:
            "À finaliser"
        case .published:
            "En ligne"
        case .reviewing:
            "Candidatures"
        case .agentChosen:
            "Choix confirmé"
        case .underMandate:
            "Commercialisation"
        case .sold:
            "Clôturé"
        }
    }
}

nonisolated enum VerificationBadge: Hashable, Sendable {
    case professionalCard(number: String)
    case mandate(network: String, number: String)

    var title: String {
        switch self {
        case .professionalCard:
            "Carte pro"
        case .mandate(let network, _):
            "Mandataire \(network)"
        }
    }

    var detail: String {
        switch self {
        case .professionalCard(let number):
            "N° \(number)"
        case .mandate(_, let number):
            "Carte \(number)"
        }
    }
}

nonisolated enum SubscriptionPlan: String, CaseIterable, Identifiable, Sendable {
    case starter
    case pro
    case elite

    var id: String { rawValue }

    var title: String {
        switch self {
        case .starter:
            "Starter"
        case .pro:
            "Pro"
        case .elite:
            "Elite"
        }
    }

    var tagline: String {
        switch self {
        case .starter:
            "Pour démarrer sereinement sur Store Immo."
        case .pro:
            "Pour les agents actifs qui veulent gagner en visibilité."
        case .elite:
            "Pour les agents qui veulent dominer leur secteur."
        }
    }

    var priceText: String {
        switch self {
        case .starter:
            "7,99 € / mois"
        case .pro:
            "19,99 € / mois"
        case .elite:
            "39,99 € / mois"
        }
    }

    var activeApplicationsLabel: String {
        switch self {
        case .starter:
            "3 candidatures actives"
        case .pro:
            "10 candidatures actives"
        case .elite:
            "Candidatures illimitées"
        }
    }

    var maxActiveApplications: Int {
        switch self {
        case .starter:
            3
        case .pro:
            10
        case .elite:
            999
        }
    }

    var features: [String] {
        switch self {
        case .starter:
            [
                "Accès complet à la plateforme",
                "Jusqu’à 3 candidatures actives",
                "Notifications des nouvelles opportunités",
                "Messagerie vendeur-agent"
            ]
        case .pro:
            [
                "Tous les avantages Starter",
                "Jusqu’à 10 candidatures actives simultanées",
                "Badge Agent Pro",
                "Meilleure visibilité du profil"
            ]
        case .elite:
            [
                "Tous les avantages Pro",
                "Candidatures illimitées",
                "Badge Agent Elite Vérifié",
                "Mise en avant premium",
                "Support prioritaire"
            ]
        }
    }

    var iconName: String {
        switch self {
        case .starter:
            "sparkles"
        case .pro:
            "bolt.fill"
        case .elite:
            "crown.fill"
        }
    }

    var ctaTitle: String {
        switch self {
        case .starter:
            "Choisir Starter"
        case .pro:
            "Choisir Pro"
        case .elite:
            "Passer Elite"
        }
    }

    var isHighlighted: Bool {
        self == .pro
    }
}

nonisolated struct CityZone: Identifiable, Hashable, Sendable {
    let id: UUID
    let city: String
    let region: String
    let radiusKilometers: Int

    init(id: UUID = UUID(), city: String, region: String, radiusKilometers: Int) {
        self.id = id
        self.city = city
        self.region = region
        self.radiusKilometers = radiusKilometers
    }
}

nonisolated struct PhotoAsset: Identifiable, Hashable, Sendable {
    let id: UUID
    let systemName: String
    let label: String
    let accentName: String
    let url: String?

    init(id: UUID = UUID(), systemName: String, label: String, accentName: String = "sun.max.fill", url: String? = nil) {
        self.id = id
        self.systemName = systemName
        self.label = label
        self.accentName = accentName
        self.url = url
    }
}

nonisolated struct Review: Identifiable, Hashable, Sendable {
    let id: UUID
    let author: String
    let rating: Double
    let comment: String
    let outcomeTag: String
    let date: Date

    init(id: UUID = UUID(), author: String, rating: Double, comment: String, outcomeTag: String, date: Date) {
        self.id = id
        self.author = author
        self.rating = rating
        self.comment = comment
        self.outcomeTag = outcomeTag
        self.date = date
    }
}

nonisolated struct AgentProfile: Identifiable, Hashable, Sendable {
    let id: UUID
    let fullName: String
    let agencyName: String
    let city: String
    let badge: VerificationBadge
    let bio: String
    let averageRating: Double
    let reviewCount: Int
    let salesLast12Months: Int
    let soldRate: Int
    let averageSalePrice: Int
    let averageDelayDays: Int
    let commissionPercent: Double
    let interventionZones: [CityZone]
    let reviews: [Review]
    let photoSymbol: String
    let plan: SubscriptionPlan

    init(
        id: UUID = UUID(),
        fullName: String,
        agencyName: String,
        city: String,
        badge: VerificationBadge,
        bio: String,
        averageRating: Double,
        reviewCount: Int,
        salesLast12Months: Int,
        soldRate: Int,
        averageSalePrice: Int,
        averageDelayDays: Int,
        commissionPercent: Double,
        interventionZones: [CityZone],
        reviews: [Review],
        photoSymbol: String,
        plan: SubscriptionPlan
    ) {
        self.id = id
        self.fullName = fullName
        self.agencyName = agencyName
        self.city = city
        self.badge = badge
        self.bio = bio
        self.averageRating = averageRating
        self.reviewCount = reviewCount
        self.salesLast12Months = salesLast12Months
        self.soldRate = soldRate
        self.averageSalePrice = averageSalePrice
        self.averageDelayDays = averageDelayDays
        self.commissionPercent = commissionPercent
        self.interventionZones = interventionZones
        self.reviews = reviews
        self.photoSymbol = photoSymbol
        self.plan = plan
    }
}

nonisolated struct AgentApplication: Identifiable, Hashable, Sendable {
    let id: UUID
    let projectID: UUID
    let agent: AgentProfile
    let proposedCommission: Double
    let customMessage: String
    let status: String
    let appliedAt: Date

    init(id: UUID = UUID(), projectID: UUID, agent: AgentProfile, proposedCommission: Double, customMessage: String, status: String = "pending", appliedAt: Date) {
        self.id = id
        self.projectID = projectID
        self.agent = agent
        self.proposedCommission = proposedCommission
        self.customMessage = customMessage
        self.status = status
        self.appliedAt = appliedAt
    }
}

nonisolated struct Appointment: Identifiable, Hashable, Sendable {
    let id: UUID
    let title: String
    let date: Date
    let location: String
    let note: String

    init(id: UUID = UUID(), title: String, date: Date, location: String, note: String) {
        self.id = id
        self.title = title
        self.date = date
        self.location = location
        self.note = note
    }
}

nonisolated struct Mandate: Identifiable, Hashable, Sendable {
    let id: UUID
    let projectID: UUID
    let propertyTitle: String
    let status: String
    let estimatedRange: String
    let valuationNotice: String
    let digitalMandateName: String
    let appointments: [Appointment]
    let photos: [PhotoAsset]

    init(
        id: UUID = UUID(),
        projectID: UUID,
        propertyTitle: String,
        status: String,
        estimatedRange: String,
        valuationNotice: String,
        digitalMandateName: String,
        appointments: [Appointment],
        photos: [PhotoAsset]
    ) {
        self.id = id
        self.projectID = projectID
        self.propertyTitle = propertyTitle
        self.status = status
        self.estimatedRange = estimatedRange
        self.valuationNotice = valuationNotice
        self.digitalMandateName = digitalMandateName
        self.appointments = appointments
        self.photos = photos
    }
}

nonisolated struct PropertyProject: Identifiable, Hashable, Sendable {
    let id: UUID
    let title: String
    let fullAddress: String
    let city: String
    let postalCode: String
    let propertyType: PropertyType
    let description: String
    let desiredPrice: Int
    let idealListingDate: Date
    let extraInformation: String
    let photos: [PhotoAsset]
    let status: ProjectStatus
    let applications: [AgentApplication]
    let selectedAgentID: UUID?
    let requiredRegion: String
    let districtLabel: String
    let feedHighlight: String

    init(
        id: UUID = UUID(),
        title: String,
        fullAddress: String,
        city: String,
        postalCode: String,
        propertyType: PropertyType,
        description: String,
        desiredPrice: Int,
        idealListingDate: Date,
        extraInformation: String,
        photos: [PhotoAsset],
        status: ProjectStatus,
        applications: [AgentApplication],
        selectedAgentID: UUID?,
        requiredRegion: String,
        districtLabel: String,
        feedHighlight: String
    ) {
        self.id = id
        self.title = title
        self.fullAddress = fullAddress
        self.city = city
        self.postalCode = postalCode
        self.propertyType = propertyType
        self.description = description
        self.desiredPrice = desiredPrice
        self.idealListingDate = idealListingDate
        self.extraInformation = extraInformation
        self.photos = photos
        self.status = status
        self.applications = applications
        self.selectedAgentID = selectedAgentID
        self.requiredRegion = requiredRegion
        self.districtLabel = districtLabel
        self.feedHighlight = feedHighlight
    }
}

nonisolated struct ChatMessage: Identifiable, Hashable, Sendable {
    let id: UUID
    let senderName: String
    let senderRole: UserRole
    let text: String
    let sentAt: Date

    init(
        id: UUID = UUID(),
        senderName: String,
        senderRole: UserRole,
        text: String,
        sentAt: Date
    ) {
        self.id = id
        self.senderName = senderName
        self.senderRole = senderRole
        self.text = text
        self.sentAt = sentAt
    }

    func isFrom(role: UserRole?) -> Bool {
        senderRole == role
    }
}

nonisolated struct Conversation: Identifiable, Hashable, Sendable {
    let id: UUID
    let title: String
    let subtitle: String
    let lastMessagePreview: String
    let unreadCount: Int
    let projectTitle: String
    let messages: [ChatMessage]

    init(
        id: UUID = UUID(),
        title: String,
        subtitle: String,
        lastMessagePreview: String,
        unreadCount: Int,
        projectTitle: String,
        messages: [ChatMessage]
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.lastMessagePreview = lastMessagePreview
        self.unreadCount = unreadCount
        self.projectTitle = projectTitle
        self.messages = messages
    }
}

nonisolated struct NotificationItem: Identifiable, Hashable, Sendable {
    let id: UUID
    let title: String
    let body: String
    let symbolName: String
    let date: Date

    init(id: UUID = UUID(), title: String, body: String, symbolName: String, date: Date) {
        self.id = id
        self.title = title
        self.body = body
        self.symbolName = symbolName
        self.date = date
    }
}

nonisolated struct SellerLeadDraft: Sendable {
    var address: String = ""
    var city: String = ""
    var postalCode: String = ""
    var propertyType: PropertyType = .apartment
    var description: String = ""
    var desiredPrice: String = ""
    var idealListingDate: Date = .now.addingTimeInterval(60 * 60 * 24 * 21)
    var extraInformation: String = ""
}

nonisolated struct AgentApplicationDraft: Sendable {
    var message: String = ""
    var commissionText: String = "4.5"
}

nonisolated struct AgentOnboardingDraft: Sendable {
    var photoSymbol: String = "person.crop.circle.fill"
    var firstName: String = ""
    var lastName: String = ""
    var email: String = ""
    var city: String = ""
    var agency: String = ""
    var phoneNumber: String = ""
    var professionalDescription: String = ""

    var isComplete: Bool {
        !firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !lastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        email.trimmingCharacters(in: .whitespacesAndNewlines).isValidEmail &&
        !city.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

nonisolated struct SellerOnboardingDraft: Sendable {
    var firstName: String = ""
    var lastName: String = ""
    var email: String = ""
    var phoneNumber: String = ""

    var isComplete: Bool {
        !firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !lastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        email.trimmingCharacters(in: .whitespacesAndNewlines).isValidEmail &&
        !phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

nonisolated struct SupabaseTableRequirement: Identifiable, Hashable, Sendable {
    let id: UUID
    let name: String
    let purpose: String
    let requiredColumns: [String]

    init(id: UUID = UUID(), name: String, purpose: String, requiredColumns: [String]) {
        self.id = id
        self.name = name
        self.purpose = purpose
        self.requiredColumns = requiredColumns
    }
}

nonisolated enum AppTabSeller: Hashable, Sendable {
    case dashboard
    case mandates
    case messages
    case profile
}

nonisolated enum AppTabAgent: Hashable, Sendable {
    case opportunities
    case discover
    case mandates
    case messages
    case profile
}
extension String {
    var isValidEmail: Bool {
        let pattern = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return range(of: pattern, options: .regularExpression) != nil
    }
}
