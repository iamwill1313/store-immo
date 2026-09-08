import SwiftUI

struct PrivacySettingsView: View {
    @Environment(AppViewModel.self) private var viewModel
    @Environment(\.dismiss) private var dismiss
    @State private var profileVisibility: ProfileVisibility = .publicProfile
    
    enum ProfileVisibility: String, CaseIterable, Identifiable {
        case publicProfile = "Public"
        case privateProfile = "Privé"
        
        var id: String { rawValue }
        
        var description: String {
            switch self {
            case .publicProfile:
                return "Votre profil est visible par tous les utilisateurs"
            case .privateProfile:
                return "Votre profil n'est visible que par vos contacts"
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                if viewModel.selectedRole == .agent {
                    Section {
                        Picker("Visibilité du profil", selection: $profileVisibility) {
                            ForEach(ProfileVisibility.allCases) { visibility in
                                Text(visibility.rawValue).tag(visibility)
                            }
                        }
                        .pickerStyle(.segmented)
                        
                        Text(profileVisibility.description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } header: {
                        Text("Visibilité du profil")
                    } footer: {
                        Text("En mode public, les vendeurs peuvent voir votre profil complet lorsque vous postulez.")
                    }
                }
                
                Section {
                    NavigationLink {
                        dataManagementView
                    } label: {
                        Label("Gestion des données", systemImage: "folder")
                    }
                } header: {
                    Text("Données personnelles")
                } footer: {
                    Text("Consultez et gérez vos données personnelles.")
                }
                
                Section {
                    Link(destination: URL(string: "https://storeimmo.fr/privacy")!) {
                        HStack {
                            Label("Politique de confidentialité", systemImage: "hand.raised.fill")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                } footer: {
                    Text("Consultez notre politique de confidentialité pour plus d'informations sur la collecte et l'utilisation de vos données.")
                }
            }
            .navigationTitle("Confidentialité")
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
    
    private var dataManagementView: some View {
        Form {
            Section {
                Text("Vous pouvez demander une copie de toutes vos données personnelles ou demander leur suppression.")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            
            Section {
                Button {
                    requestDataExport()
                } label: {
                    Label("Télécharger mes données", systemImage: "arrow.down.circle")
                }
                
                Button(role: .destructive) {
                    requestDataDeletion()
                } label: {
                    Label("Supprimer mon compte", systemImage: "trash")
                }
            } footer: {
                Text("La suppression de votre compte est irréversible. Toutes vos données seront définitivement supprimées.")
            }
        }
        .navigationTitle("Gestion des données")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func requestDataExport() {
        viewModel.appStatusMessage = "Demande d'export de données enregistrée. Vous recevrez un email sous 48h."
    }
    
    private func requestDataDeletion() {
        viewModel.appStatusMessage = "Demande de suppression enregistrée. Contactez le support pour confirmer."
    }
}

#Preview {
    @Previewable @State var viewModel = AppViewModel()
    PrivacySettingsView()
        .environment(viewModel)
}
