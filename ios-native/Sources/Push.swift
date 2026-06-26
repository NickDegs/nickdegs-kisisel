import SwiftUI
import UserNotifications

// İlk açılışta bildirim izni ister + APNs token alır (video hazır olunca push için)
final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        // Konumla arka plan açılışında (uygulama kapalıyken hareketle uyandırma) takibi hemen dirilt.
        // Tracker.shared.init zaten 'active' ise startUpdatingLocation + significant-change'i sürdürür.
        _ = Tracker.shared
        UNUserNotificationCenter.current().delegate = NotifDelegate.shared
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            if granted { DispatchQueue.main.async { application.registerForRemoteNotifications() } }
        }
        return true
    }
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let token = deviceToken.map { String(format: "%02x", $0) }.joined()
        UserDefaults.standard.set(token, forKey: "nd_apns")
        NotificationCenter.default.post(name: .ndApns, object: token)
    }
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {}
}

final class NotifDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotifDelegate()
    // uygulama açıkken de bildirim göster
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        [.banner, .sound, .badge]
    }
}

extension Notification.Name { static let ndApns = Notification.Name("nd_apns") }
