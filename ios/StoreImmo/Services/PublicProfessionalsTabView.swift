import SwiftUI

/// Public tab displaying available real estate professionals with REAL photos.
/// REFONTE VISUELLE — Affichage moderne des agents avec VRAIES photos de profil
struct PublicProfessionalsTabView: View {
    @Environment(AppViewModel.self) private var viewModel
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header moderne
                    ProfessionalsHeaderView()
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                    
                    // Grid des agents avec VRAIES photos
                    PublicAgentsModernGridView()
                        .padding(.horizontal, 20)
                        .padding(.bottom, 32)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Professionnels")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

/// Header moderne avec icône et description
private struct ProfessionalsHeaderView: View {
    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            // Icône professionnels
            Image(systemName: "person.2.fill")
                .font(.title)
                .foregroundStyle(.white)
                .frame(width: 50, height: 50)
                .background(
                    LinearGradient(
                        colors: [Color.purple, Color.purple.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    in: .circle
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Agents immobiliers vérifiés")
                    .font(.title3.bold())
                    .foregroundStyle(.primary)
                
                Text("Trouvez le professionnel idéal")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding(16)
        .background(Color(.secondarySystemBackground), in: .rect(cornerRadius: 18))
    }
}

/// Grid moderne des agents avec photos réelles
private struct PublicAgentsModernGridView: View {
    @Environment(AppViewModel.self) private var viewModel
    @State private var selectedAgent: AgentProfile?
    @State private var publicAgents: [AgentProfile] = []
    
    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]
    
    var body: some View {
        Group {
            if publicAgents.isEmpty {
                // Empty state élégant
                ContentUnavailableView {
                    VStack(spacing: 16) {
                        Image(systemName: "person.2.slash")
                            .font(.system(size: 60))
                            .foregroundStyle(.secondary.opacity(0.5))
                        Text("Aucun agent disponible")
                            .font(.title3.bold())
                    }
                } description: {
                    Text("Les profils des agents immobiliers apparaîtront ici.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(minHeight: 300)
            } else {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(publicAgents) { agent in
                        PublicAgentModernCard(agent: agent)
                            .onTapGesture {
                                selectedAgent = agent
                            }
                    }
                }
                .sheet(item: $selectedAgent) { agent in
                    PublicAgentDetailModernView(agent: agent)
                }
            }
        }
        .task {
            await loadPublicAgents()
        }
    }
    
    private func loadPublicAgents() async {
        // Extract agents from existing data
        let agentsFromOpportunities = viewModel.agentOpportunities.flatMap { project in
            project.applications.map { $0.agent }
        }
        
        let uniqueAgents = Dictionary(grouping: agentsFromOpportunities, by: { $0.id })
            .compactMap { $0.value.first }
        
        if let currentAgent = viewModel.currentAgentProfile {
            var agents = uniqueAgents
            if !agents.contains(where: { $0.id == currentAgent.id }) {
                agents.append(currentAgent)
            }
            publicAgents = Array(agents.prefix(20))
        } else {
            publicAgents = Array(uniqueAgents.prefix(20))
        }
    }
}

/// Carte moderne agent avec VRAIE photo de profil
private struct PublicAgentModernCard: View {
    let agent: AgentProfile
    
    var body: some View {
        VStack(spacing: 14) {
            // Photo de profil en grand format
            ZStack(alignment: .bottomTrailing) {
                if let photoURL = agent.profilePhotoURL, let url = URL(string: photoURL) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 120, height: 120)
                                .clipShape(Circle())
                        case .failure:
                            agentPlaceholder
                        default:
                            Color(.systemGray5)
                                .frame(width: 120, height: 120)
                                .clipShape(Circle())
                                .overlay {
                                    ProgressView()
                                }
                        }
                    }
                } else {
                    agentPlaceholder
                }
                
                // Badge plan
                planBadge
                    .offset(x: -8, y: -8)
            }
            
            // Informations agent
            VStack(spacing: 6) {
                Text(agent.fullName)
                    .font(.headline)
                    .lineLimit(1)
                    .foregroundStyle(.primary)
                
                if !agent.agencyName.isEmpty {
                    Text(agent.agencyName)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                } else {
                    Text("Indépendant")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                }
                
                // Ville principale
                HStack(spacing: 4) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.caption2)
                    Text(agent.interventionZones.first?.city ?? "France")
                        .font(.caption)
                }
                .foregroundStyle(Color.purple)
                .padding(.top, 2)
                
                // Badge vérification
                if !agent.badge.title.isEmpty {
                    Text(agent.badge.title)
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            LinearGradient(
                                colors: [Color.purple, Color.purple.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            in: .capsule
                        )
                        .padding(.top, 4)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .padding(.horizontal, 12)
        .background(Color(.secondarySystemBackground), in: .rect(cornerRadius: 18))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.06), radius: 10, y: 4)
    }
    
    private var agentPlaceholder: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [Color.purple, Color.purple.opacity(0.75)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 120, height: 120)
            .overlay {
                Image(systemName: agent.photoSymbol)
                    .font(.system(size: 50))
                    .foregroundStyle(.white.opacity(0.9))
            }
    }
    
    @ViewBuilder
    private var planBadge: some View {
        let planColor: Color = {
            switch agent.plan {
            case .starter: return .teal
            case .pro: return .blue
            case .elite: return .orange
            }
        }()
        
        Image(systemName: agent.plan.iconName)
            .font(.caption2.weight(.bold))
            .foregroundStyle(.white)
            .frame(width: 28, height: 28)
            .background(planColor, in: .circle)
            .overlay {
                Circle()
                    .strokeBorder(.white, lineWidth: 2)
            }
    }
}

/// Vue détail agent en modal — design moderne
private struct PublicAgentDetailModernView: View {
    let agent: AgentProfile
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 26) {
                    // Agent header avec photo
                    HStack(alignment: .top, spacing: 18) {
                        // Photo
                        if let photoURL = agent.profilePhotoURL, let url = URL(string: photoURL) {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 90, height: 90)
                                        .clipShape(Circle())
                                        .overlay {
                                            Circle()
                                                .strokeBorder(Color.purple.opacity(0.3), lineWidth: 3)
                                        }
                                default:
                                    agentPlaceholder(size: 90)
                                }
                            }
                        } else {
                            agentPlaceholder(size: 90)
                        }
                        
                        // Info
                        VStack(alignment: .leading, spacing: 8) {
                            Text(agent.fullName)
                                .font(.title2.bold())
                                .foregroundStyle(.primary)
                            
                            if !agent.agencyName.isEmpty {
                                Text(agent.agencyName)
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(.secondary)
                            } else {
                                Text("Agent indépendant")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(.secondary)
                            }
                            
                            if !agent.badge.title.isEmpty {
                                Text(agent.badge.title)
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        LinearGradient(
                                            colors: [Color.purple, Color.purple.opacity(0.8)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        ),
                                        in: .capsule
                                    )
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(.bottom, 8)
                    
                    Divider()
                    
                    // Bio
                    if !agent.bio.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Présentation", systemImage: "person.text.rectangle.fill")
                                .font(.headline)
                                .foregroundStyle(Color.purple)
                            Text(agent.bio)
                                .font(.body)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    
                    // Intervention zones
                    if !agent.interventionZones.isEmpty {
                        VStack(alignment: .leading, spacing: 14) {
                            Label("Zones d'intervention", systemImage: "map.fill")
                                .font(.headline)
                                .foregroundStyle(Color.purple)
                            
                            ForEach(agent.interventionZones.prefix(6)) { zone in
                                HStack(spacing: 10) {
                                    Image(systemName: "mappin.circle.fill")
                                        .foregroundStyle(Color.purple)
                                    Text(zone.city)
                                        .font(.subheadline.weight(.medium))
                                    Spacer()
                                    Text("\(zone.radiusKilometers) km")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(.secondary)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color(.tertiarySystemBackground), in: .capsule)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    
                    // Trust indicators
                    VStack(alignment: .leading, spacing: 14) {
                        Label("Informations", systemImage: "checkmark.seal.fill")
                            .font(.headline)
                            .foregroundStyle(Color.purple)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 10) {
                                Image(systemName: "calendar.circle.fill")
                                    .font(.title3)
                                    .foregroundStyle(Color.purple)
                                Text(agent.trustIndicators.memberSince)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            
                            HStack(spacing: 10) {
                                Image(systemName: "clock.fill")
                                    .font(.title3)
                                    .foregroundStyle(Color.purple)
                                Text(agent.trustIndicators.responseTime)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            
                            HStack(spacing: 10) {
                                Image(systemName: "bolt.circle.fill")
                                    .font(.title3)
                                    .foregroundStyle(Color.purple)
                                Text(agent.trustIndicators.recentActivity)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.tertiarySystemBackground), in: .rect(cornerRadius: 14))
                    }
                    
                    Spacer(minLength: 40)
                }
                .padding(22)
            }
            .background(Color(.systemGroupedBackground))
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
    
    private func agentPlaceholder(size: CGFloat) -> some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [Color.purple, Color.purple.opacity(0.75)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: size, height: size)
            .overlay {
                Image(systemName: agent.photoSymbol)
                    .font(.system(size: size * 0.5))
                    .foregroundStyle(.white.opacity(0.9))
            }
    }
}

#Preview {
    PublicProfessionalsTabView()
        .environment(AppViewModel())
}
