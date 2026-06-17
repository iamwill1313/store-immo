import Foundation
import Observation
import Supabase
import PostgREST
import Auth

// MARK: - Codable DTOs (nonisolated so JSONEncoder can run off-main)

nonisolated struct UserRow: Codable, Sendable {
    let id: String
    let role: String
    let email: String?
    let phone: String?
}

nonisolated struct AgentProfileRow: Codable, Sendable {
    let id: String
    let user_id: String
    let photo_url: String?
    let first_name: String
    let last_name: String
    let email: String
    let city: String
    let agency: String?
    let phone: String
    let description: String?
}

nonisolated struct SellerProfileRow: Codable, Sendable {
    let id: String
    let user_id: String
    let first_name: String
    let last_name: String
    let email: String
    let phone: String
}

nonisolated struct SellerProjectRow: Codable, Sendable {
    let id: String
    let seller_id: String?
    let address: String
    let city: String
    let postal_code: String
    let property_type: String
    let description: String
    let desired_price: Int
    let ideal_listing_date: String
    let status: String
    let selected_agent_id: String?
    let photo_url: String?
}

nonisolated struct ProjectSelectionUpdateRow: Codable, Sendable {
    let id: String
    let selected_agent_id: String
    let status: String
}

nonisolated struct SellerProjectPhotoUpdateRow: Codable, Sendable {
    let id: String
    let photo_url: String
}

nonisolated struct ApplicationRow: Codable, Sendable {
    let id: String
    let project_id: String
    let agent_id: String?
    let message: String
    let commission_percent: Double
    let status: String
}

nonisolated struct MessageRow: Codable, Sendable {
    let id: String
    let conversation_id: String?
    let project_id: String?
    let sender_id: String?
    let receiver_id: String?
    let body: String
}

nonisolated struct NotificationRow: Codable, Sendable {
    let id: String
    let user_id: String?
    let title: String
    let body: String
    let type: String
    let is_read: Bool
}

nonisolated struct SubscriptionRow: Codable, Sendable {
    let id: String
    let agent_id: String?
    let plan: String
    let status: String
}

nonisolated struct PaymentRow: Codable, Sendable {
    let id: String
    let subscription_id: String?
    let amount_cents: Int
    let currency: String
    let status: String
    let plan: String
}

nonisolated struct ReviewRow: Codable, Sendable {
    let id: String
    let project_id: String?
    let agent_id: String?
    let seller_id: String?
    let rating: Double
    let comment: String
    let outcome_tag: String
}

// MARK: - Repository

@Observable
@MainActor
final class SupabaseRepository {
    static let shared = SupabaseRepository()

    private let service = SupabaseService.shared

    private(set) var lastError: String?

    /// Cached id for the current authenticated user (auth.users.id).
    /// Falls back to a generated UUID for demo flows when auth is not signed in.
    var currentUserID: String {
        if let cached = _currentUserID { return cached }
        let generated = UUID().uuidString.lowercased()
        _currentUserID = generated
        return generated
    }
    private var _currentUserID: String?

    private init() {}

    var isConfigured: Bool { service.isConfigured }

    // MARK: - Auth bootstrap

    func bootstrapAuth() async {
        guard let client = service.client else { return }
        if let uid = try? await client.auth.session.user.id.uuidString {
            _currentUserID = uid.lowercased()
        }
    }

    // MARK: - Generic insert with error capture

    @discardableResult
    private func insert<T: Encodable & Sendable>(_ value: T, into table: String) async -> Bool {
        let ok = await service.insert(value, into: table)
        if !ok { lastError = service.lastError ?? "Échec de l'enregistrement (\(table))." }
        return ok
    }

    @discardableResult
    private func upsert<T: Encodable & Sendable>(_ value: T, into table: String, onConflict: String? = nil) async -> Bool {
        print("🟡 Tentative upsert Supabase dans table:", table)
        print("📦 Données envoyées:", value)

        guard let client = service.client else {
            print("❌ Supabase non configuré")
            lastError = "Supabase non configuré."
            return false
        }

        do {
            print("🔥 TABLE =", table)
            if let onConflict {
                try await client.from(table).upsert(value, onConflict: onConflict).execute()
            } else {
                try await client.from(table).upsert(value).execute()
            }

            print("✅ Upsert Supabase réussi dans:", table)
            lastError = nil
            return true
        } catch {
            print("🚨 ERREUR COMPLETE =", error)
            print("❌ Erreur upsert Supabase dans \(table):", error)
            lastError = "Upsert \(table): \(error.localizedDescription)"
            return false
        }
    }

    // MARK: - Users

    @discardableResult
    func upsertUser(role: String, email: String?, phone: String?) async -> Bool {
        await bootstrapAuth()

        let row = UserRow(
            id: currentUserID,
            role: role,
            email: email,
            phone: phone
        )

        return await upsert(row, into: "users", onConflict: "id")
    }

    // MARK: - Profiles

    @discardableResult
    func saveAgentProfile(_ draft: AgentOnboardingDraft) async -> Bool {
        let row = AgentProfileRow(
            id: UUID().uuidString.lowercased(),
            user_id: currentUserID,
            photo_url: nil,
            first_name: draft.firstName,
            last_name: draft.lastName,
            email: draft.email,
            city: draft.city,
            agency: draft.agency.isEmpty ? nil : draft.agency,
            phone: draft.phoneNumber,
            description: draft.professionalDescription.isEmpty ? nil : draft.professionalDescription
        )
        return await upsert(row, into: "agents_profiles", onConflict: "user_id")
    }

    @discardableResult
    func saveSellerProfile(_ draft: SellerOnboardingDraft) async -> Bool {
        let row = SellerProfileRow(
            id: UUID().uuidString.lowercased(),
            user_id: currentUserID,
            first_name: draft.firstName,
            last_name: draft.lastName,
            email: draft.email,
            phone: draft.phoneNumber
        )
        return await upsert(row, into: "sellers_profiles", onConflict: "user_id")
    }

    // MARK: - Projects

    @discardableResult
    func createProject(from draft: SellerLeadDraft, projectID: UUID) async -> Bool {
        let formatter = ISO8601DateFormatter()
        let row = SellerProjectRow(
            id: projectID.uuidString.lowercased(),
            seller_id: currentUserID,
            address: draft.address,
            city: draft.city,
            postal_code: draft.postalCode,
            property_type: draft.propertyType.rawValue,
            description: draft.description,
            desired_price: Int(draft.desiredPrice) ?? 0,
            ideal_listing_date: formatter.string(from: draft.idealListingDate),
            status: ProjectStatus.published.rawValue,
            selected_agent_id: nil,
            photo_url: nil
        )
        return await insert(row, into: "sellers_projects")
    }
    
   
    func updateProjectSelectedAgent(projectID: UUID, selectedAgentID: UUID) async -> Bool {
       
        
        let row = ProjectSelectionUpdateRow(
            id: projectID.uuidString.lowercased(),
            selected_agent_id: selectedAgentID.uuidString.lowercased(),
            status: ProjectStatus.agentChosen.rawValue
        )

        return await upsert(
            row,
            into: "sellers_projects",
            onConflict: "id"
        )
    }
   
    
    // MARK: - Applications

    @discardableResult
    func createApplication(projectID: UUID, commission: Double, message: String) async -> Bool {
        let row = ApplicationRow(
            id: UUID().uuidString.lowercased(),
            project_id: projectID.uuidString.lowercased(),
            agent_id: currentUserID,
            message: message,
            commission_percent: commission,
            status: "pending"
        )
        return await insert(row, into: "applications")
    }

    @discardableResult
    func updateApplicationStatus(applicationID: UUID, status: String) async -> Bool {
        let row = [
            "id": applicationID.uuidString.lowercased(),
            "status": status
        ]

        return await upsert(
            row,
            into: "applications",
            onConflict: "id"
        )
    }
    
    // MARK: - Messages

    @discardableResult
    func sendMessage(
        conversationID: UUID?,
        projectID: UUID?,
        receiverID: String?,
        body: String
    ) async -> Bool {
        let row = MessageRow(
            id: UUID().uuidString.lowercased(),
            conversation_id: conversationID?.uuidString.lowercased(),
            project_id: projectID?.uuidString.lowercased(),
            sender_id: currentUserID,
            receiver_id: receiverID,
            body: body
        )

        return await insert(row, into: "messages")
    }
    
    // MARK: - Notifications

    @discardableResult
    func createNotification(title: String, body: String, type: String) async -> Bool {
        let row = NotificationRow(
            id: UUID().uuidString.lowercased(),
            user_id: currentUserID,
            title: title,
            body: body,
            type: type,
            is_read: false
        )
        return await insert(row, into: "notifications")
    }

    // MARK: - Subscriptions & Payments

    @discardableResult
    func saveSubscription(plan: SubscriptionPlan) async -> Bool {
        let row = SubscriptionRow(
            id: UUID().uuidString.lowercased(),
            agent_id: currentUserID,
            plan: plan.rawValue,
            status: "active"
        )
        return await upsert(row, into: "subscriptions", onConflict: "agent_id")
    }

    @discardableResult
    func recordPayment(plan: SubscriptionPlan) async -> Bool {
        let amount: Int = {
            switch plan {
            case .starter: return 799
            case .pro: return 1999
            case .elite: return 3999
            }
        }()
        let row = PaymentRow(
            id: UUID().uuidString.lowercased(),
            subscription_id: nil,
            amount_cents: amount,
            currency: "EUR",
            status: "succeeded",
            plan: plan.rawValue
        )
        return await insert(row, into: "payments")
    }

    // MARK: - Reviews

    @discardableResult
    func createReview(projectID: UUID?, agentID: UUID?, rating: Double, comment: String, outcome: String) async -> Bool {
        let row = ReviewRow(
            id: UUID().uuidString.lowercased(),
            project_id: projectID?.uuidString.lowercased(),
            agent_id: agentID?.uuidString.lowercased(),
            seller_id: currentUserID,
            rating: rating,
            comment: comment,
            outcome_tag: outcome
        )
        return await insert(row, into: "reviews")
    }
    func uploadProjectPhoto(
        projectID: UUID,
        imageData: Data
    ) async -> String? {

        guard let client = service.client else {
            return nil
        }

        let fileName = "\(projectID.uuidString.lowercased()).jpg"

        do {
            try await client.storage
                .from("project-photos")
                .upload(
                    path: fileName,
                    file: imageData,
                    options: FileOptions(
                        cacheControl: "3600",
                        upsert: true
                    )
                )

            let publicURL = try client.storage
                .from("project-photos")
                .getPublicURL(path: fileName)

            let urlString = publicURL.absoluteString
            print("📸 URL PHOTO =", urlString)

            let updateRow = SellerProjectPhotoUpdateRow(
                id: projectID.uuidString.lowercased(),
                photo_url: urlString
            )
            await upsert(updateRow, into: "sellers_projects", onConflict: "id")

            return urlString

        } catch {
            print("🚨 Upload photo erreur =", error)
            return nil
        }
    }
}
