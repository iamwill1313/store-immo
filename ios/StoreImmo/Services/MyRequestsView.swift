import SwiftUI

struct MyRequestsView: View {
    @Environment(AppViewModel.self) private var viewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.supportTickets.isEmpty {
                    emptyStateView
                } else {
                    ticketsList
                }
            }
            .navigationTitle("Mes demandes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fermer") {
                        dismiss()
                    }
                }
            }
            .task {
                await viewModel.loadSupportTickets()
            }
        }
    }
    
    private var emptyStateView: some View {
        ContentUnavailableView {
            Label("Aucune demande", systemImage: "tray")
        } description: {
            Text("Vous n'avez pas encore envoyé de demande au support.")
        }
    }
    
    private var ticketsList: some View {
        List {
            ForEach(viewModel.supportTickets) { ticket in
                NavigationLink {
                    TicketDetailView(ticket: ticket)
                } label: {
                    TicketRowView(ticket: ticket)
                }
            }
        }
    }
}

struct TicketRowView: View {
    let ticket: SupportTicket
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            headerRow
            
            Text(ticket.subject)
                .font(.body)
                .lineLimit(1)
            
            Text(ticket.message)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
            
            Text(ticket.createdAt.formatted(date: .abbreviated, time: .shortened))
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }
    
    private var headerRow: some View {
        HStack {
            Image(systemName: ticket.category.symbolName)
                .foregroundStyle(Color.accentColor)
            
            Text(ticket.category.rawValue)
                .font(.subheadline.weight(.medium))
            
            Spacer()
            
            statusBadge
        }
    }
    
    private var statusBadge: some View {
        Text(ticket.status.rawValue)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor)
            .clipShape(Capsule())
    }
    
    private var statusColor: Color {
        switch ticket.status {
        case .new:
            return .blue
        case .inProgress:
            return .orange
        case .resolved:
            return .green
        }
    }
}

struct TicketDetailView: View {
    let ticket: SupportTicket
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                headerSection
                Divider()
                messageSection
                Divider()
                metadataSection
                
                if ticket.status != .resolved {
                    infoAlert
                }
            }
            .padding()
        }
        .navigationTitle("Demande #\(String(ticket.id.uuidString.prefix(8)))")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: ticket.category.symbolName)
                    .font(.title2)
                    .foregroundStyle(Color.accentColor)
                
                Text(ticket.category.rawValue)
                    .font(.headline)
                
                Spacer()
                
                statusBadge
            }
            
            Text(ticket.subject)
                .font(.title3.weight(.semibold))
        }
    }
    
    private var messageSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Description")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            
            Text(ticket.message)
                .font(.body)
        }
    }
    
    private var metadataSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            createdAtRow
            
            if let updatedAt = ticket.updatedAt {
                updatedAtRow(date: updatedAt)
            }
            
            statusRow
        }
    }
    
    private var createdAtRow: some View {
        HStack {
            Text("Créée le")
                .foregroundStyle(.secondary)
            Spacer()
            Text(ticket.createdAt.formatted(date: .long, time: .shortened))
                .fontWeight(.medium)
        }
        .font(.subheadline)
    }
    
    private func updatedAtRow(date: Date) -> some View {
        HStack {
            Text("Mise à jour")
                .foregroundStyle(.secondary)
            Spacer()
            Text(date.formatted(date: .long, time: .shortened))
                .fontWeight(.medium)
        }
        .font(.subheadline)
    }
    
    private var statusRow: some View {
        HStack {
            Text("Statut")
                .foregroundStyle(.secondary)
            Spacer()
            statusBadge
        }
        .font(.subheadline)
    }
    
    private var infoAlert: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("ℹ️ Notre équipe traite votre demande")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Text("Vous recevrez une notification dès que nous aurons une réponse.")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.blue.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var statusBadge: some View {
        Text(ticket.status.rawValue)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(statusColor)
            .clipShape(Capsule())
    }
    
    private var statusColor: Color {
        switch ticket.status {
        case .new:
            return .blue
        case .inProgress:
            return .orange
        case .resolved:
            return .green
        }
    }
}

#Preview("List with tickets") {
    @Previewable @State var viewModel = {
        let vm = AppViewModel()
        vm.supportTickets = [
            SupportTicket(
                category: .technicalIssue,
                subject: "Problème de connexion",
                message: "Je n'arrive pas à me connecter depuis ce matin.",
                status: .inProgress,
                createdAt: Date().addingTimeInterval(-86400)
            ),
            SupportTicket(
                category: .payment,
                subject: "Question sur l'abonnement",
                message: "Je voudrais savoir comment modifier mon plan.",
                status: .resolved,
                createdAt: Date().addingTimeInterval(-172800),
                updatedAt: Date().addingTimeInterval(-86400)
            )
        ]
        return vm
    }()
    
    return MyRequestsView()
        .environment(viewModel)
}

#Preview("Empty state") {
    let viewModel = AppViewModel()
    return MyRequestsView()
        .environment(viewModel)
}
