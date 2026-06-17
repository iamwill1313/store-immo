import SwiftUI

@main
struct StoreImmoApp: App {
    @State private var viewModel = AppViewModel()
    @State private var readinessService = StoreImmoReadinessService()
    @State private var notificationService = StoreImmoNotificationService()
    @State private var supabase = SupabaseService.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(viewModel)
                .environment(readinessService)
                .environment(notificationService)
                .environment(supabase)
        }
    }
}
