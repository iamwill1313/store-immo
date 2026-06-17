import SwiftUI

nonisolated enum StoreImmoTheme {
    static let navy: Color = Color(red: 10 / 255, green: 37 / 255, blue: 64 / 255)
    static let slate: Color = Color(red: 78 / 255, green: 93 / 255, blue: 112 / 255)
    static let mist: Color = Color(red: 242 / 255, green: 245 / 255, blue: 248 / 255)

    static let heroGradient: LinearGradient = LinearGradient(
        colors: [navy, Color(red: 25 / 255, green: 59 / 255, blue: 97 / 255), Color.black.opacity(0.92)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let panelGradient: LinearGradient = LinearGradient(
        colors: [Color.white.opacity(0.16), Color.white.opacity(0.04)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

extension View {
    func storeImmoCardStyle() -> some View {
        self
            .padding(16)
            .background(Color(.secondarySystemBackground), in: .rect(cornerRadius: 24))
    }

    func storeImmoPremiumCardStyle() -> some View {
        self
            .padding(18)
            .background(.regularMaterial, in: .rect(cornerRadius: 26))
            .overlay {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .strokeBorder(.white.opacity(0.18), lineWidth: 1)
            }
    }
}
