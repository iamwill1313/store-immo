import SwiftUI

/// Public tab displaying available properties with real photos.
/// REFONTE VISUELLE — Affichage moderne des biens avec VRAIES photos
struct PublicPropertiesTabView: View {
    @Environment(AppViewModel.self) private var viewModel
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Section "Biens disponibles"
                    PublicPropertiesContentSection()
                        .padding(.horizontal, 24)
                        .padding(.top, 24)
                        .padding(.bottom, 32)
                    
                    // Bouton "Publier mon bien"
                    PublicPropertiesPublishButton()
                        .padding(.horizontal, 24)
                        .padding(.bottom, 40)
                }
            }
            .background(Color(.systemBackground))
            .navigationTitle("Biens")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Content Section (Biens disponibles)

private struct PublicPropertiesContentSection: View {
    @Environment(AppViewModel.self) private var viewModel
    
    var body: some View {
        VStack(spacing: 20) {
            // Titre de section
            VStack(spacing: 8) {
                Text("Biens disponibles")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(StoreImmoTheme.navy)
                    .multilineTextAlignment(.center)
                
                // Sous-titre
                Text("Découvrez les derniers biens publiés par nos vendeurs.")
                    .font(.system(size: 17, weight: .regular))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)
            
            // Liste des biens
            PublicPropertiesListView()
                .padding(.top, 8)
        }
    }
}

// MARK: - Properties List View

private struct PublicPropertiesListView: View {
    @Environment(AppViewModel.self) private var viewModel
    @State private var selectedProperty: PropertyProject?
    @State private var visiblePropertiesCount: Int = 4
    
    private let initialDisplayCount: Int = 4
    private let loadMoreIncrement: Int = 4
    
    var body: some View {
        if viewModel.publicProjects.isEmpty {
            // Empty state élégant
            VStack(spacing: 16) {
                Image(systemName: "house.slash")
                    .font(.system(size: 60))
                    .foregroundStyle(.secondary.opacity(0.5))
                
                Text("Aucun bien disponible")
                    .font(.title3.bold())
                    .foregroundStyle(.primary)
                
                Text("Les biens immobiliers publiés par les vendeurs apparaîtront ici.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 60)
        } else {
            ScrollViewReader { scrollProxy in
                LazyVStack(spacing: 16) {
                    // Afficher uniquement les biens visibles
                    ForEach(Array(viewModel.publicProjects.prefix(visiblePropertiesCount))) { property in
                        PublicPropertyModernCard(property: property)
                            .onTapGesture {
                                selectedProperty = property
                            }
                            .id(property.id)
                    }
                    
                    // Contrôles d'expansion/réduction
                    PublicPropertiesLoadingControls(
                        visibleCount: $visiblePropertiesCount,
                        totalCount: viewModel.publicProjects.count,
                        increment: loadMoreIncrement,
                        initialCount: initialDisplayCount,
                        scrollProxy: scrollProxy,
                        properties: viewModel.publicProjects
                    )
                    .id("controls")
                    
                    // Message discret après le dernier bien
                    if visiblePropertiesCount >= viewModel.publicProjects.count {
                        VStack(spacing: 6) {
                            Text("Professionnel de l'immobilier ou vendeur,")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundStyle(.secondary.opacity(0.7))
                            
                            Text("créez votre compte gratuitement.")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundStyle(.secondary.opacity(0.7))
                        }
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 32)
                        .padding(.bottom, 16)
                    }
                }
                .sheet(item: $selectedProperty) { property in
                    PublicPropertyDetailView(property: property)
                }
            }
            .onAppear {
                print("📱 PublicPropertiesTabView displaying:", viewModel.publicProjects.count, "properties")
                // Réinitialiser le compteur si nécessaire
                if visiblePropertiesCount > initialDisplayCount && viewModel.publicProjects.count <= initialDisplayCount {
                    visiblePropertiesCount = initialDisplayCount
                }
            }
        }
    }
}

// MARK: - Loading Controls (Afficher plus / Réduire)

private struct PublicPropertiesLoadingControls: View {
    @Binding var visibleCount: Int
    let totalCount: Int
    let increment: Int
    let initialCount: Int
    let scrollProxy: ScrollViewProxy
    let properties: [PropertyProject]
    
    private var canLoadMore: Bool {
        visibleCount < totalCount
    }
    
    private var canReduce: Bool {
        visibleCount > initialCount
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Bouton "Afficher plus de biens"
            if canLoadMore {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        visibleCount = min(visibleCount + increment, totalCount)
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 14, weight: .semibold))
                        
                        Text("Afficher plus")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundStyle(StoreImmoTheme.navy)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(StoreImmoTheme.mist, in: .rect(cornerRadius: 14))
                    .overlay {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(StoreImmoTheme.navy.opacity(0.15), lineWidth: 1)
                    }
                    .shadow(color: StoreImmoTheme.navy.opacity(0.08), radius: 4, y: 2)
                }
                .buttonStyle(.plain)
            }
            
            // Bouton "Réduire"
            if canReduce {
                Button(action: {
                    // Calculer l'index du dernier bien actuellement visible
                    let lastVisibleIndex = visibleCount - 1
                    
                    // Réduire le nombre de biens visibles
                    let newCount = max(visibleCount - increment, initialCount)
                    
                    withAnimation(.easeInOut(duration: 0.3)) {
                        visibleCount = newCount
                    }
                    
                    // Faire défiler vers le dernier bien qui reste visible
                    // Attendre la fin de l'animation pour que la mise à jour soit effective
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        let targetIndex = min(newCount - 1, properties.count - 1)
                        if targetIndex >= 0, targetIndex < properties.count {
                            withAnimation(.easeInOut(duration: 0.4)) {
                                scrollProxy.scrollTo(properties[targetIndex].id, anchor: .bottom)
                            }
                        }
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "chevron.up")
                            .font(.system(size: 14, weight: .semibold))
                        
                        Text("Réduire")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Color(.systemGray6), in: .rect(cornerRadius: 14))
                    .overlay {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(Color.secondary.opacity(0.15), lineWidth: 1)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.top, 8)
    }
}

// MARK: - Publish Button Section

private struct PublicPropertiesPublishButton: View {
    @Environment(AppViewModel.self) private var viewModel
    
    var body: some View {
        Button(action: {
            viewModel.chooseRole(.seller)
        }) {
            HStack(spacing: 10) {
                Text("Publier mon bien")
                    .font(.system(size: 20, weight: .semibold))
                
                Image(systemName: "arrow.right")
                    .font(.system(size: 18, weight: .semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(StoreImmoTheme.navy)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: StoreImmoTheme.navy.opacity(0.25), radius: 12, y: 4)
        }
        .buttonStyle(.plain)
    }
}


/// Carte moderne de propriété avec VRAIE photo en grand format
private struct PublicPropertyModernCard: View {
    let property: PropertyProject
    
    var body: some View {
        VStack(spacing: 0) {
            // Photo principale en grand format
            GeometryReader { proxy in
                ZStack(alignment: .topLeading) {
                    // Photo background
                    if let firstPhoto = property.photos.first {
                        if let urlString = firstPhoto.url, let url = URL(string: urlString) {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: proxy.size.width, height: proxy.size.height)
                                case .failure:
                                    propertyPlaceholder(photo: firstPhoto, size: proxy.size)
                                default:
                                    Color(.systemGray5)
                                        .overlay {
                                            ProgressView()
                                        }
                                }
                            }
                        } else {
                            propertyPlaceholder(photo: firstPhoto, size: proxy.size)
                        }
                    } else {
                        Color(StoreImmoTheme.navy)
                            .overlay {
                                VStack(spacing: 12) {
                                    Image(systemName: "house.fill")
                                        .font(.system(size: 50))
                                        .foregroundStyle(.white.opacity(0.5))
                                    Text("Aucune photo")
                                        .font(.subheadline.weight(.medium))
                                        .foregroundStyle(.white.opacity(0.7))
                                }
                            }
                    }
                }
                .frame(width: proxy.size.width, height: proxy.size.height)
                .clipped()
            }
            .frame(height: 220)
            .overlay(alignment: .topLeading) {
                // Badge type
                Text(property.propertyType.rawValue)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(StoreImmoTheme.navy.opacity(0.88), in: .capsule)
                    .padding(12)
            }
            .overlay(alignment: .topTrailing) {
                // Badge typologie
                Text(property.typology.rawValue)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(StoreImmoTheme.navy)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.white.opacity(0.92), in: .capsule)
                    .padding(12)
            }
            .overlay {
                // Gradient pour texte en bas
                LinearGradient(
                    colors: [.clear, .clear, .black.opacity(0.7)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .allowsHitTesting(false)
            }
            .overlay(alignment: .bottomLeading) {
                // Prix et localisation
                VStack(alignment: .leading, spacing: 4) {
                    Text(property.formattedPrice)
                        .font(.title3.bold())
                        .foregroundStyle(.white)
                    
                    HStack(spacing: 5) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.caption)
                        Text(property.city)
                            .font(.subheadline.weight(.medium))
                    }
                    .foregroundStyle(.white.opacity(0.9))
                }
                .padding(14)
            }
            
            // Informations en bas de carte
            VStack(alignment: .leading, spacing: 10) {
                Text(property.title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                
                if !property.description.isEmpty {
                    Text(property.description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                
                HStack(spacing: 8) {
                    if property.applications.count > 0 {
                        Label("\(property.applications.count) candidature\(property.applications.count > 1 ? "s" : "")", systemImage: "person.2.fill")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(StoreImmoTheme.navy)
                    }
                    
                    Label(property.idealListingDate.formatted(date: .abbreviated, time: .omitted), systemImage: "calendar")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.systemBackground))
        }
        .clipShape(.rect(cornerRadius: 20))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.08), radius: 12, y: 4)
    }
    
    @ViewBuilder
    private func propertyPlaceholder(photo: PhotoAsset, size: CGSize) -> some View {
        Color(StoreImmoTheme.navy)
            .overlay {
                LinearGradient(
                    colors: [StoreImmoTheme.slate, StoreImmoTheme.navy, .black.opacity(0.8)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .overlay {
                    VStack(spacing: 14) {
                        Image(systemName: photo.systemName)
                            .font(.system(size: 56))
                            .foregroundStyle(.white.opacity(0.85))
                        Text(photo.label)
                            .font(.headline)
                            .foregroundStyle(.white.opacity(0.75))
                    }
                }
            }
            .frame(width: size.width, height: size.height)
    }
}


/// Public Property Detail View — VRAIES photos en plein écran
private struct PublicPropertyDetailView: View {
    let property: PropertyProject
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Property photos carousel
                    if !property.photos.isEmpty {
                        TabView {
                            ForEach(property.photos) { photo in
                                PropertyPhotoFullView(photo: photo, title: property.title)
                            }
                        }
                        .frame(height: 320)
                        .tabViewStyle(.page(indexDisplayMode: .automatic))
                        .indexViewStyle(.page(backgroundDisplayMode: .always))
                    }
                    
                    // Property info
                    VStack(alignment: .leading, spacing: 20) {
                        // Type and typology
                        HStack(spacing: 10) {
                            Text(property.propertyType.rawValue)
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 7)
                                .background(StoreImmoTheme.navy, in: .capsule)
                            
                            Text(property.typology.rawValue)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(StoreImmoTheme.navy)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 7)
                                .background(StoreImmoTheme.mist, in: .capsule)
                        }
                        
                        // Title
                        Text(property.title)
                            .font(.title.bold())
                            .foregroundStyle(.primary)
                        
                        // Location
                        HStack(spacing: 8) {
                            Image(systemName: "mappin.circle.fill")
                                .foregroundStyle(StoreImmoTheme.navy)
                            Text(property.fullAddress)
                                .font(.body)
                                .foregroundStyle(.secondary)
                        }
                        
                        // Price
                        Text(property.formattedPrice)
                            .font(.system(size: 34, weight: .bold))
                            .foregroundStyle(StoreImmoTheme.navy)
                        
                        Divider()
                        
                        // Description
                        if !property.description.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Description")
                                    .font(.headline)
                                Text(property.description)
                                    .font(.body)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        // Extra information
                        if !property.extraInformation.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Informations complémentaires")
                                    .font(.headline)
                                Text(property.extraInformation)
                                    .font(.body)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        // Ideal listing date
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Date idéale de mise en vente")
                                .font(.headline)
                            HStack(spacing: 8) {
                                Image(systemName: "calendar.circle.fill")
                                    .foregroundStyle(StoreImmoTheme.navy)
                                Text(property.idealListingDate, style: .date)
                                    .font(.body)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        // Applications count
                        if property.applications.count > 0 {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Intérêt")
                                    .font(.headline)
                                HStack(spacing: 8) {
                                    Image(systemName: "person.2.fill")
                                        .foregroundStyle(StoreImmoTheme.navy)
                                    Text("\(property.applications.count) agent\(property.applications.count > 1 ? "s ont" : " a") candidaté")
                                        .font(.body)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer(minLength: 40)
                }
            }
            .navigationTitle("Détails du bien")
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
}

/// Vue photo individuelle en grand format
private struct PropertyPhotoFullView: View {
    let photo: PhotoAsset
    let title: String
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            if let urlString = photo.url, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    default:
                        photoPlaceholder
                    }
                }
            } else {
                photoPlaceholder
            }
            
            // Label photo
            Text(photo.label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(.black.opacity(0.6), in: .capsule)
                .padding(14)
        }
        .frame(height: 320)
        .clipShape(.rect(cornerRadius: 20))
    }
    
    private var photoPlaceholder: some View {
        Color(StoreImmoTheme.navy)
            .overlay {
                VStack(spacing: 14) {
                    Image(systemName: photo.systemName)
                        .font(.system(size: 60))
                        .foregroundStyle(.white.opacity(0.7))
                    Text(photo.label)
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.8))
                }
            }
    }
}

private extension PropertyProject {
    var formattedPrice: String {
        desiredPrice.formatted(.currency(code: "EUR").presentation(.narrow))
    }
}

#Preview {
    PublicPropertiesTabView()
        .environment(AppViewModel())
}
