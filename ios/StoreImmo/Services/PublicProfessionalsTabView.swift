import SwiftUI

/// Public tab displaying featured real estate professionals.
/// REFONTE VISUELLE — Affichage cohérent avec Biens et Actualités
struct PublicProfessionalsTabView: View {
    @Environment(AppViewModel.self) private var viewModel
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // En-tête minimaliste Store Immo
                    ProfessionalsHeaderSection()
                        .padding(.top, 20)
                        .padding(.bottom, 28)
                    
                    // Section "Agents mis en avant"
                    ProfessionalsFeaturedAgentsSection()
                        .padding(.horizontal, 20)
                        .padding(.bottom, 28)
                    
                    // Encadré "Rejoindre Store Immo"
                    ProfessionalsJoinSection()
                        .padding(.horizontal, 20)
                        .padding(.bottom, 32)
                }
            }
            .background(Color(.systemBackground))
            .navigationTitle("Professionnels")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Header Section (En-tête minimaliste)

private struct ProfessionalsHeaderSection: View {
    var body: some View {
        VStack(spacing: 12) {
            // Titre principal : Agents immobiliers vérifiés
            Text("Agents immobiliers vérifiés")
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(StoreImmoTheme.navy)
            
            // Sous-titre
            Text("Découvrez les professionnels mis en avant par Store Immo.")
                .font(.system(size: 16))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Featured Agents Section

private struct ProfessionalsFeaturedAgentsSection: View {
    @Environment(AppViewModel.self) private var viewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Liste des agents mis en avant
            ProfessionalsFeaturedAgentsList()
        }
    }
}

// MARK: - Featured Agents List

private struct ProfessionalsFeaturedAgentsList: View {
    @Environment(AppViewModel.self) private var viewModel
    @State private var selectedAgent: AgentProfile?
    @State private var featuredAgents: [AgentProfile] = []
    
    var body: some View {
        Group {
            if featuredAgents.isEmpty {
                // Empty state discret
                VStack(spacing: 16) {
                    Image(systemName: "person.2.slash")
                        .font(.system(size: 50))
                        .foregroundStyle(.secondary.opacity(0.4))
                    
                    Text("Aucun agent mis en avant")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    Text("La sélection d'agents sera bientôt disponible.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 50)
            } else {
                VStack(spacing: 0) {
                    ForEach(featuredAgents) { agent in
                        Button {
                            selectedAgent = agent
                        } label: {
                            ProfessionalsFeaturedAgentCard(agent: agent)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
                }
                .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
                .sheet(item: $selectedAgent) { agent in
                    ProfessionalsAgentDetailView(agent: agent)
                }
            }
        }
        .task {
            await loadFeaturedAgents()
        }
    }
    
    /// Charge les 5 agents mis en avant par Store Immo.
    /// Pour V1: sélection basée sur l'activité et les données disponibles.
    /// À terme: remplacer par un système de sélection manuelle/hebdomadaire.
    private func loadFeaturedAgents() async {
        // Récupérer TOUS les profils agents depuis Supabase (pas seulement ceux ayant candidaté)
        let agentRows = await SupabaseService.shared.fetch(from: "agents_profiles", as: AgentProfileRow.self)
        
        print("📌 [Featured Agents] Profils agents récupérés depuis Supabase:", agentRows.count)
        
        // Convertir les rows en AgentProfile
        var allAgents: [AgentProfile] = agentRows.map { row in
            AgentProfile(
                id: UUID(uuidString: row.user_id) ?? UUID(),
                fullName: "\(row.first_name) \(row.last_name)".trimmingCharacters(in: .whitespaces),
                agencyName: row.agency ?? "Indépendant",
                city: row.city,
                badge: .professionalCard(number: "Vérifié"),
                bio: row.description ?? "Agent immobilier vérifié sur Store Immo.",
                averageRating: 0,
                reviewCount: 0,
                salesLast12Months: 0,
                soldRate: 0,
                averageSalePrice: 0,
                averageDelayDays: 0,
                commissionPercent: 4.5,
                interventionZones: [],
                reviews: [],
                photoSymbol: "person.crop.circle.fill",
                plan: .starter,
                profilePhotoURL: row.profile_photo_url
            )
        }
        
        // Ajouter currentAgentProfile s'il existe et n'est pas déjà présent
        if let currentAgent = viewModel.currentAgentProfile {
            if !allAgents.contains(where: { $0.id == currentAgent.id }) {
                allAgents.append(currentAgent)
                print("📌 [Featured Agents] Ajout currentAgentProfile:", currentAgent.fullName)
            }
        }
        
        // Pour V1: afficher simplement les 5 premiers agents disponibles
        // (La logique de sélection hebdomadaire sera implémentée plus tard)
        let selectedAgents = allAgents
            .sorted { agent1, agent2 in
                // Critère 1: Plan (Elite > Pro > Starter)
                let plan1Weight = planWeight(agent1.plan)
                let plan2Weight = planWeight(agent2.plan)
                
                if plan1Weight != plan2Weight {
                    return plan1Weight > plan2Weight
                }
                
                // Critère 2: Date d'inscription (plus récent)
                if let date1 = agent1.memberSinceDate, let date2 = agent2.memberSinceDate {
                    return date1 > date2
                }
                
                return false
            }
            .prefix(5) // LIMITE STRICTE : 5 agents maximum
        
        featuredAgents = Array(selectedAgents)
        
        print("📌 [Featured Agents] Sélection finale affichée:", featuredAgents.count, "agents")
        featuredAgents.forEach { agent in
            print("   - \(agent.fullName) (\(agent.agencyName)) - Plan \(agent.plan.title)")
        }
    }
    
    private func planWeight(_ plan: SubscriptionPlan) -> Int {
        switch plan {
        case .elite: return 3
        case .pro: return 2
        case .starter: return 1
        }
    }
}

// MARK: - Featured Agent Card

/// Liste professionnelle d'agents - design épuré et compact
private struct ProfessionalsFeaturedAgentCard: View {
    let agent: AgentProfile
    
    var body: some View {
        HStack(spacing: 14) {
            // Photo ronde à gauche
            agentPhotoView
                .frame(width: 64, height: 64)
                .clipShape(Circle())
                .overlay {
                    Circle()
                        .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
                }
            
            // Informations à droite
            VStack(alignment: .leading, spacing: 4) {
                // Nom
                Text(agent.fullName)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                
                // Agence
                if !agent.agencyName.isEmpty {
                    Text(agent.agencyName)
                        .font(.system(size: 15))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                
                // Ville
                HStack(spacing: 4) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                    Text(agent.city)
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }
                .padding(.bottom, 2)
                
                // Note et avis si disponibles
                if agent.reviewCount > 0 && agent.averageRating > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(.orange)
                        Text(String(format: "%.1f", agent.averageRating))
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.primary)
                        Text("·")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                        Text("\(agent.reviewCount) avis")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Spacer(minLength: 0)
            
            // Chevron discret
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(StoreImmoTheme.navy.opacity(0.4))
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(Color(.systemBackground))
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.primary.opacity(0.08))
                .frame(height: 0.5)
                .padding(.leading, 94)
        }
    }
    
    @ViewBuilder
    private var agentPhotoView: some View {
        if let photoURL = agent.profilePhotoURL, let url = URL(string: photoURL) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                case .failure:
                    agentPhotoPlaceholder
                default:
                    Color(.systemGray5)
                        .overlay {
                            ProgressView()
                        }
                }
            }
        } else {
            agentPhotoPlaceholder
        }
    }
    
    @ViewBuilder
    private var agentPhotoPlaceholder: some View {
        ZStack {
            Color(.systemGray5)
            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: 32))
                .foregroundStyle(.secondary.opacity(0.5))
        }
    }
}

// MARK: - Join Section

private struct ProfessionalsJoinSection: View {
    @Environment(AppViewModel.self) private var viewModel
    
    var body: some View {
        VStack(spacing: 12) {
            // Message pour les agents
            VStack(spacing: 4) {
                Text("Vous êtes agent immobilier ?")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                
                Text("Développez votre activité sur Store Immo.")
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Bouton Rejoindre
            Button(action: {
                withAnimation(.smooth(duration: 0.35)) {
                    viewModel.chooseRole(.agent)
                }
            }) {
                HStack(spacing: 6) {
                    Text("Rejoindre Store Immo")
                        .font(.system(size: 16, weight: .semibold))
                    
                    Image(systemName: "arrow.right")
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 46)
                .background(StoreImmoTheme.navy)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .shadow(color: StoreImmoTheme.navy.opacity(0.2), radius: 8, y: 3)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.03), radius: 6, y: 2)
    }
}

// MARK: - Agent Detail View

/// Vue détail agent reprenant le style cohérent de l'application
private struct ProfessionalsAgentDetailView: View {
    let agent: AgentProfile
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Photo de profil compacte en haut
                    if !agent.profilePhotoURL.isNilOrEmpty {
                        HStack {
                            Spacer()
                            agentPhotoSection
                            Spacer()
                        }
                        .padding(.top, 20)
                        .padding(.bottom, 8)
                    }
                    
                    // Informations principales
                    VStack(alignment: .leading, spacing: 20) {
                        // Nom et agence
                        VStack(alignment: .leading, spacing: 8) {
                            Text(agent.fullName)
                                .font(.title2.bold())
                                .foregroundStyle(.primary)
                            
                            if !agent.agencyName.isEmpty {
                                Text(agent.agencyName)
                                    .font(.title3)
                                    .foregroundStyle(.secondary)
                            }
                            
                            // Badge vérification
                            if !agent.badge.title.isEmpty {
                                Text(agent.badge.title)
                                    .font(.subheadline.weight(.bold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 7)
                                    .background(StoreImmoTheme.navy, in: .capsule)
                            }
                        }
                        
                        Divider()
                        
                        // Bio
                        if !agent.bio.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Présentation")
                                    .font(.headline)
                                Text(agent.bio)
                                    .font(.body)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        // Statistiques si disponibles
                        if agent.reviewCount > 0 || agent.salesLast12Months > 0 {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Activité")
                                    .font(.headline)
                                
                                VStack(alignment: .leading, spacing: 12) {
                                    if agent.averageRating > 0 && agent.reviewCount > 0 {
                                        HStack(spacing: 8) {
                                            Image(systemName: "star.fill")
                                                .foregroundStyle(.orange)
                                            Text("\(String(format: "%.1f", agent.averageRating))/5")
                                                .font(.subheadline.weight(.medium))
                                            Text("(\(agent.reviewCount) avis)")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    
                                    if agent.salesLast12Months > 0 {
                                        HStack(spacing: 8) {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundStyle(.green)
                                            Text("\(agent.salesLast12Months) ventes")
                                                .font(.subheadline.weight(.medium))
                                            Text("12 derniers mois")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    
                                    if agent.soldRate > 0 {
                                        HStack(spacing: 8) {
                                            Image(systemName: "chart.line.uptrend.xyaxis")
                                                .foregroundStyle(.blue)
                                            Text("\(agent.soldRate)%")
                                                .font(.subheadline.weight(.medium))
                                            Text("taux de réussite")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Zones d'intervention
                        if !agent.interventionZones.isEmpty {
                            VStack(alignment: .leading, spacing: 14) {
                                Text("Zones d'intervention")
                                    .font(.headline)
                                
                                ForEach(agent.interventionZones.prefix(5)) { zone in
                                    HStack(spacing: 10) {
                                        Image(systemName: "mappin.circle.fill")
                                            .foregroundStyle(StoreImmoTheme.navy)
                                        Text(zone.city)
                                            .font(.subheadline.weight(.medium))
                                        Spacer()
                                        if zone.radiusKilometers > 0 {
                                            Text("\(zone.radiusKilometers) km")
                                                .font(.caption.weight(.semibold))
                                                .foregroundStyle(.secondary)
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 4)
                                                .background(Color(.tertiarySystemBackground), in: .capsule)
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Informations complémentaires
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Informations")
                                .font(.headline)
                            
                            VStack(alignment: .leading, spacing: 12) {
                                if let memberDate = agent.memberSinceDate {
                                    HStack(spacing: 10) {
                                        Image(systemName: "calendar.circle.fill")
                                            .font(.title3)
                                            .foregroundStyle(StoreImmoTheme.navy)
                                        Text("Membre depuis \(memberDate.formatted(date: .abbreviated, time: .omitted))")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                
                                HStack(spacing: 10) {
                                    Image(systemName: agent.plan.iconName)
                                        .font(.title3)
                                        .foregroundStyle(StoreImmoTheme.navy)
                                    Text("Plan \(agent.plan.title)")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.tertiarySystemBackground), in: .rect(cornerRadius: 14))
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer(minLength: 40)
                }
            }
            .navigationTitle("Profil agent")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
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
    
    @ViewBuilder
    private var agentPhotoSection: some View {
        if let photoURL = agent.profilePhotoURL, let url = URL(string: photoURL) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                        .overlay {
                            Circle()
                                .strokeBorder(Color.primary.opacity(0.1), lineWidth: 1)
                        }
                default:
                    Circle()
                        .fill(Color(.systemGray5))
                        .frame(width: 100, height: 100)
                        .overlay {
                            Image(systemName: "person.crop.circle.fill")
                                .font(.system(size: 45))
                                .foregroundStyle(.secondary.opacity(0.5))
                        }
                }
            }
        }
    }
}

private extension Optional where Wrapped == String {
    var isNilOrEmpty: Bool {
        self?.isEmpty ?? true
    }
}

#Preview {
    PublicProfessionalsTabView()
        .environment(AppViewModel())
}
