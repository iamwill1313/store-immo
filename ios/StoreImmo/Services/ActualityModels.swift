import Foundation

// MARK: - Actuality Models for Public Home

/// Category of real estate news
enum ActualityCategory: String, Identifiable, CaseIterable {
    case market = "Marché"
    case regulation = "Réglementation"
    case dpe = "DPE"
    case investment = "Investissement"
    case local = "Actualité locale"
    case national = "Actualité nationale"
    
    var id: String { rawValue }
    
    var symbolName: String {
        switch self {
        case .market:
            return "chart.line.uptrend.xyaxis"
        case .regulation:
            return "doc.text.fill"
        case .dpe:
            return "leaf.fill"
        case .investment:
            return "eurosign.circle.fill"
        case .local:
            return "mappin.circle.fill"
        case .national:
            return "flag.fill"
        }
    }
    
    var accentColor: String {
        switch self {
        case .market:
            return "blue"
        case .regulation:
            return "purple"
        case .dpe:
            return "green"
        case .investment:
            return "orange"
        case .local:
            return "cyan"
        case .national:
            return "indigo"
        }
    }
}

/// Real estate news item for the public home
struct ActualityItem: Identifiable {
    let id: UUID
    let title: String
    let excerpt: String
    let category: ActualityCategory
    let date: Date
    let imageURL: String?
    let content: String
    
    init(
        id: UUID = UUID(),
        title: String,
        excerpt: String,
        category: ActualityCategory,
        date: Date,
        imageURL: String? = nil,
        content: String
    ) {
        self.id = id
        self.title = title
        self.excerpt = excerpt
        self.category = category
        self.date = date
        self.imageURL = imageURL
        self.content = content
    }
}

// MARK: - Mock Data Factory

struct ActualityDataFactory {
    /// Mock actuality items for the public home (v1)
    /// Can be replaced with API calls in future versions
    static func makeMockActualities() -> [ActualityItem] {
        [
            ActualityItem(
                title: "DPE 2026 : Nouvelles obligations pour les propriétaires",
                excerpt: "À partir de janvier 2026, de nouvelles règles entrent en vigueur concernant le Diagnostic de Performance Énergétique.",
                category: .dpe,
                date: Date().addingTimeInterval(-86400 * 2),
                content: """
                Les propriétaires bailleurs devront désormais respecter des seuils de consommation énergétique plus stricts. Les logements classés G seront interdits à la location dès le 1er janvier 2026.
                
                Cette mesure vise à améliorer la performance énergétique du parc immobilier français et à réduire les émissions de CO2.
                
                Les propriétaires sont invités à réaliser des travaux de rénovation énergétique pour améliorer la classification de leur bien.
                """
            ),
            
            ActualityItem(
                title: "Marché immobilier PACA : Hausse de 3,2% en 2025",
                excerpt: "Le marché immobilier de la région Provence-Alpes-Côte d'Azur affiche une croissance soutenue selon les derniers chiffres.",
                category: .market,
                date: Date().addingTimeInterval(-86400 * 5),
                content: """
                La région PACA enregistre une hausse de 3,2% des prix immobiliers sur l'année 2025, portée par une forte demande sur le littoral méditerranéen.
                
                Les villes de Nice, Marseille et Aix-en-Provence sont particulièrement dynamiques, avec des prix au m² en progression constante.
                
                Les experts prévoient une stabilisation du marché au premier semestre 2026, avec un maintien des prix à leur niveau actuel.
                """
            ),
            
            ActualityItem(
                title: "Nouvelle loi sur l'encadrement des loyers",
                excerpt: "Le gouvernement annonce un renforcement de l'encadrement des loyers dans 15 grandes agglomérations françaises.",
                category: .regulation,
                date: Date().addingTimeInterval(-86400 * 7),
                content: """
                À compter de mars 2026, quinze nouvelles agglomérations seront soumises à l'encadrement des loyers, rejoignant Paris, Lyon et Lille.
                
                Cette mesure vise à limiter les hausses excessives de loyers et à garantir l'accès au logement pour tous.
                
                Les propriétaires devront respecter des plafonds de loyers fixés par arrêté préfectoral, sous peine de sanctions financières.
                """
            ),
            
            ActualityItem(
                title: "Investissement locatif : Les dispositifs fiscaux 2026",
                excerpt: "Tour d'horizon des dispositifs fiscaux disponibles pour les investisseurs en immobilier locatif cette année.",
                category: .investment,
                date: Date().addingTimeInterval(-86400 * 10),
                content: """
                Les dispositifs Pinel, Denormandie et Loc'Avantages restent en vigueur en 2026, avec quelques ajustements à la baisse des taux de réduction d'impôt.
                
                Le dispositif Pinel+ offre toujours des avantages fiscaux intéressants pour les logements respectant des critères de performance énergétique élevés.
                
                Les investisseurs sont invités à se rapprocher de professionnels pour optimiser leur stratégie d'investissement locatif.
                """
            ),
            
            ActualityItem(
                title: "Marseille : Un nouveau quartier éco-responsable en projet",
                excerpt: "La ville de Marseille dévoile son projet d'éco-quartier de 500 logements dans le secteur nord de la ville.",
                category: .local,
                date: Date().addingTimeInterval(-86400 * 14),
                content: """
                Le projet "Quartier Vert Nord" prévoit la construction de 500 logements éco-responsables, intégrant des espaces verts, des commerces de proximité et des équipements publics.
                
                Ce nouveau quartier sera desservi par une ligne de tramway et des pistes cyclables, favorisant les mobilités douces.
                
                Les premiers logements devraient être livrés fin 2027, avec une priorité donnée aux primo-accédants et aux familles.
                """
            ),
            
            ActualityItem(
                title: "Taux d'intérêt immobiliers : Légère baisse attendue",
                excerpt: "Les taux d'intérêt des crédits immobiliers pourraient connaître une légère baisse au premier trimestre 2026.",
                category: .national,
                date: Date().addingTimeInterval(-86400 * 18),
                content: """
                Les experts anticipent une baisse des taux d'intérêt des crédits immobiliers de l'ordre de 0,15 à 0,25 point au premier trimestre 2026.
                
                Cette évolution est liée à la politique monétaire de la Banque Centrale Européenne et à la stabilisation de l'inflation.
                
                Les acquéreurs potentiels sont invités à surveiller l'évolution des taux et à se rapprocher de courtiers pour obtenir les meilleures conditions de financement.
                """
            )
        ]
    }
}
