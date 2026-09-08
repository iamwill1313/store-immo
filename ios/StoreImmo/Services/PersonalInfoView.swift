import SwiftUI
import PhotosUI

struct PersonalInfoView: View {
    @Environment(AppViewModel.self) private var viewModel
    @Environment(\.dismiss) private var dismiss
    @State private var isEditing = false
    @State private var isSaving = false
    @State private var editedFirstName = ""
    @State private var editedLastName = ""
    @State private var editedEmail = ""
    @State private var editedPhone = ""
    @State private var editedCity = ""
    @State private var editedAgency = ""
    @State private var editedDescription = ""
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var showingPhotoOptions = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    if viewModel.selectedRole == .agent {
                        agentProfileSection
                    } else {
                        sellerProfileSection
                    }
                }
                .padding()
            }
            .navigationTitle("Informations personnelles")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Fermer") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    if isEditing {
                        Button {
                            isSaving = true
                            if viewModel.selectedRole == .agent {
                                saveAgentChanges()
                            } else {
                                saveSellerChanges()
                            }
                        } label: {
                            if isSaving {
                                ProgressView()
                            } else {
                                Text("Enregistrer")
                            }
                        }
                        .fontWeight(.semibold)
                        .disabled(isSaving)
                    } else {
                        Button("Modifier") {
                            startEditing()
                        }
                    }
                }
            }
        }
        .onAppear {
            loadInitialValues()
        }
        .onChange(of: selectedPhotoItem) { oldValue, newValue in
            Task {
                if let data = try? await newValue?.loadTransferable(type: Data.self) {
                    await viewModel.uploadAndSaveAgentProfilePhoto(data)
                }
            }
        }
    }
    
    // MARK: - Agent Profile
    
    private var agentProfileSection: some View {
        VStack(spacing: 24) {
            // Photo de profil
            VStack(spacing: 12) {
                if let photoURL = viewModel.currentAgentProfile?.profilePhotoURL,
                   !photoURL.isEmpty {
                    AsyncImage(url: URL(string: photoURL)) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .foregroundStyle(.gray)
                    }
                    .frame(width: 120, height: 120)
                    .clipShape(Circle())
                } else {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .foregroundStyle(.gray)
                        .frame(width: 120, height: 120)
                }
                
                if isEditing {
                    HStack(spacing: 16) {
                        PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                            Label("Changer", systemImage: "photo")
                                .font(.subheadline)
                        }
                        .buttonStyle(.bordered)
                        
                        if viewModel.currentAgentProfile?.profilePhotoURL != nil {
                            Button(role: .destructive) {
                                Task {
                                    await viewModel.removeAgentProfilePhoto()
                                }
                            } label: {
                                Label("Supprimer", systemImage: "trash")
                                    .font(.subheadline)
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }
            }
            
            // Informations
            VStack(spacing: 16) {
                infoRow(
                    label: "Prénom",
                    value: isEditing ? "" : viewModel.currentAgentProfile?.fullName.components(separatedBy: " ").first ?? "",
                    editBinding: isEditing ? $editedFirstName : nil,
                    isEditable: true
                )
                
                infoRow(
                    label: "Nom",
                    value: isEditing ? "" : viewModel.currentAgentProfile?.fullName.components(separatedBy: " ").dropFirst().joined(separator: " ") ?? "",
                    editBinding: isEditing ? $editedLastName : nil,
                    isEditable: true
                )
                
                infoRow(
                    label: "Email",
                    value: viewModel.agentOnboardingDraft.email,
                    isEditable: false
                )
                
                infoRow(
                    label: "Ville",
                    value: isEditing ? "" : viewModel.currentAgentProfile?.city ?? "",
                    editBinding: isEditing ? $editedCity : nil,
                    isEditable: true
                )
                
                infoRow(
                    label: "Agence",
                    value: isEditing ? "" : viewModel.currentAgentProfile?.agencyName ?? "",
                    editBinding: isEditing ? $editedAgency : nil,
                    isEditable: true
                )
                
                infoRow(
                    label: "Téléphone",
                    value: isEditing ? "" : viewModel.agentOnboardingDraft.phoneNumber,
                    editBinding: isEditing ? $editedPhone : nil,
                    isEditable: true,
                    keyboardType: .phonePad
                )
                
                // Description professionnelle
                VStack(alignment: .leading, spacing: 8) {
                    Text("Description professionnelle")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    if isEditing {
                        TextEditor(text: $editedDescription)
                            .frame(minHeight: 100)
                            .padding(8)
                            .background(Color(uiColor: .systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    } else {
                        Text(viewModel.currentAgentProfile?.bio ?? "")
                            .font(.body)
                    }
                }
                .padding(.vertical, 8)
            }
            .padding()
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    // MARK: - Seller Profile
    
    private var sellerProfileSection: some View {
        VStack(spacing: 24) {
            // Photo de profil (icône par défaut pour le vendeur)
            VStack(spacing: 12) {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .foregroundStyle(.gray)
                    .frame(width: 120, height: 120)
                
                if !isEditing {
                    Text("Photo de profil non disponible")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            // Informations
            VStack(spacing: 16) {
                infoRow(
                    label: "Prénom",
                    value: isEditing ? "" : viewModel.sellerPublicFirstName,
                    editBinding: isEditing ? $editedFirstName : nil,
                    isEditable: true
                )
                
                infoRow(
                    label: "Nom",
                    value: isEditing ? "" : viewModel.sellerOnboardingDraft.lastName,
                    editBinding: isEditing ? $editedLastName : nil,
                    isEditable: true
                )
                
                infoRow(
                    label: "Email",
                    value: viewModel.sellerOnboardingDraft.email,
                    isEditable: false
                )
                
                infoRow(
                    label: "Téléphone",
                    value: isEditing ? "" : viewModel.sellerPhoneNumber,
                    editBinding: isEditing ? $editedPhone : nil,
                    isEditable: true,
                    keyboardType: .phonePad
                )
            }
            .padding()
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    // MARK: - Helper Views
    
    private func infoRow(
        label: String,
        value: String,
        editBinding: Binding<String>? = nil,
        isEditable: Bool,
        keyboardType: UIKeyboardType = .default
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            if let binding = editBinding {
                TextField(label, text: binding)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(keyboardType)
            } else {
                Text(value)
                    .font(.body)
            }
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Actions
    
    private func loadInitialValues() {
        if viewModel.selectedRole == .agent {
            if let profile = viewModel.currentAgentProfile {
                let components = profile.fullName.components(separatedBy: " ")
                editedFirstName = components.first ?? ""
                editedLastName = components.dropFirst().joined(separator: " ")
                editedEmail = viewModel.agentOnboardingDraft.email
                editedCity = profile.city
                editedAgency = profile.agencyName
                editedPhone = viewModel.agentOnboardingDraft.phoneNumber
                editedDescription = profile.bio
            }
        } else {
            editedFirstName = viewModel.sellerPublicFirstName
            editedLastName = viewModel.sellerOnboardingDraft.lastName
            editedEmail = viewModel.sellerOnboardingDraft.email
            editedPhone = viewModel.sellerPhoneNumber
        }
    }
    
    private func startEditing() {
        loadInitialValues()
        isEditing = true
    }
    
    private func saveAgentChanges() {
        viewModel.appStatusMessage = "Enregistrement en cours..."
        
        Task {
            let success = await viewModel.updateAgentPersonalInfo(
                firstName: editedFirstName,
                lastName: editedLastName,
                phone: editedPhone,
                city: editedCity,
                agency: editedAgency,
                description: editedDescription
            )
            
            await MainActor.run {
                isSaving = false
                
                if success {
                    isEditing = false
                    viewModel.appStatusMessage = "✅ Modifications enregistrées avec succès."
                    // Recharger les valeurs depuis le profil mis à jour
                    loadInitialValues()
                } else {
                    viewModel.appStatusMessage = "❌ Erreur lors de l'enregistrement. Veuillez réessayer."
                }
                
                // Effacer le message après 3 secondes
                Task {
                    try? await Task.sleep(for: .seconds(3))
                    await MainActor.run {
                        if viewModel.appStatusMessage?.contains("enregistrées") == true ||
                           viewModel.appStatusMessage?.contains("Erreur") == true {
                            viewModel.appStatusMessage = nil
                        }
                    }
                }
            }
        }
    }
    
    private func saveSellerChanges() {
        viewModel.appStatusMessage = "Enregistrement en cours..."
        
        Task {
            let success = await viewModel.updateSellerPersonalInfo(
                firstName: editedFirstName,
                lastName: editedLastName,
                phone: editedPhone
            )
            
            await MainActor.run {
                isSaving = false
                
                if success {
                    isEditing = false
                    viewModel.appStatusMessage = "✅ Modifications enregistrées avec succès."
                    // Recharger les valeurs depuis le profil mis à jour
                    loadInitialValues()
                } else {
                    viewModel.appStatusMessage = "❌ Erreur lors de l'enregistrement. Veuillez réessayer."
                }
                
                // Effacer le message après 3 secondes
                Task {
                    try? await Task.sleep(for: .seconds(3))
                    await MainActor.run {
                        if viewModel.appStatusMessage?.contains("enregistrées") == true ||
                           viewModel.appStatusMessage?.contains("Erreur") == true {
                            viewModel.appStatusMessage = nil
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    @Previewable @State var viewModel = AppViewModel()
    PersonalInfoView()
        .environment(viewModel)
}
