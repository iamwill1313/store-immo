import SwiftUI

// MARK: - Actuality Section for Public Home

struct ActualitySectionView: View {
    @State private var selectedActuality: ActualityItem?
    
    private let actualities = ActualityDataFactory.makeMockActualities()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header
            HStack {
                Image(systemName: "newspaper.fill")
                    .font(.title2)
                    .foregroundStyle(.blue)
                Text("Actualité immobilière")
                    .font(.title2.weight(.bold))
            }
            .padding(.horizontal, 20)
            
            // Horizontal scroll of actuality cards
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(actualities) { actuality in
                        ActualityCardView(actuality: actuality)
                            .onTapGesture {
                                selectedActuality = actuality
                            }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .sheet(item: $selectedActuality) { actuality in
            ActualityDetailView(actuality: actuality)
        }
    }
}

// MARK: - Actuality Card

private struct ActualityCardView: View {
    let actuality: ActualityItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Category badge
            HStack(spacing: 6) {
                Image(systemName: actuality.category.symbolName)
                    .font(.caption.weight(.semibold))
                Text(actuality.category.rawValue)
                    .font(.caption.weight(.semibold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(categoryColor(for: actuality.category), in: .capsule)
            
            // Title
            Text(actuality.title)
                .font(.headline)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
            
            // Excerpt
            Text(actuality.excerpt)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
            
            // Date
            HStack {
                Image(systemName: "calendar")
                    .font(.caption)
                Text(actuality.date, style: .date)
                    .font(.caption)
            }
            .foregroundStyle(.secondary)
        }
        .frame(width: 280, height: 200)
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }
    
    private func categoryColor(for category: ActualityCategory) -> Color {
        switch category {
        case .market:
            return .blue
        case .regulation:
            return .purple
        case .dpe:
            return .green
        case .investment:
            return .orange
        case .local:
            return .cyan
        case .national:
            return .indigo
        }
    }
}

// MARK: - Actuality Detail View

private struct ActualityDetailView: View {
    let actuality: ActualityItem
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Category badge
                    HStack(spacing: 6) {
                        Image(systemName: actuality.category.symbolName)
                            .font(.subheadline.weight(.semibold))
                        Text(actuality.category.rawValue)
                            .font(.subheadline.weight(.semibold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(categoryColor(for: actuality.category), in: .capsule)
                    
                    // Title
                    Text(actuality.title)
                        .font(.title.weight(.bold))
                    
                    // Date
                    HStack {
                        Image(systemName: "calendar")
                            .font(.subheadline)
                        Text(actuality.date, style: .date)
                            .font(.subheadline)
                    }
                    .foregroundStyle(.secondary)
                    
                    Divider()
                    
                    // Excerpt
                    Text(actuality.excerpt)
                        .font(.body.weight(.medium))
                        .foregroundStyle(.secondary)
                    
                    // Full content
                    Text(actuality.content)
                        .font(.body)
                        .lineSpacing(4)
                    
                    Spacer(minLength: 40)
                }
                .padding(20)
            }
            .navigationTitle("Actualité")
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
    
    private func categoryColor(for category: ActualityCategory) -> Color {
        switch category {
        case .market:
            return .blue
        case .regulation:
            return .purple
        case .dpe:
            return .green
        case .investment:
            return .orange
        case .local:
            return .cyan
        case .national:
            return .indigo
        }
    }
}

#Preview {
    ActualitySectionView()
}
