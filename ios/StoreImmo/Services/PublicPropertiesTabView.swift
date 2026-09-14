import SwiftUI

/// Public tab displaying available properties with real photos.
/// REFONTE VISUELLE — Affichage moderne des biens avec VRAIES photos
struct PublicPropertiesTabView: View {
    @Environment(AppViewModel.self) private var viewModel
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header avec compteur
                    PropertiesHeaderView()
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                    
                    // Grid de propriétés avec VRAIES photos
                    PublicPropertiesGridView()
                        .padding(.horizontal, 20)
                    
                    // CTA vendeur
                    PublicPropertiesCTASection()
                        .padding(.horizontal, 20)
                        .padding(.bottom, 32)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Biens")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

/// Header moderne avec compteur de biens
private struct PropertiesHeaderView: View {
    @Environment(AppViewModel.self) private var viewModel
    
    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            // Icône
            Image(systemName: "house.fill")
                .font(.title)
                .foregroundStyle(StoreImmoTheme.navy)
                .frame(width: 50, height: 50)
                .background(StoreImmoTheme.mist, in: .circle)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Biens disponibles")
                    .font(.title3.bold())
                    .foregroundStyle(.primary)
                
                if viewModel.sellerProjects.isEmpty {
                    Text("Aucun bien pour le moment")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    Text("\(viewModel.sellerProjects.count) \(viewModel.sellerProjects.count > 1 ? "biens" : "bien") en ligne")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(StoreImmoTheme.navy)
                }
            }
            
            Spacer()
        }
        .padding(16)
        .background(Color(.secondarySystemBackground), in: .rect(cornerRadius: 18))
    }
}

/// Grid moderne des propriétés avec photos réelles
private struct PublicPropertiesGridView: View {
    @Environment(AppViewModel.self) private var viewModel
    @State private var selectedProperty: PropertyProject?
    
    var body: some View {
        if viewModel.sellerProjects.isEmpty {
            // Empty state élégant
            ContentUnavailableView {
                VStack(spacing: 16) {
                    Image(systemName: "house.slash")
                        .font(.system(size: 60))
                        .foregroundStyle(.secondary.opacity(0.5))
                    Text("Aucun bien disponible")
                        .font(.title3.bold())
                }
            } description: {
                Text("Les biens immobiliers publiés par les vendeurs apparaîtront ici.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(minHeight: 300)
        } else {
            LazyVStack(spacing: 16) {
                ForEach(viewModel.sellerProjects) { property in
                    PublicPropertyModernCard(property: property)
                        .onTapGesture {
                            selectedProperty = property
                        }
                }
            }
            .sheet(item: $selectedProperty) { property in
                PublicPropertyDetailView(property: property)
            }
        }
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

/// CTA section encouraging users to create their own property listing
private struct PublicPropertiesCTASection: View {
    @Environment(AppViewModel.self) private var viewModel
    
    var body: some View {
        VStack(spacing: 18) {
            HStack(spacing: 12) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(StoreImmoTheme.navy)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Vous avez un bien à vendre ?")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    Text("Publiez gratuitement et recevez des candidatures d'agents")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Spacer()
            }
            
            Button {
                viewModel.chooseRole(.seller)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.right.circle.fill")
                    Text("Publier mon bien")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(StoreImmoTheme.navy, in: .rect(cornerRadius: 14))
                .foregroundStyle(.white)
            }
            .buttonStyle(.plain)
        }
        .padding(20)
        .background(Color(.secondarySystemBackground), in: .rect(cornerRadius: 20))
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
