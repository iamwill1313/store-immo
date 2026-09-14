import SwiftUI

// MARK: - Public Properties Section for Public Home

struct PublicPropertiesSectionView: View {
    @Environment(AppViewModel.self) private var viewModel
    @State private var selectedProperty: PropertyProject?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header
            HStack {
                Image(systemName: "house.fill")
                    .font(.title2)
                    .foregroundStyle(.orange)
                Text("Biens disponibles")
                    .font(.title2.weight(.bold))
                Spacer()
                if !viewModel.sellerProjects.isEmpty {
                    Text("\(viewModel.sellerProjects.count)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 20)
            
            // Properties list
            if viewModel.sellerProjects.isEmpty {
                // Empty state
                ContentUnavailableView {
                    Label("Aucun bien disponible", systemImage: "house")
                } description: {
                    Text("Les biens immobiliers proposés apparaîtront ici.")
                }
                .frame(height: 200)
            } else {
                VStack(spacing: 14) {
                    ForEach(viewModel.sellerProjects.prefix(6)) { property in
                        PublicPropertyCardView(property: property)
                            .onTapGesture {
                                selectedProperty = property
                            }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .sheet(item: $selectedProperty) { property in
            PublicPropertyDetailView(property: property)
        }
    }
}

// MARK: - Public Property Card

private struct PublicPropertyCardView: View {
    let property: PropertyProject
    
    var body: some View {
        HStack(spacing: 14) {
            // Property image
            if let firstPhoto = property.photos.first {
                if let urlString = firstPhoto.url, let url = URL(string: urlString) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                        default:
                            propertyPlaceholder
                        }
                    }
                    .frame(width: 100, height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    propertyPlaceholder
                }
            } else {
                propertyPlaceholder
            }
            
            // Property info
            VStack(alignment: .leading, spacing: 6) {
                // Type badge
                Text(property.propertyType.rawValue)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.orange, in: .capsule)
                
                // Title
                Text(property.title)
                    .font(.headline)
                    .lineLimit(1)
                
                // Location
                HStack(spacing: 4) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.caption)
                    Text(property.city)
                        .font(.subheadline)
                }
                .foregroundStyle(.secondary)
                
                // Price
                Text(property.formattedPrice)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.orange)
            }
            
            Spacer()
            
            // Chevron
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.05), radius: 6, y: 3)
    }
    
    private var propertyPlaceholder: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(
                LinearGradient(
                    colors: [Color(red: 0.2, green: 0.3, blue: 0.4), Color(red: 0.1, green: 0.2, blue: 0.3)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 100, height: 100)
            .overlay {
                Image(systemName: "house.fill")
                    .font(.largeTitle)
                    .foregroundStyle(.white.opacity(0.5))
            }
    }
}

// MARK: - Public Property Detail View

private struct PublicPropertyDetailView: View {
    let property: PropertyProject
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Property photos
                    if !property.photos.isEmpty {
                        TabView {
                            ForEach(property.photos) { photo in
                                if let urlString = photo.url, let url = URL(string: urlString) {
                                    AsyncImage(url: url) { phase in
                                        switch phase {
                                        case .success(let image):
                                            image
                                                .resizable()
                                                .scaledToFill()
                                        default:
                                            photoPlaceholder(photo: photo)
                                        }
                                    }
                                    .frame(height: 250)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                } else {
                                    photoPlaceholder(photo: photo)
                                }
                            }
                        }
                        .frame(height: 250)
                        .tabViewStyle(.page(indexDisplayMode: .automatic))
                    }
                    
                    // Property info
                    VStack(alignment: .leading, spacing: 16) {
                        // Type and typology
                        HStack(spacing: 8) {
                            Text(property.propertyType.rawValue)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(.orange, in: .capsule)
                            
                            Text(property.typology.rawValue)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }
                        
                        // Title
                        Text(property.title)
                            .font(.title.weight(.bold))
                        
                        // Location
                        HStack(spacing: 6) {
                            Image(systemName: "mappin.circle.fill")
                                .foregroundStyle(.orange)
                            Text(property.fullAddress)
                                .font(.body)
                                .foregroundStyle(.secondary)
                        }
                        
                        // Price
                        Text(property.formattedPrice)
                            .font(.largeTitle.weight(.bold))
                            .foregroundStyle(.orange)
                        
                        Divider()
                        
                        // Description
                        if !property.description.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Description")
                                    .font(.headline)
                                Text(property.description)
                                    .font(.body)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        // Extra information
                        if !property.extraInformation.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Informations complémentaires")
                                    .font(.headline)
                                Text(property.extraInformation)
                                    .font(.body)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        // Ideal listing date
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Date idéale de mise en vente")
                                .font(.headline)
                            HStack(spacing: 6) {
                                Image(systemName: "calendar")
                                Text(property.idealListingDate, style: .date)
                                    .font(.body)
                            }
                            .foregroundStyle(.secondary)
                        }
                    }
                    
                    Spacer(minLength: 40)
                }
                .padding(20)
            }
            .navigationTitle("Détails du bien")
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
    
    private func photoPlaceholder(photo: PhotoAsset) -> some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(
                LinearGradient(
                    colors: [Color(red: 0.2, green: 0.3, blue: 0.4), Color(red: 0.1, green: 0.2, blue: 0.3)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(height: 250)
            .overlay {
                VStack(spacing: 12) {
                    Image(systemName: photo.systemName)
                        .font(.system(size: 60))
                        .foregroundStyle(.white.opacity(0.5))
                    Text(photo.label)
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.7))
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
    @Previewable @State var viewModel = AppViewModel()
    PublicPropertiesSectionView()
        .environment(viewModel)
}
