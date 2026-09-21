import Foundation

// MARK: - News Models (Supabase-backed actualities, Phase 2 validation)

nonisolated struct NewsSeries: Identifiable, Codable, Sendable {
    let id: UUID
    let title: String
    let weekStart: Date
    let weekEnd: Date
    let isActive: Bool
    let createdAt: Date
}

nonisolated struct NewsArticle: Identifiable, Codable, Sendable {
    let id: UUID
    let seriesId: UUID
    let title: String
    let summary: String
    let category: String
    let sourceName: String
    let sourceURL: URL
    let publishedAt: Date?
    let createdAt: Date
    let contentHash: String
}
