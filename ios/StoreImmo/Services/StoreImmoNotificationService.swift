import Foundation
import Observation
import UserNotifications
import UIKit

@Observable
@MainActor
final class StoreImmoNotificationService {
    var authorizationStatus: UNAuthorizationStatus = .notDetermined

    func refreshAuthorizationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        authorizationStatus = settings.authorizationStatus
        if authorizationStatus == .authorized {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }

    func requestAuthorizationIfNeeded() async {
        guard authorizationStatus == .notDetermined else {
            if authorizationStatus == .authorized {
                UIApplication.shared.registerForRemoteNotifications()
            }
            return
        }
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
            authorizationStatus = granted ? .authorized : .denied
            if granted {
                UIApplication.shared.registerForRemoteNotifications()
                print("[Push] Enregistrement APNs demandé")
            }
        } catch {
            authorizationStatus = .denied
        }
    }

    func scheduleSectorAlert(for project: PropertyProject) async {
        guard authorizationStatus == .authorized || authorizationStatus == .provisional else { return }

        let content = UNMutableNotificationContent()
        content.title = "Nouveau bien dans votre secteur"
        content.body = "\(project.title) · \(project.city) · \(project.formattedPrice)"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "sector-\(project.id.uuidString)", content: content, trigger: trigger)

        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
        }
    }
}

private extension PropertyProject {
    var formattedPrice: String {
        desiredPrice.formatted(.currency(code: "EUR").presentation(.narrow))
    }
}
