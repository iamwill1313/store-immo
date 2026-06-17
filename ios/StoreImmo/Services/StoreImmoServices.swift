import Foundation
import Observation

nonisolated struct ServiceStatus: Identifiable, Hashable, Sendable {
    let id: UUID
    let title: String
    let detail: String
    let symbolName: String
    let isHighlighted: Bool

    init(id: UUID = UUID(), title: String, detail: String, symbolName: String, isHighlighted: Bool = false) {
        self.id = id
        self.title = title
        self.detail = detail
        self.symbolName = symbolName
        self.isHighlighted = isHighlighted
    }
}

nonisolated enum ExternalStackChoice: String, Sendable {
    case supabase
    case stripeCheckout
    case pushReady
}

@Observable
@MainActor
final class StoreImmoReadinessService {
    let backendStatuses: [ServiceStatus] = [
        ServiceStatus(title: "Supabase prêt", detail: "Architecture recommandée pour Auth, Postgres, Storage, Realtime et Edge Functions.", symbolName: "server.rack", isHighlighted: true),
        ServiceStatus(title: "Stripe Checkout", detail: "Parcours externe recommandé pour une première version premium avec back-office agent.", symbolName: "creditcard.trianglebadge.exclamationmark"),
        ServiceStatus(title: "Push transactionnelles", detail: "Flux prévus pour nouveaux projets, candidatures, messages et rendez-vous.", symbolName: "bell.badge")
    ]

    let implementationNotes: [String] = [
        "Supabase Swift recommande la gestion d’auth via onOpenURL pour les retours OAuth et magic links.",
        "Supabase Realtime V2 impose d’enregistrer les callbacks avant subscribe() pour éviter les erreurs de canal.",
        "Stripe recommande Checkout Sessions pour limiter la complexité côté client et côté serveur.",
        "Les notifications doivent rester strictement transactionnelles et pilotées par préférences utilisateur."
    ]

    func badgeText(for plan: SubscriptionPlan) -> String {
        switch plan {
        case .starter:
            "3 actives"
        case .pro:
            "10 actives"
        case .elite:
            "Illimité"
        }
    }
}
