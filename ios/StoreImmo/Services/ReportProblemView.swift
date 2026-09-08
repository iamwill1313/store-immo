import SwiftUI
import PhotosUI

struct ReportProblemView: View {
    @Environment(AppViewModel.self) private var viewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedCategory: SupportCategory?
    @State private var problemDescription = ""
    @State private var selectedPhotoItems: [PhotosPickerItem] = []
    @State private var selectedPhotoDatas: [Data] = []
    @State private var isSubmitting = false
    @State private var showingSuccess = false
    
    private let maxPhotos = 5
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Catégorie", selection: $selectedCategory) {
                        Text("Sélectionnez une catégorie").tag(nil as SupportCategory?)
                        ForEach(availableCategories) { category in
                            Label(category.rawValue, systemImage: category.symbolName)
                                .tag(category as SupportCategory?)
                        }
                    }
                } header: {
                    Text("Type de problème")
                } footer: {
                    Text("Choisissez la catégorie qui correspond le mieux à votre problème.")
                }
                
                Section {
                    TextEditor(text: $problemDescription)
                        .frame(minHeight: 120)
                        .overlay(alignment: .topLeading) {
                            if problemDescription.isEmpty {
                                Text("Décrivez votre problème en détail...")
                                    .foregroundStyle(.tertiary)
                                    .padding(.top, 8)
                                    .padding(.leading, 4)
                                    .allowsHitTesting(false)
                            }
                        }
                } header: {
                    Text("Description")
                } footer: {
                    Text("Plus vous donnez de détails, plus nous pourrons vous aider efficacement.")
                }
                
                Section {
                    if !selectedPhotoDatas.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("\(selectedPhotoDatas.count)/\(maxPhotos) capture\(selectedPhotoDatas.count > 1 ? "s" : "") ajoutée\(selectedPhotoDatas.count > 1 ? "s" : "")")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(selectedPhotoDatas.indices, id: \.self) { index in
                                        if let uiImage = UIImage(data: selectedPhotoDatas[index]) {
                                            ZStack(alignment: .topTrailing) {
                                                Image(uiImage: uiImage)
                                                    .resizable()
                                                    .scaledToFill()
                                                    .frame(width: 100, height: 100)
                                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                                
                                                Button {
                                                    selectedPhotoDatas.remove(at: index)
                                                } label: {
                                                    Image(systemName: "xmark.circle.fill")
                                                        .font(.system(size: 20))
                                                        .foregroundStyle(.white, .red)
                                                }
                                                .padding(4)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    if selectedPhotoDatas.count < maxPhotos {
                        PhotosPicker(
                            selection: $selectedPhotoItems,
                            maxSelectionCount: maxPhotos - selectedPhotoDatas.count,
                            matching: .images
                        ) {
                            Label(
                                selectedPhotoDatas.isEmpty ? "Ajouter des captures d'écran" : "Ajouter d'autres captures",
                                systemImage: "photo.on.rectangle"
                            )
                        }
                    }
                } header: {
                    Text("Captures d'écran (optionnel)")
                } footer: {
                    Text("Vous pouvez ajouter jusqu'à \(maxPhotos) captures d'écran pour nous aider à mieux comprendre le problème.")
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        infoRow(label: "Rôle", value: roleDescription)
                        infoRow(label: "Version", value: appVersion)
                        infoRow(label: "Appareil", value: deviceModel)
                    }
                } header: {
                    Text("Informations techniques")
                } footer: {
                    Text("Ces informations seront automatiquement incluses dans votre demande.")
                }
            }
            .navigationTitle("Signaler un problème")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Annuler") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Envoyer") {
                        submitTicket()
                    }
                    .fontWeight(.semibold)
                    .disabled(!isFormValid || isSubmitting)
                }
            }
            .disabled(isSubmitting)
            .onChange(of: selectedPhotoItems) { oldValue, newValue in
                guard !newValue.isEmpty else { return }
                Task {
                    for item in newValue {
                        if let data = try? await item.loadTransferable(type: Data.self) {
                            await MainActor.run {
                                selectedPhotoDatas.append(data)
                            }
                        }
                    }
                    await MainActor.run {
                        selectedPhotoItems = []
                    }
                }
            }
            .alert("Demande envoyée", isPresented: $showingSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Votre demande a été enregistrée. Nous vous répondrons dans les plus brefs délais.")
            }
        }
    }
    
    private var availableCategories: [SupportCategory] {
        if viewModel.selectedRole == .seller {
            return [
                .technicalIssue,
                .project,
                .application,
                .account,
                .other
            ]
        } else {
            return SupportCategory.allCases
        }
    }
    
    private var isFormValid: Bool {
        selectedCategory != nil && !problemDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private var roleDescription: String {
        viewModel.selectedRole == .seller ? "Vendeur" : "Agent"
    }
    
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
    
    private var deviceModel: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let modelCode = withUnsafePointer(to: &systemInfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                String(validatingUTF8: $0)
            }
        }
        return modelCode ?? "Unknown"
    }
    
    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
        .font(.subheadline)
    }
    
    private func submitTicket() {
        guard let category = selectedCategory else { return }
        
        isSubmitting = true
        
        Task {
            await viewModel.submitSupportTicket(
                category: category,
                subject: category.rawValue,
                message: problemDescription
            )
            
            isSubmitting = false
            showingSuccess = true
        }
    }
}

#Preview {
    @Previewable @State var viewModel = AppViewModel()
    ReportProblemView()
        .environment(viewModel)
}
