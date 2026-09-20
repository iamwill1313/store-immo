import SwiftUI

/// Public account tab for unauthenticated users.
/// REFONTE VISUELLE — Interface minimaliste cohérente avec les autres onglets publics
struct PublicAccountTabView: View {
    @Environment(AppViewModel.self) private var viewModel
    @State private var showingHelpCenter = false
    @State private var showingAbout = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // En-tête minimaliste
                    PublicAccountHeaderSection()
                        .padding(.top, 20)
                        .padding(.bottom, 32)
                    
                    // Sélection de rôle simple
                    PublicRoleSelectionSection()
                        .padding(.horizontal, 20)
                        .padding(.bottom, 48)
                    
                    // Section d'aide
                    PublicHelpSection(
                        showingHelpCenter: $showingHelpCenter,
                        showingAbout: $showingAbout
                    )
                    .padding(.horizontal, 20)
                    .padding(.bottom, 60)
                }
            }
            .background(Color(.systemBackground))
            .navigationTitle("Compte")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingHelpCenter) {
                PublicHelpCenterView()
            }
            .sheet(isPresented: $showingAbout) {
                PublicAboutView()
            }
        }
    }
}

// MARK: - Header Section

private struct PublicAccountHeaderSection: View {
    var body: some View {
        VStack(spacing: 12) {
            // Titre principal
            Text("Choisissez votre espace")
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(StoreImmoTheme.navy)
            
            // Sous-titre discret
            Text("Accédez à votre espace ou créez votre compte.")
                .font(.system(size: 16))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Role Selection Section

private struct PublicRoleSelectionSection: View {
    @Environment(AppViewModel.self) private var viewModel
    
    var body: some View {
        VStack(spacing: 16) {
            // Carte Vendeur
            PublicRoleMinimalCard(
                role: .seller,
                action: {
                    withAnimation(.smooth(duration: 0.35)) {
                        viewModel.chooseRole(.seller)
                    }
                }
            )
            
            // Carte Agent
            PublicRoleMinimalCard(
                role: .agent,
                action: {
                    withAnimation(.smooth(duration: 0.35)) {
                        viewModel.chooseRole(.agent)
                    }
                }
            )
        }
    }
}

// MARK: - Minimal Role Card

private struct PublicRoleMinimalCard: View {
    let role: UserRole
    let action: () -> Void
    
    private var description: String {
        switch role {
        case .seller:
            "Publiez votre bien et développez votre projet."
        case .agent:
            "Développez votre activité immobilière."
        }
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Contenu textuel
                VStack(alignment: .leading, spacing: 6) {
                    Text(role.title.uppercased())
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(StoreImmoTheme.navy)
                    
                    Text(description)
                        .font(.system(size: 15))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(StoreImmoTheme.navy.opacity(0.5))
            }
            .padding(.vertical, 20)
            .padding(.horizontal, 20)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.1), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Help Section

private struct PublicHelpSection: View {
    @Binding var showingHelpCenter: Bool
    @Binding var showingAbout: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Titre de section
            HStack {
                Text("Besoin d'aide ?")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(StoreImmoTheme.navy)
                Spacer()
            }
            .padding(.bottom, 16)
            
            // Liste des options d'aide
            VStack(spacing: 0) {
                PublicHelpItemButton(
                    title: "Centre d'aide",
                    action: { showingHelpCenter = true }
                )
                
                Divider()
                    .padding(.leading, 16)
                
                PublicHelpItemButton(
                    title: "À propos de Store Immo",
                    action: { showingAbout = true }
                )
            }
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.1), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
        }
    }
}

// MARK: - Help Item Button

private struct PublicHelpItemButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Text(title)
                    .font(.system(size: 16))
                    .foregroundStyle(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(StoreImmoTheme.navy.opacity(0.4))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Public Help Center View

struct PublicHelpCenterView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showingReportProblem = false
    @State private var showingFAQ = false
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        showingReportProblem = true
                    } label: {
                        HStack {
                            Image(systemName: "exclamationmark.bubble.fill")
                                .font(.title3)
                                .foregroundStyle(.blue)
                                .frame(width: 28)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Signaler un problème")
                                    .font(.body)
                                    .foregroundStyle(.primary)
                                
                                Text("Contactez notre équipe de support")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.vertical, 4)
                    }
                    
                    Button {
                        showingFAQ = true
                    } label: {
                        HStack {
                            Image(systemName: "questionmark.circle.fill")
                                .font(.title3)
                                .foregroundStyle(.blue)
                                .frame(width: 28)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Questions fréquentes")
                                    .font(.body)
                                    .foregroundStyle(.primary)
                                
                                Text("Trouvez rapidement une réponse")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Text("Comment pouvons-nous vous aider ?")
                }
                
                Section {
                    HStack {
                        Image(systemName: "envelope.fill")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                            .frame(width: 28)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Email")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            Text("support@storeimmo.fr")
                                .font(.body)
                                .foregroundStyle(.primary)
                        }
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Nous contacter")
                }
            }
            .navigationTitle("Centre d'aide")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fermer") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingReportProblem) {
                ReportProblemView()
            }
            .sheet(isPresented: $showingFAQ) {
                PublicFAQView()
            }
        }
    }
}

// MARK: - Public FAQ View

struct PublicFAQView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var expandedItemID: UUID?
    @State private var searchText = ""
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredFAQItems) { item in
                    FAQItemView(
                        item: item,
                        isExpanded: expandedItemID == item.id
                    ) {
                        withAnimation {
                            if expandedItemID == item.id {
                                expandedItemID = nil
                            } else {
                                expandedItemID = item.id
                            }
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Rechercher...")
            .navigationTitle("Questions fréquentes")
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
    
    private var filteredFAQItems: [FAQItem] {
        if searchText.isEmpty {
            return publicFAQItems
        }
        return publicFAQItems.filter {
            $0.question.localizedCaseInsensitiveContains(searchText) ||
            $0.answer.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    private let publicFAQItems: [FAQItem] = [
        FAQItem(
            question: "Qu'est-ce que Store Immo ?",
            answer: "Store Immo est une plateforme qui met en relation les vendeurs de biens immobiliers avec des agents immobiliers vérifiés. Notre mission est de simplifier le processus de vente immobilière en permettant aux vendeurs de comparer facilement les profils et propositions des agents de leur secteur.",
            category: "Général"
        ),
        FAQItem(
            question: "Comment fonctionne Store Immo ?",
            answer: "Les vendeurs publient leur projet immobilier sur la plateforme. Les agents de leur secteur reçoivent une notification et peuvent postuler. Le vendeur compare les profils, échange avec les agents via messagerie, puis choisit celui qui lui convient le mieux.",
            category: "Général"
        ),
        FAQItem(
            question: "Store Immo est-il gratuit ?",
            answer: "Store Immo est entièrement gratuit pour les vendeurs. Les agents accèdent à la plateforme via un abonnement mensuel qui leur permet de candidater sur les projets de leur secteur.",
            category: "Tarifs"
        ),
        FAQItem(
            question: "Comment sont vérifiés les agents ?",
            answer: "Tous les agents présents sur Store Immo doivent fournir leur carte professionnelle ou leur numéro de mandataire. Nous vérifions l'authenticité de ces informations avant de valider leur compte.",
            category: "Sécurité"
        ),
        FAQItem(
            question: "Puis-je utiliser Store Immo partout en France ?",
            answer: "Oui, Store Immo est disponible dans toute la France. Notre réseau d'agents couvre l'ensemble du territoire, des grandes villes aux zones rurales.",
            category: "Général"
        ),
        FAQItem(
            question: "Comment créer mon compte ?",
            answer: "Choisissez votre profil (Vendeur ou Agent) depuis l'onglet Compte, puis suivez les étapes d'inscription. Vous recevrez un email de confirmation pour activer votre compte.",
            category: "Compte"
        ),
        FAQItem(
            question: "Mes données sont-elles sécurisées ?",
            answer: "Oui, nous prenons la sécurité de vos données très au sérieux. Toutes les informations sont cryptées et stockées de manière sécurisée. Nous ne partageons jamais vos données personnelles avec des tiers sans votre consentement.",
            category: "Sécurité"
        ),
        FAQItem(
            question: "Comment contacter le support ?",
            answer: "Vous pouvez nous contacter par email à support@storeimmo.fr ou utiliser le formulaire 'Signaler un problème' disponible dans le Centre d'aide. Notre équipe vous répondra sous 48h maximum.",
            category: "Support"
        )
    ]
}

// MARK: - Public About View

struct PublicAboutView: View {
    @Environment(\.dismiss) private var dismiss
    
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
    
    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(spacing: 16) {
                        Image(systemName: "building.2.fill")
                            .font(.system(size: 64))
                            .foregroundStyle(.blue)
                        
                        Text("Store Immo")
                            .font(.title.bold())
                        
                        Text("Votre partenaire immobilier")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                }
                .listRowBackground(Color.clear)
                
                Section {
                    HStack {
                        Text("Version")
                            .foregroundStyle(.primary)
                        Spacer()
                        Text("\(appVersion) (\(buildNumber))")
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Informations")
                }
                
                Section {
                    HStack {
                        Spacer()
                        Text("© 2024 Store Immo")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                }
                .listRowBackground(Color.clear)
            }
            .navigationTitle("À propos")
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
}

#Preview {
    PublicAccountTabView()
        .environment(AppViewModel())
}
