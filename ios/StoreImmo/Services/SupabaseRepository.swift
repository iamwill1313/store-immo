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
    let created_at: String?
    let profile_photo_url: String?
    let push_token: String?
}

nonisolated struct SellerProfileRow: Codable, Sendable {
    let id: String
    let user_id: String
    let first_name: String
    let last_name: String
    let email: String
    let phone: String
    let push_token: String?
}

nonisolated struct SellerProjectRow: Codable, Sendable {
    let id: String
    let seller_id: String?
    let address: String
    let city: String
    let postal_code: String
    let property_type: String
    let typology: String?
    let description: String
    let desired_price: Int
    let ideal_listing_date: String
    let status: String
    let selected_agent_id: String?
    let photo_url: String?
}

nonisolated struct SellerProjectUpdateRow: Codable, Sendable {
    let address: String
    let city: String
    let postal_code: String
    let property_type: String
    let typology: String
    let description: String
    let desired_price: Int
    let ideal_listing_date: String
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

/// Read-only DTO — used when FETCHING from `applications`. All nullable columns optional.
nonisolated struct ApplicationRow: Codable, Sendable {
    let id: String
    let project_id: String
    let agent_id: String?
    let seller_id: String?
    let message: String
    let commission_percent: Double
    let status: String
    let created_at: String?
    let seller_has_seen: Bool?
}

/// Write-only DTO — used when INSERTING into `applications`.
/// Only includes columns that exist in the table.
/// seller_id is intentionally absent: the seller retrieves applications via
/// fetchApplicationsForProjects(projectIDs:) which filters by project_id.
nonisolated struct ApplicationInsertRow: Encodable, Sendable {
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

nonisolated struct AnalyticsEventRow: Codable, Sendable {
    let event_name: String
    let user_id: String?
    let session_id: String
}

nonisolated struct NotificationRow: Codable, Sendable {
    let id: String
    let user_id: String?
    let title: String
    let body: String
    let type: String
    let is_read: Bool
    let related_project_id: String?
    let related_conversation_id: String?
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

nonisolated struct ConversationInsertRow: Codable, Sendable {
    let id: String
    let project_id: String
    let seller_id: String
    let agent_id: String
}

nonisolated struct ConversationFetchRow: Codable, Sendable {
    let id: String
    let project_id: String?
    let seller_id: String?
    let agent_id: String?
}

nonisolated struct MessageFetchRow: Codable, Sendable {
    let id: String
    let conversation_id: String?
    let sender_id: String?
    let receiver_id: String?
    let body: String
    let created_at: String?
    let is_read: Bool?
}

nonisolated struct NotificationFetchRow: Codable, Sendable {
    let id: String
    let user_id: String?
    let title: String
    let body: String
    let type: String
    let is_read: Bool
    let created_at: String?
    let related_project_id: String?
    let related_conversation_id: String?
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

    /// Clears the cached user ID so the next bootstrapAuth() fetches the correct session.
    /// Call this on sign-out and before bootstrapping a new login.
    func resetUserID() {
        _currentUserID = nil
    }

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
            email: email?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
            phone: phone
        )

        // Conflict on email (not id): if a stale row exists from a pre-OTP call with a random UUID,
        // this UPDATE sets id to the real auth.uid() so FK references stay valid.
        return await upsert(row, into: "users", onConflict: "email")
    }

    /// Returns true if an account with this email already exists in `users` (case-insensitive).
    /// Returns false when Supabase is not configured so demo mode is never blocked.
    func emailExists(email: String) async -> Bool {
        guard let client = service.client else { return false }
        let normalized = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !normalized.isEmpty else { return false }
        do {
            let rows: [UserRow] = try await client
                .from("users")
                .select()
                .ilike("email", pattern: normalized)
                .execute()
                .value
            return !rows.isEmpty
        } catch {
            print("🚨 emailExists erreur:", error)
            return false
        }
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
            description: draft.professionalDescription.isEmpty ? nil : draft.professionalDescription,
            created_at: nil,
            profile_photo_url: nil,
            push_token: nil
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
            phone: draft.phoneNumber,
            push_token: nil
        )
        return await upsert(row, into: "sellers_profiles", onConflict: "user_id")
    }

    // MARK: - Projects

    @discardableResult
    func createProject(from draft: SellerLeadDraft, projectID: UUID) async -> Bool {
        let dateFormatter: DateFormatter = {
            let f = DateFormatter()
            f.dateFormat = "yyyy-MM-dd"
            f.locale = Locale(identifier: "en_US_POSIX")
            return f
        }()

        let sellerID = currentUserID
        print("🔵 createProject — seller_id:", sellerID, "project:", projectID.uuidString.lowercased().prefix(8))
        print("🔵 ideal_listing_date:", dateFormatter.string(from: draft.idealListingDate))

        let row = SellerProjectRow(
            id: projectID.uuidString.lowercased(),
            seller_id: sellerID,
            address: draft.address,
            city: draft.city,
            postal_code: draft.postalCode,
            property_type: draft.propertyType.rawValue,
            typology: draft.typology.rawValue,
            description: draft.description,
            desired_price: Int(draft.desiredPrice) ?? 0,
            ideal_listing_date: dateFormatter.string(from: draft.idealListingDate),
            status: ProjectStatus.published.rawValue,
            selected_agent_id: nil,
            photo_url: nil
        )

        let ok = await insert(row, into: "sellers_projects")
        guard ok, let client = service.client else { return ok }

        // Verify the row actually landed in the DB — detects silent RLS blocks.
        // If RLS has no INSERT policy, PostgREST inserts 0 rows without throwing.
        do {
            let rows: [SellerProjectRow] = try await client
                .from("sellers_projects")
                .select()
                .eq("id", value: projectID.uuidString.lowercased())
                .execute()
                .value
            if rows.isEmpty {
                print("⚠️ PROJET NON TROUVÉ après insert — RLS a bloqué silencieusement l'insertion")
                print("⚠️ seller_id utilisé:", sellerID)
                print("⚠️ Action requise : dans le Dashboard Supabase → sellers_projects → RLS → ajouter politique INSERT avec : auth.uid() = seller_id")
                lastError = "Projet non enregistré (RLS bloquant). Dans Supabase Dashboard → sellers_projects → Policies → Add Policy INSERT : WITH CHECK (auth.uid() = seller_id)."
                return false
            }
            print("✅ Projet confirmé en DB:", projectID.uuidString.lowercased().prefix(8))
        } catch {
            print("⚠️ Vérification post-insert échouée:", error.localizedDescription)
        }

        return ok
    }
    
   
    func updateProjectSelectedAgent(projectID: UUID, selectedAgentID: UUID) async -> Bool {
        guard let client = service.client else { return false }
        do {
            try await client.from("sellers_projects")
                .update([
                    "selected_agent_id": selectedAgentID.uuidString.lowercased(),
                    "status": ProjectStatus.agentChosen.rawValue
                ])
                .eq("id", value: projectID.uuidString.lowercased())
                .eq("seller_id", value: currentUserID)
                .execute()
            return true
        } catch {
            print("🚨 updateProjectSelectedAgent erreur:", error)
            return false
        }
    }
   
    
    func updateSellerProject(
        projectID: UUID,
        address: String,
        city: String,
        postalCode: String,
        propertyType: String,
        typology: String,
        description: String,
        desiredPrice: Int,
        idealListingDate: String
    ) async -> Bool {
        guard let client = service.client else { return false }
        let row = SellerProjectUpdateRow(
            address: address,
            city: city,
            postal_code: postalCode,
            property_type: propertyType,
            typology: typology,
            description: description,
            desired_price: desiredPrice,
            ideal_listing_date: idealListingDate
        )
        do {
            try await client
                .from("sellers_projects")
                .update(row)
                .eq("id", value: projectID.uuidString.lowercased())
                .eq("seller_id", value: currentUserID)
                .execute()
            print("✅ updateSellerProject OK:", projectID.uuidString.prefix(8))
            return true
        } catch {
            print("🚨 updateSellerProject erreur:", error)
            lastError = error.localizedDescription
            return false
        }
    }

    func archiveSellerProject(projectID: UUID) async -> Bool {
        guard let client = service.client else { return false }
        do {
            try await client
                .from("sellers_projects")
                .update(["status": ProjectStatus.deleted.rawValue])
                .eq("id", value: projectID.uuidString.lowercased())
                .eq("seller_id", value: currentUserID)
                .execute()
            print("✅ archiveSellerProject OK:", projectID.uuidString.prefix(8))
            return true
        } catch {
            print("🚨 archiveSellerProject erreur:", error)
            lastError = error.localizedDescription
            return false
        }
    }

    // MARK: - Applications

    /// Returns true if the current authenticated agent already has an application for this project.
    /// Calls bootstrapAuth() first to guarantee currentUserID == auth.uid().
    func checkApplicationExists(projectID: UUID) async -> Bool {
        await bootstrapAuth()
        guard let client = service.client else { return false }
        do {
            let rows: [ApplicationRow] = try await client
                .from("applications")
                .select()
                .eq("agent_id", value: currentUserID)
                .eq("project_id", value: projectID.uuidString.lowercased())
                .limit(1)
                .execute()
                .value
            print("🔍 checkApplicationExists — agent:", currentUserID.prefix(8), "project:", projectID.uuidString.prefix(8), "→", rows.isEmpty ? "aucune" : "EXISTE")
            return !rows.isEmpty
        } catch {
            print("🚨 checkApplicationExists erreur:", error)
            return false
        }
    }

    @discardableResult
    func createApplication(projectID: UUID, commission: Double, message: String) async -> Bool {
        // Ensure we have the real auth.uid() before building the row.
        await bootstrapAuth()
        let rowID = UUID().uuidString.lowercased()
        let row = ApplicationInsertRow(
            id: rowID,
            project_id: projectID.uuidString.lowercased(),
            agent_id: currentUserID,
            message: message,
            commission_percent: commission,
            status: "pending"
        )
        print("📩 createApplication — id:", rowID.prefix(8), "project:", projectID.uuidString.lowercased().prefix(8), "agent:", currentUserID.prefix(8))
        let ok = await insert(row, into: "applications")
        guard ok, let client = service.client else {
            print("🚨 createApplication INSERT ECHOUE — lastError:", lastError ?? "nil")
            return false
        }

        // Post-insert verification: detects silent RLS blocks (same pattern as createProject).
        // Supabase can return HTTP 201 with 0 rows inserted when RLS has no INSERT policy.
        do {
            let rows: [ApplicationRow] = try await client
                .from("applications")
                .select()
                .eq("id", value: rowID)
                .execute()
                .value
            if rows.isEmpty {
                print("⚠️ CANDIDATURE NON TROUVÉE après insert — RLS bloquant ou contrainte FK")
                print("⚠️ Action Supabase Dashboard requise :")
                print("   → applications → RLS → Add Policy INSERT : WITH CHECK (auth.uid()::text = agent_id)")
                print("   → applications → RLS → Add Policy SELECT : USING (auth.uid()::text = agent_id OR auth.uid()::text = seller_id)")
                lastError = "Candidature non enregistrée (RLS bloquant). Ajoutez une politique INSERT sur la table applications dans Supabase Dashboard."
                return false
            }
            print("✅ Candidature confirmée en DB:", rowID.prefix(8))
        } catch {
            print("⚠️ Vérification post-insert candidature échouée:", error.localizedDescription)
        }
        return ok
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
        await bootstrapAuth()
        let messageID = UUID().uuidString.lowercased()
        let convIDStr = conversationID?.uuidString.lowercased()
        let row = MessageRow(
            id: messageID,
            conversation_id: convIDStr,
            project_id: projectID?.uuidString.lowercased(),
            sender_id: currentUserID,
            receiver_id: receiverID,
            body: body
        )

        print("💬 [sendMessage] ===== INSERT MESSAGE DANS SUPABASE =====")
        print("💬 [sendMessage] Message ID:", messageID.prefix(8))
        print("💬 [sendMessage] conversation_id (complet):", convIDStr ?? "nil")
        print("💬 [sendMessage] conversation_id (8 premiers):", convIDStr?.prefix(8) ?? "nil")
        print("💬 [sendMessage] sender_id:", currentUserID.prefix(8))
        print("💬 [sendMessage] receiver_id:", receiverID?.prefix(8) ?? "nil")
        print("💬 [sendMessage] body:", body.prefix(50))

        let ok = await insert(row, into: "messages")
        
        if ok {
            print("💬 [sendMessage] ✅ INSERT réussi — message ID:", messageID.prefix(8))
            print("💬 [sendMessage] ✅ Le message est maintenant dans la table 'messages' avec conversation_id =", convIDStr?.prefix(8) ?? "nil")
        } else {
            print("💬 [sendMessage] ❌ INSERT ECHOUE:", lastError ?? "unknown")
        }
        
        return ok
    }
    
    // MARK: - Push Tokens

    func savePushToken(_ token: String) async {
        guard let client = service.client else { return }
        let userID = currentUserID
        guard !userID.isEmpty else { return }
        print("[Push] Sauvegarde token pour userID:", userID.prefix(8))
        // Update both tables — only one will match depending on the user's role
        do {
            try await client.from("agents_profiles")
                .update(["push_token": token])
                .eq("user_id", value: userID)
                .execute()
        } catch {
            print("[Push] agents_profiles token erreur:", error)
        }
        do {
            try await client.from("sellers_profiles")
                .update(["push_token": token])
                .eq("user_id", value: userID)
                .execute()
        } catch {
            print("[Push] sellers_profiles token erreur:", error)
        }
    }

    func fetchAgentUserIDsForCity(_ city: String) async -> [String] {
        guard let client = service.client, !city.isEmpty else { return [] }
        do {
            let rows: [AgentProfileRow] = try await client
                .from("agents_profiles")
                .select()
                .eq("city", value: city)
                .execute()
                .value
            return rows.map { $0.user_id }
        } catch {
            print("[Push] fetchAgentUserIDsForCity erreur:", error)
            return []
        }
    }

    func notifyAgentsInCityForNewProject(city: String, projectID: String) async {
        let agentUserIDs = await fetchAgentUserIDsForCity(city)
        guard !agentUserIDs.isEmpty else { return }
        print("[Push] Notification nouveau projet à \(city) — \(agentUserIDs.count) agent(s)")
        for agentID in agentUserIDs {
            await createNotificationForUser(
                userID: agentID,
                title: "Nouveau projet disponible",
                body: "Un nouveau projet à \(city) vient d'être publié.",
                type: "new_project",
                relatedProjectId: projectID
            )
        }
    }

    // MARK: - Notifications

    /// Creates a notification for the CURRENT user.
    @discardableResult
    func createNotification(
        title: String,
        body: String,
        type: String,
        relatedProjectId: String? = nil,
        relatedConversationId: String? = nil
    ) async -> Bool {
        let row = NotificationRow(
            id: UUID().uuidString.lowercased(),
            user_id: currentUserID,
            title: title,
            body: body,
            type: type,
            is_read: false,
            related_project_id: relatedProjectId,
            related_conversation_id: relatedConversationId
        )
        return await insert(row, into: "notifications")
    }

    /// Creates a notification for ANY user (cross-user: agent notifies seller and vice versa).
    /// Requires permissive INSERT RLS on the notifications table.
    @discardableResult
    func createNotificationForUser(
        userID: String,
        title: String,
        body: String,
        type: String,
        relatedProjectId: String? = nil,
        relatedConversationId: String? = nil
    ) async -> Bool {
        guard !userID.isEmpty else {
            print("🔔 [createNotificationForUser] ❌ userID vide")
            return false
        }
        let row = NotificationRow(
            id: UUID().uuidString.lowercased(),
            user_id: userID,
            title: title,
            body: body,
            type: type,
            is_read: false,
            related_project_id: relatedProjectId,
            related_conversation_id: relatedConversationId
        )
        print("🔔 [createNotificationForUser] Insertion notification:")
        print("🔔   - id:", row.id)
        print("🔔   - user_id:", row.user_id)
        print("🔔   - type:", row.type)
        print("🔔   - title:", row.title)
        print("🔔   - related_conversation_id:", row.related_conversation_id ?? "nil")
        
        let result = await insert(row, into: "notifications")
        print("🔔 [createNotificationForUser] Résultat insertion:", result ? "✅" : "❌")
        return result
    }

    /// Marks a notification as read for the current user.
    @discardableResult
    func markNotificationRead(id: String) async -> Bool {
        guard let client = service.client else { return false }
        do {
            try await client
                .from("notifications")
                .update(["is_read": true])
                .eq("id", value: id)
                .execute()
            return true
        } catch {
            print("🚨 markNotificationRead erreur:", error)
            return false
        }
    }

    func markMessagesRead(conversationID: UUID) async {
        guard let client = service.client else { return }
        let uid = currentUserID
        do {
            try await client
                .from("messages")
                .update(["is_read": true])
                .eq("conversation_id", value: conversationID.uuidString.lowercased())
                .neq("sender_id", value: uid)
                .execute()
        } catch {
            print("🚨 markMessagesRead erreur:", error)
        }
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
    // MARK: - Project fetch

    func fetchSellerProjects(sellerID: String) async -> [SellerProjectRow] {
        guard let client = service.client else { return [] }
        do {
            let rows: [SellerProjectRow] = try await client
                .from("sellers_projects")
                .select()
                .eq("seller_id", value: sellerID)
                .neq("status", value: ProjectStatus.deleted.rawValue)
                .execute()
                .value
            return rows
        } catch {
            print("🚨 fetchSellerProjects erreur:", error)
            return []
        }
    }

    // MARK: - Profile fetch

    func fetchSellerProfile(byEmail email: String) async -> SellerProfileRow? {
        guard let client = service.client else { return nil }
        let normalized = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !normalized.isEmpty else { return nil }
        do {
            let rows: [SellerProfileRow] = try await client
                .from("sellers_profiles")
                .select()
                .ilike("email", pattern: normalized)
                .limit(1)
                .execute()
                .value
            return rows.first
        } catch {
            print("🚨 fetchSellerProfile erreur:", error)
            return nil
        }
    }

    // MARK: - Photos

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
                    fileName,
                    data: imageData,
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

            do {
                try await client.from("sellers_projects")
                    .update(["photo_url": urlString])
                    .eq("id", value: projectID.uuidString.lowercased())
                    .execute()
            } catch {
                print("🚨 Photo URL update erreur:", error)
            }

            return urlString

        } catch {
            print("🚨 Upload photo erreur =", error)
            return nil
        }
    }

    func uploadProjectPhotos(projectID: UUID, photoDatas: [Data?]) async -> [String?] {
        guard let client = service.client else {
            return Array(repeating: nil, count: photoDatas.count)
        }
        var urls: [String?] = Array(repeating: nil, count: photoDatas.count)
        for (i, data) in photoDatas.enumerated() {
            guard let data else { continue }
            let suffix = i == 0 ? "" : "_\(i)"
            let fileName = "\(projectID.uuidString.lowercased())\(suffix).jpg"
            do {
                try await client.storage
                    .from("project-photos")
                    .upload(fileName, data: data, options: FileOptions(cacheControl: "3600", upsert: true))
                let publicURL = try client.storage.from("project-photos").getPublicURL(path: fileName)
                let urlString = publicURL.absoluteString
                urls[i] = urlString
                if i == 0 {
                    do {
                        try await client.from("sellers_projects")
                            .update(["photo_url": urlString])
                            .eq("id", value: projectID.uuidString.lowercased())
                            .execute()
                    } catch {
                        print("🚨 Photo URL update erreur:", error)
                    }
                    print("📸 URL PHOTO[0] =", urlString)
                }
            } catch {
                print("🚨 Upload photo[\(i)] erreur =", error)
            }
        }
        return urls
    }

    // MARK: - Conversations

    /// Finds an existing conversation for the (project, seller, agent) triple, or creates one.
    /// Returns the conversation UUID string, or nil on failure.
    func findOrCreateConversation(projectID: UUID, sellerID: String, agentID: String, newID: UUID) async -> String? {
        print("💬 [findOrCreateConversation] ===== RECHERCHE OU CRÉATION CONVERSATION =====")
        print("💬 [findOrCreateConversation] project_id:", projectID.uuidString.lowercased().prefix(8))
        print("💬 [findOrCreateConversation] seller_id:", sellerID.lowercased().prefix(8))
        print("💬 [findOrCreateConversation] agent_id:", agentID.lowercased().prefix(8))
        print("💬 [findOrCreateConversation] tentative newID:", newID.uuidString.lowercased().prefix(8))
        
        // 1. Try to find an existing conversation first (avoids duplicates).
        if let existing = await fetchConversationByParticipants(projectID: projectID, sellerID: sellerID, agentID: agentID) {
            print("💬 [findOrCreateConversation] ✅ CONVERSATION EXISTANTE TROUVÉE")
            print("💬 [findOrCreateConversation] ID existant (complet):", existing.id)
            print("💬 [findOrCreateConversation] ID existant (8 premiers):", existing.id.prefix(8))
            print("💬 [findOrCreateConversation] ⚠️ IMPORTANT: tentativeID sera remplacé par cet ID existant")
            return existing.id
        }
        // 2. None found — insert a new one.
        print("💬 [findOrCreateConversation] ℹ️ Aucune conversation existante — création d'une nouvelle")
        let row = ConversationInsertRow(
            id: newID.uuidString.lowercased(),
            project_id: projectID.uuidString.lowercased(),
            seller_id: sellerID.lowercased(),
            agent_id: agentID.lowercased()
        )
        let ok = await insert(row, into: "conversations")
        if ok {
            print("💬 [findOrCreateConversation] ✅ NOUVELLE CONVERSATION CRÉÉE")
            print("💬 [findOrCreateConversation] ID (complet):", newID.uuidString.lowercased())
            print("💬 [findOrCreateConversation] ID (8 premiers):", newID.uuidString.lowercased().prefix(8))
            return newID.uuidString.lowercased()
        }
        print("🚨 [findOrCreateConversation] ❌ ÉCHEC création conversation")
        return nil
    }

    /// Fetches a single conversation matching the (project, seller, agent) triple.
    func fetchConversationByParticipants(projectID: UUID, sellerID: String, agentID: String) async -> ConversationFetchRow? {
        guard let client = service.client else { return nil }
        do {
            let rows: [ConversationFetchRow] = try await client
                .from("conversations")
                .select()
                .eq("project_id", value: projectID.uuidString.lowercased())
                .eq("seller_id", value: sellerID.lowercased())
                .eq("agent_id", value: agentID.lowercased())
                .limit(1)
                .execute()
                .value
            return rows.first
        } catch {
            print("🚨 fetchConversationByParticipants erreur:", error)
            return nil
        }
    }

    @discardableResult
    func createConversation(id: UUID, projectID: UUID, sellerID: String, agentID: String) async -> Bool {
        let row = ConversationInsertRow(
            id: id.uuidString.lowercased(),
            project_id: projectID.uuidString.lowercased(),
            seller_id: sellerID.lowercased(),
            agent_id: agentID.lowercased()
        )
        return await insert(row, into: "conversations")
    }

    func fetchConversationsForUser(userID: String) async -> [ConversationFetchRow] {
        guard let client = service.client else { return [] }
        do {
            let rows: [ConversationFetchRow] = try await client
                .from("conversations")
                .select()
                .or("seller_id.eq.\(userID),agent_id.eq.\(userID)")
                .execute()
                .value
            return rows
        } catch {
            print("🚨 fetchConversations erreur:", error)
            return []
        }
    }

    func fetchMessages(conversationID: String) async -> [MessageFetchRow] {
        guard let client = service.client else { return [] }
        do {
            let rows: [MessageFetchRow] = try await client
                .from("messages")
                .select()
                .eq("conversation_id", value: conversationID)
                .order("created_at", ascending: true)
                .execute()
                .value
            return rows
        } catch {
            print("🚨 fetchMessages erreur:", error)
            return []
        }
    }

    // MARK: - Notifications fetch

    func fetchNotifications() async -> [NotificationFetchRow] {
        guard let client = service.client else { return [] }
        do {
            let rows: [NotificationFetchRow] = try await client
                .from("notifications")
                .select()
                .eq("user_id", value: currentUserID)
                .order("created_at", ascending: false)
                .limit(30)
                .execute()
                .value
            return rows
        } catch {
            print("🚨 fetchNotifications erreur:", error)
            return []
        }
    }

    // MARK: - Subscription fetch

    func fetchActiveSubscription(agentID: String) async -> SubscriptionRow? {
        guard let client = service.client else { return nil }
        do {
            let rows: [SubscriptionRow] = try await client
                .from("subscriptions")
                .select()
                .eq("agent_id", value: agentID)
                .eq("status", value: "active")
                .limit(1)
                .execute()
                .value
            return rows.first
        } catch {
            print("🚨 fetchActiveSubscription erreur:", error)
            return nil
        }
    }

    // MARK: - Analytics

    @discardableResult
    func logAnalyticsEvent(name: String, sessionID: String) async -> Bool {
        guard isConfigured else { return false }
        let row = AnalyticsEventRow(
            event_name: name,
            user_id: currentUserID.isEmpty ? nil : currentUserID,
            session_id: sessionID
        )
        return await insert(row, into: "analytics_events")
    }

    // MARK: - Agent applications fetch

    func fetchAgentApplications(agentID: String) async -> [ApplicationRow] {
        guard let client = service.client else { return [] }
        do {
            let rows: [ApplicationRow] = try await client
                .from("applications")
                .select()
                .eq("agent_id", value: agentID)
                .execute()
                .value
            return rows
        } catch {
            print("🚨 fetchAgentApplications erreur:", error)
            return []
        }
    }

    func markApplicationSeenBySeller(applicationID: UUID) async -> Bool {
        guard let client = service.client else { return false }
        do {
            try await client
                .from("applications")
                .update(["seller_has_seen": true])
                .eq("id", value: applicationID.uuidString.lowercased())
                .execute()
            return true
        } catch {
            print("🚨 markApplicationSeenBySeller erreur:", error)
            return false
        }
    }

    /// Starts a Supabase real-time subscription for INSERT events on the notifications table.
    /// Calls onNew on the main actor when a new notification targets userID.
    func startNotificationsRealtime(
        userID: String,
        onNew: @MainActor @escaping () async -> Void
    ) -> Task<Void, Never> {
        return Task.detached {
            guard let client = self.service.client else { return }
            let channelName = "user-notifs-\(userID.prefix(8))"
            let channel = client.channel(channelName)
            let insertions = channel.postgresChange(InsertAction.self, schema: "public", table: "notifications")
            await channel.subscribe()
            print("🔔 [Realtime] Connecté notifications pour user:", userID)
            for await action in insertions {
                print("🔔 [Realtime] Notification INSERT reçue")
                print("🔔 [Realtime] Record:", action.record)
                if let uid = action.record["user_id"]?.stringValue,
                   uid.lowercased() == userID.lowercased() {
                    print("🔔 [Realtime] ✅ Notification pour cet utilisateur (user_id match)")
                    print("🔔 [Realtime] Notification user_id:", uid)
                    print("🔔 [Realtime] Current user:", userID)
                    await onNew()
                } else {
                    print("🔔 [Realtime] ❌ Notification ignorée (user_id mismatch)")
                    if let uid = action.record["user_id"]?.stringValue {
                        print("🔔 [Realtime] Notification user_id:", uid)
                        print("🔔 [Realtime] Current user:", userID)
                    }
                }
            }
        }
    }

    /// Starts a Supabase real-time subscription for INSERT events on the applications table.
    /// Calls onNewApplication on the main actor when a new application targets one of projectIDs.
    func startApplicationsRealtime(
        projectIDs: [String],
        onNewApplication: @MainActor @escaping () async -> Void
    ) -> Task<Void, Never> {
        let userID = currentUserID
        return Task.detached {
            guard let client = self.service.client else { return }
            let channelName = "seller-apps-\(userID.prefix(8))"
            let channel = client.channel(channelName)
            let insertions = channel.postgresChange(InsertAction.self, schema: "public", table: "applications")
            await channel.subscribe()
            for await action in insertions {
                if let pid = action.record["project_id"]?.stringValue,
                   projectIDs.contains(pid.lowercased()) {
                    await onNewApplication()
                }
            }
        }
    }

    /// Starts a Supabase real-time subscription for INSERT events on the messages table.
    /// Calls onNewMessage on the main actor when a new message is sent in the given conversationID.
    func startMessagesRealtime(
        conversationID: String,
        onNewMessage: @MainActor @escaping () async -> Void
    ) -> Task<Void, Never> {
        let userID = currentUserID
        return Task.detached {
            guard let client = self.service.client else { return }
            let channelName = "conv-msgs-\(conversationID.prefix(8))"
            let channel = client.channel(channelName)
            let insertions = channel.postgresChange(InsertAction.self, schema: "public", table: "messages")
            await channel.subscribe()
            print("💬 [Realtime] ===== CONNECTÉ REALTIME MESSAGES =====")
            print("💬 [Realtime] Channel:", channelName)
            print("💬 [Realtime] Écoute conversation_id (complet):", conversationID)
            print("💬 [Realtime] Écoute conversation_id (8 premiers):", conversationID.prefix(8))
            for await action in insertions {
                print("💬 [Realtime] ===== MESSAGE INSERT REÇU =====")
                print("💬 [Realtime] Record complet:", action.record)
                if let convID = action.record["conversation_id"]?.stringValue {
                    print("💬 [Realtime] conversation_id du message (complet):", convID)
                    print("💬 [Realtime] conversation_id du message (8 premiers):", convID.prefix(8))
                    print("💬 [Realtime] conversation_id attendu (complet):", conversationID)
                    print("💬 [Realtime] conversation_id attendu (8 premiers):", conversationID.prefix(8))
                    print("💬 [Realtime] Comparaison (lowercase):", convID.lowercased(), "==", conversationID.lowercased(), "?", convID.lowercased() == conversationID.lowercased())
                    if convID.lowercased() == conversationID.lowercased() {
                        print("💬 [Realtime] ✅ MATCH — Message pour cette conversation")
                        await onNewMessage()
                    } else {
                        print("💬 [Realtime] ❌ MISMATCH — Message ignoré (conversation_id différent)")
                    }
                } else {
                    print("💬 [Realtime] ⚠️ Message SANS conversation_id")
                }
            }
        }
    }

    // MARK: - Filtered fetches (Priority F)

    /// Fetch only applications that belong to the given project IDs (seller-scoped).
    func fetchApplicationsForProjects(projectIDs: [String]) async -> [ApplicationRow] {
        guard let client = service.client, !projectIDs.isEmpty else { return [] }
        print("🔍 fetchApplicationsForProjects — project IDs:", projectIDs.map { String($0.prefix(8)) })
        do {
            let rows: [ApplicationRow] = try await client
                .from("applications")
                .select()
                .in("project_id", values: projectIDs)
                .order("created_at", ascending: false)
                .execute()
                .value
            print("📊 fetchApplicationsForProjects — résultat:", rows.count, "candidature(s)")
            return rows
        } catch {
            print("🚨 fetchApplicationsForProjects erreur (possible RLS):", error)
            return []
        }
    }

    /// Fetch seller profiles by their user_id list (used by agent-side conversation display).
    func fetchSellerProfilesByUserIDs(_ userIDs: [String]) async -> [SellerProfileRow] {
        guard let client = service.client, !userIDs.isEmpty else { return [] }
        do {
            let rows: [SellerProfileRow] = try await client
                .from("sellers_profiles")
                .select()
                .in("user_id", values: userIDs)
                .execute()
                .value
            return rows
        } catch {
            print("🚨 fetchSellerProfilesByUserIDs erreur:", error)
            return []
        }
    }

    /// Fetch agent profiles by their user_id list (applicants for a seller's projects).
    func fetchAgentProfilesByUserIDs(_ userIDs: [String]) async -> [AgentProfileRow] {
        guard let client = service.client, !userIDs.isEmpty else { return [] }
        do {
            let rows: [AgentProfileRow] = try await client
                .from("agents_profiles")
                .select()
                .in("user_id", values: userIDs)
                .execute()
                .value
            return rows
        } catch {
            print("🚨 fetchAgentProfilesByUserIDs erreur:", error)
            return []
        }
    }

    // MARK: - Own agent profile fetch (Priority C)

    /// Fetch the agent's own profile row after re-login.
    func fetchAgentProfile(agentID: String) async -> AgentProfileRow? {
        guard let client = service.client else { return nil }
        do {
            let rows: [AgentProfileRow] = try await client
                .from("agents_profiles")
                .select()
                .eq("user_id", value: agentID)
                .limit(1)
                .execute()
                .value
            return rows.first
        } catch {
            print("🚨 fetchAgentProfile erreur:", error)
            return nil
        }
    }

    // MARK: - Trust Indicators

    /// Builds verifiable trust indicators for an agent from real app data.
    /// Combines the agent's registration date (memberSince) with computed response time.
    func buildAgentTrustIndicators(agent: AgentProfile) async -> AgentTrustIndicators {
        let avgMinutes = await fetchAgentAverageResponseMinutes(agentID: agent.id.uuidString)
        let responseLabel = avgMinutes.map { AgentProfile.responseTimeLabel($0) }
            ?? "Temps de réponse en cours de calcul"
        return AgentTrustIndicators(
            memberSince: agent.trustIndicators.memberSince,
            responseTime: responseLabel,
            recentActivity: agent.trustIndicators.recentActivity
        )
    }

    // MARK: - Agent Profile Photo

    func uploadAgentProfilePhoto(_ data: Data, agentID: String) async -> String? {
        guard let client = service.client else { return nil }
        let fileName = "\(agentID).jpg"
        print("[Photo profil] Upload démarré — agentID:", agentID)
        do {
            try await client.storage
                .from("profile-photos")
                .upload(fileName, data: data, options: FileOptions(cacheControl: "3600", upsert: true))
            let publicURL = try client.storage
                .from("profile-photos")
                .getPublicURL(path: fileName)
            // Append cache-buster so AsyncImage reloads when the photo is replaced at the same path
            let version = Int(Date().timeIntervalSince1970)
            let urlString = publicURL.absoluteString + "?v=\(version)"
            print("[Photo profil] URL publique:", urlString)
            try await client.from("agents_profiles")
                .update(["profile_photo_url": urlString])
                .eq("user_id", value: agentID)
                .execute()
            return urlString
        } catch {
            print("[Photo profil] Erreur upload:", error)
            return nil
        }
    }

    @discardableResult
    func updateAgentProfilePhotoURL(_ url: String?, agentID: String) async -> Bool {
        guard let client = service.client else { return false }
        do {
            if let url {
                try await client.from("agents_profiles")
                    .update(["profile_photo_url": url])
                    .eq("user_id", value: agentID)
                    .execute()
            } else {
                try await client.from("agents_profiles")
                    .update(["profile_photo_url": String?.none])
                    .eq("user_id", value: agentID)
                    .execute()
            }
            return true
        } catch {
            print("🚨 updateAgentProfilePhotoURL erreur:", error)
            return false
        }
    }

    private func fetchAgentAverageResponseMinutes(agentID: String) async -> Double? {
        guard let client = service.client else { return nil }
        do {
            let convRows: [ConversationFetchRow] = try await client
                .from("conversations")
                .select()
                .eq("agent_id", value: agentID)
                .execute()
                .value
            guard !convRows.isEmpty else { return nil }
            let convIDs = convRows.map { $0.id }

            let messages: [MessageFetchRow] = try await client
                .from("messages")
                .select()
                .in("conversation_id", values: convIDs)
                .order("created_at", ascending: true)
                .execute()
                .value

            let isoParser = ISO8601DateFormatter()
            let grouped = Dictionary(grouping: messages, by: { $0.conversation_id ?? "" })
            var deltas: [Double] = []

            for (_, convMsgs) in grouped {
                let sellerMsgs = convMsgs.filter { $0.sender_id != agentID }
                let agentMsgs  = convMsgs.filter { $0.sender_id == agentID }
                for sellerMsg in sellerMsgs {
                    guard let sentAt = sellerMsg.created_at.flatMap({ isoParser.date(from: $0) }) else { continue }
                    if let firstReply = agentMsgs.first(where: {
                        guard let replyAt = $0.created_at.flatMap({ isoParser.date(from: $0) }) else { return false }
                        return replyAt > sentAt
                    }), let replyAt = firstReply.created_at.flatMap({ isoParser.date(from: $0) }) {
                        deltas.append(replyAt.timeIntervalSince(sentAt) / 60)
                    }
                }
            }
            guard !deltas.isEmpty else { return nil }
            return deltas.reduce(0, +) / Double(deltas.count)
        } catch {
            print("🚨 fetchAgentAverageResponseMinutes erreur:", error)
            return nil
        }
    }
}
