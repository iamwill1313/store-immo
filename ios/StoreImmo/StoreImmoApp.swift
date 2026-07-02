import SwiftUI
import UIKit

// MARK: - AppDelegate (APNs token callbacks)

private class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("[Push] Token APNs reçu:", token.prefix(16), "...")
        Task {
            await SupabaseRepository.shared.savePushToken(token)
        }
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("[Push] Echec enregistrement APNs:", error)
    }

    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        completionHandler(.newData)
    }
}

// MARK: - App

@main
struct StoreImmoApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
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
