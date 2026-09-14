import SwiftUI

// MARK: - Public Agents Section for Public Home

struct PublicAgentsSectionView: View {
    @Environment(AppViewModel.self) private var viewModel
    @State private var selectedAgent: AgentProfile?
    @State private var publicAgents: [AgentProfile] = []
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header
            HStack {
                Image(systemName: "person.3.fill")
                    .font(.title2)
                    .foregroundStyle(.purple)
                Text("Nos agents")
                    .font(.title2.weight(.bold))
                Spacer()
                if !publicAgents.isEmpty {
                    Text("\(publicAgents.count)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 20)
            
            // Agents scroll
            if publicAgents.isEmpty {
                // Empty state
                ContentUnavailableView {
                    Label("Aucun agent disponible", systemImage: "person.3")
                } description: {
                    Text("Les profils des agents immobiliers apparaîtront ici.")
                }
                .frame(height: 200)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        ForEach(publicAgents) { agent in
                            PublicAgentCardView(agent: agent)
                                .onTapGesture {
                                    selectedAgent = agent
                                }
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
        .task {
            await loadPublicAgents()
        }
        .sheet(item: $selectedAgent) { agent in
            PublicAgentDetailView(agent: agent)
        }
    }
    
    private func loadPublicAgents() async {
        // Load public agents from existing data
        // For now, we'll use a simple approach that doesn't modify existing queries
        
        // If there are opportunities with agents, extract unique agents
        let agentsFromOpportunities = viewModel.agentOpportunities.flatMap { project in
            project.applications.map { $0.agent }
        }
        
        // Get unique agents
        let uniqueAgents = Dictionary(grouping: agentsFromOpportunities, by: { $0.id })
            .compactMap { $0.value.first }
        
        // If we have a current agent profile, add it
        if let currentAgent = viewModel.currentAgentProfile {
            var agents = uniqueAgents
            if !agents.contains(where: { $0.id == currentAgent.id }) {
                agents.append(currentAgent)
            }
            publicAgents = Array(agents.prefix(10))
        } else {
            publicAgents = Array(uniqueAgents.prefix(10))
        }
        
        // Note: In a future version with SupabaseRepository extended,
        // we would call: await viewModel.loadPublicAgents()
    }
}

// MARK: - Public Agent Card

private struct PublicAgentCardView: View {
    let agent: AgentProfile
    
    var body: some View {
        VStack(spacing: 12) {
            // Agent photo
            if let photoURL = agent.profilePhotoURL, let url = URL(string: photoURL) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    default:
                        agentPlaceholder
                    }
                }
                .frame(width: 80, height: 80)
                .clipShape(Circle())
                .overlay {
                    Circle()
                        .strokeBorder(Color.purple.opacity(0.3), lineWidth: 2)
                }
            } else {
                agentPlaceholder
            }
            
            // Agent info
            VStack(spacing: 4) {
                // Name
                Text(agent.fullName)
                    .font(.headline)
                    .lineLimit(1)
                
                // Agency
                if !agent.agencyName.isEmpty {
                    Text(agent.agencyName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                } else {
                    Text("Indépendant")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                // City
                HStack(spacing: 3) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.caption2)
                    Text(agent.interventionZones.first?.city ?? "France")
                        .font(.caption)
                }
                .foregroundStyle(.purple)
                
                // Badge
                if !agent.badge.title.isEmpty {
                    Text(agent.badge.title)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.purple, in: .capsule)
                }
            }
        }
        .frame(width: 140)
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.05), radius: 6, y: 3)
    }
    
    private var agentPlaceholder: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [Color.purple, Color.purple.opacity(0.7)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 80, height: 80)
            .overlay {
                Image(systemName: "person.fill")
                    .font(.largeTitle)
                    .foregroundStyle(.white.opacity(0.8))
            }
    }
}

// MARK: - Public Agent Detail View

private struct PublicAgentDetailView: View {
    let agent: AgentProfile
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Agent header
                    HStack(spacing: 16) {
                        // Photo
                        if let photoURL = agent.profilePhotoURL, let url = URL(string: photoURL) {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFill()
                                default:
                                    agentPlaceholder
                                }
                            }
                            .frame(width: 80, height: 80)
                            .clipShape(Circle())
                            .overlay {
                                Circle()
                                    .strokeBorder(Color.purple.opacity(0.3), lineWidth: 2)
                            }
                        } else {
                            agentPlaceholder
                        }
                        
                        // Info
                        VStack(alignment: .leading, spacing: 6) {
                            Text(agent.fullName)
                                .font(.title2.weight(.bold))
                            
                            if !agent.agencyName.isEmpty {
                                Text(agent.agencyName)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            } else {
                                Text("Agent indépendant")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            
                            if !agent.badge.title.isEmpty {
                                Text(agent.badge.title)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(.purple, in: .capsule)
                            }
                        }
                        
                        Spacer()
                    }
                    
                    Divider()
                    
                    // Bio
                    if !agent.bio.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Présentation")
                                .font(.headline)
                            Text(agent.bio)
                                .font(.body)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    // Intervention zones
                    if !agent.interventionZones.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Zones d'intervention")
                                .font(.headline)
                            
                            ForEach(agent.interventionZones.prefix(5)) { zone in
                                HStack {
                                    Image(systemName: "mappin.circle.fill")
                                        .foregroundStyle(.purple)
                                    Text(zone.city)
                                        .font(.subheadline)
                                    Spacer()
                                    Text("\(zone.radiusKilometers) km")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                    
                    // Trust indicators
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Informations")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "calendar")
                                    .foregroundStyle(.purple)
                                Text(agent.trustIndicators.memberSince)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            
                            HStack {
                                Image(systemName: "clock")
                                    .foregroundStyle(.purple)
                                Text(agent.trustIndicators.responseTime)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            
                            HStack {
                                Image(systemName: "bolt.circle")
                                    .foregroundStyle(.purple)
                                Text(agent.trustIndicators.recentActivity)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    
                    Spacer(minLength: 40)
                }
                .padding(20)
            }
            .navigationTitle("Profil agent")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fermer") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var agentPlaceholder: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [Color.purple, Color.purple.opacity(0.7)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 80, height: 80)
            .overlay {
                Image(systemName: "person.fill")
                    .font(.largeTitle)
                    .foregroundStyle(.white.opacity(0.8))
            }
    }
}

#Preview {
    @Previewable @State var viewModel = AppViewModel()
    PublicAgentsSectionView()
        .environment(viewModel)
}
