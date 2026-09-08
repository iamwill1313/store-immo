import SwiftUI

struct FAQView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppViewModel.self) private var viewModel
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
        let items = faqItems
        if searchText.isEmpty {
            return items
        }
        return items.filter {
            $0.question.localizedCaseInsensitiveContains(searchText) ||
            $0.answer.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    private var faqItems: [FAQItem] {
        if viewModel.selectedRole == .seller {
            return sellerFAQItems
        } else {
            return agentFAQItems
        }
    }
    
    private let sellerFAQItems: [FAQItem] = [
        FAQItem(
            question: "Comment publier un bien ?",
            answer: "Pour publier un bien, accédez à l'onglet Tableau de bord et appuyez sur le bouton '+'. Remplissez les informations de votre bien (adresse, type, prix souhaité, etc.) et ajoutez des photos. Votre projet sera visible par les agents de votre secteur dès sa publication.",
            category: "Projet"
        ),
        FAQItem(
            question: "Comment choisir un agent ?",
            answer: "Lorsque vous recevez des candidatures d'agents, consultez leur profil, leurs statistiques et leur proposition. Vous pouvez échanger avec eux via la messagerie avant de faire votre choix. Une fois décidé, validez l'agent directement depuis la fiche de candidature.",
            category: "Candidatures"
        ),
        FAQItem(
            question: "Puis-je modifier mon projet après publication ?",
            answer: "Oui, vous pouvez modifier les informations de votre projet à tout moment depuis le tableau de bord. Certaines modifications importantes (changement de prix, ajout de photos) notifieront les agents qui ont déjà postulé.",
            category: "Projet"
        ),
        FAQItem(
            question: "Comment fonctionne la messagerie ?",
            answer: "La messagerie vous permet d'échanger directement avec les agents qui ont postulé sur votre projet. Vous recevrez une notification pour chaque nouveau message. Les conversations sont organisées par projet.",
            category: "Messages"
        ),
        FAQItem(
            question: "Store Immo est-il gratuit pour les vendeurs ?",
            answer: "Oui, Store Immo est entièrement gratuit pour les vendeurs. Vous pouvez publier vos projets, recevoir des candidatures et échanger avec les agents sans aucun frais.",
            category: "Compte"
        ),
        FAQItem(
            question: "Comment supprimer mon compte ?",
            answer: "Pour supprimer votre compte, rendez-vous dans Compte > Paramètres > Confidentialité > Gestion des données. La suppression est définitive et toutes vos données seront effacées.",
            category: "Compte"
        )
    ]
    
    private let agentFAQItems: [FAQItem] = [
        FAQItem(
            question: "Comment fonctionne le système d'abonnement ?",
            answer: "Store Immo propose trois formules d'abonnement : Starter (3 candidatures actives), Pro (10 candidatures) et Elite (illimité). Chaque formule offre des avantages supplémentaires comme des badges de confiance et une meilleure visibilité.",
            category: "Abonnement"
        ),
        FAQItem(
            question: "Qu'est-ce qu'une candidature active ?",
            answer: "Une candidature active est une candidature en attente de réponse du vendeur. Une fois qu'un vendeur accepte ou refuse votre candidature, celle-ci devient inactive et libère une place pour postuler sur d'autres projets.",
            category: "Candidatures"
        ),
        FAQItem(
            question: "Comment optimiser mon profil ?",
            answer: "Pour optimiser votre profil : ajoutez une photo professionnelle, rédigez une description détaillée, complétez vos zones d'intervention, et encouragez vos clients à laisser des avis. Un profil complet augmente vos chances d'être sélectionné.",
            category: "Profil"
        ),
        FAQItem(
            question: "Comment ajuster mon rayon de recherche ?",
            answer: "Accédez à l'onglet Découvrir et utilisez le filtre de rayon en haut de l'écran. Vous pouvez choisir entre 10, 25, 50, 100 ou 250 km. Votre recherche est centrée sur la ville que vous avez indiquée dans votre profil.",
            category: "Recherche"
        ),
        FAQItem(
            question: "Que faire si je ne reçois pas de réponse ?",
            answer: "Les vendeurs peuvent prendre plusieurs jours pour étudier les candidatures. Assurez-vous que votre message de candidature est personnalisé et professionnel. Si après 2 semaines vous n'avez pas de retour, la candidature sera automatiquement considérée comme inactive.",
            category: "Candidatures"
        ),
        FAQItem(
            question: "Comment changer de formule d'abonnement ?",
            answer: "Vous pouvez changer de formule à tout moment depuis Compte > Paramètres. Le changement prend effet immédiatement. En cas de passage à une formule inférieure, vos candidatures actives resteront valides jusqu'à leur résolution.",
            category: "Abonnement"
        ),
        FAQItem(
            question: "Les vendeurs voient-ils toutes mes informations ?",
            answer: "Les vendeurs voient votre profil public (nom, agence, ville, badges, statistiques, avis). Votre email et numéro de téléphone ne sont partagés qu'après validation de votre candidature.",
            category: "Confidentialité"
        )
    ]
}

struct FAQItemView: View {
    let item: FAQItem
    let isExpanded: Bool
    let onTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: onTap) {
                questionHeader
            }
            .buttonStyle(.plain)
            
            if isExpanded {
                expandedContent
            }
        }
        .padding(.vertical, 8)
    }
    
    private var questionHeader: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.question)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                
                if !isExpanded {
                    Text(item.category)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.accentColor)
        }
        .contentShape(Rectangle())
    }
    
    private var expandedContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(item.answer)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.top, 4)
            
            HStack {
                categoryBadge
                Spacer()
            }
            .padding(.top, 8)
        }
    }
    
    private var categoryBadge: some View {
        Text(item.category)
            .font(.caption2.weight(.medium))
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.accentColor)
            .clipShape(Capsule())
    }
}

#Preview {
    @Previewable @State var viewModel = {
        let vm = AppViewModel()
        vm.selectedRole = .seller
        return vm
    }()
    
    return FAQView()
        .environment(viewModel)
}
