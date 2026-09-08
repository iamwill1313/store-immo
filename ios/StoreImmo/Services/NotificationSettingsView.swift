import SwiftUI

struct NotificationSettingsView: View {
    @Environment(AppViewModel.self) private var viewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle(isOn: Binding(
                        get: { viewModel.notificationSettings.projectsEnabled },
                        set: { viewModel.notificationSettings.projectsEnabled = $0 }
                    )) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Projets / Biens")
                                .font(.body)
                            Text(projectsDescription)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Toggle(isOn: Binding(
                        get: { viewModel.notificationSettings.applicationsEnabled },
                        set: { viewModel.notificationSettings.applicationsEnabled = $0 }
                    )) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Candidatures")
                                .font(.body)
                            Text(applicationsDescription)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Toggle(isOn: Binding(
                        get: { viewModel.notificationSettings.messagesEnabled },
                        set: { viewModel.notificationSettings.messagesEnabled = $0 }
                    )) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Messages")
                                .font(.body)
                            Text("Nouveaux messages et échanges")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("Notifications par catégorie")
                } footer: {
                    Text("Gérez les notifications que vous souhaitez recevoir pour chaque catégorie.")
                }
                
                if viewModel.selectedRole == .agent {
                    Section {
                        Toggle(isOn: Binding(
                            get: { viewModel.notificationSettings.subscriptionEnabled },
                            set: { viewModel.notificationSettings.subscriptionEnabled = $0 }
                        )) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Abonnement et paiement")
                                    .font(.body)
                                Text("Informations sur votre abonnement")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                
                Section {
                    Toggle(isOn: Binding(
                        get: { viewModel.notificationSettings.generalEnabled },
                        set: { viewModel.notificationSettings.generalEnabled = $0 }
                    )) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Notifications générales")
                                .font(.body)
                            Text("Actualités et mises à jour de l'application")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                Section {
                    Button {
                        openSystemSettings()
                    } label: {
                        HStack {
                            Image(systemName: "gear")
                            Text("Paramètres système")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .font(.caption)
                        }
                    }
                } footer: {
                    Text("Pour désactiver complètement les notifications, modifiez les paramètres système de votre appareil.")
                }
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Terminé") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private var projectsDescription: String {
        if viewModel.selectedRole == .seller {
            return "Nouvelles candidatures sur vos projets"
        } else {
            return "Nouveaux biens disponibles dans votre zone"
        }
    }
    
    private var applicationsDescription: String {
        if viewModel.selectedRole == .seller {
            return "Candidatures reçues et mises à jour"
        } else {
            return "Statut de vos candidatures"
        }
    }
    
    private func openSystemSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

#Preview {
    @Previewable @State var viewModel = AppViewModel()
    NotificationSettingsView()
        .environment(viewModel)
}
