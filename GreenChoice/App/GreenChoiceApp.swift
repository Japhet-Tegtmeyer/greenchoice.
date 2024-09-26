//
//  GreenChoiceApp.swift
//  GreenChoice
//
//  Created by Japhet Tegtmeyer on 9/21/24.
//

import FirebaseCore
import SwiftUI
import UserNotifications
import FirebaseMessaging
import FirebaseFirestore

class AppDelegate: NSObject, UIApplicationDelegate, MessagingDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        application.registerForRemoteNotifications()
        Messaging.messaging().delegate = self
        UNUserNotificationCenter.current().delegate = self
        
        return true
    }
    
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }
    
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        if let fcm = Messaging.messaging().fcmToken {
            print("fcm", fcm)
        }
    }
}

@main
struct GreenChoiceApp: App {
    // register app delegate for Firebase setup
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    @StateObject var authManager: AuthManager
    @StateObject var notificationManager = NotificationManager()
    @StateObject var uploader = ManufacturerUploader()
    
    init() {
        // Use Firebase library to configure APIs
        FirebaseApp.configure()
        
        let authManager = AuthManager()
        _authManager = StateObject(wrappedValue: authManager)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
                .preferredColorScheme(.light)
                .onChange(of: notificationManager.hasPermission) { newValue in
                    updateFirebase(key: "notificationsEnabled", value: newValue)
                }
        }
    }
    
    private func updateFirebase(key: String, value: Bool) {
        guard let userId = authManager.currentUser?.id else {
            print("Error: User ID not found")
            return
        }
        
        let db = Firestore.firestore()
        db.collection("users").document(userId).updateData([
            "preferences.\(key)": value
        ]) { error in
            if let error = error {
                print("Error updating Firebase: \(error.localizedDescription)")
            } else {
                print("Successfully updated \(key) to \(value) in Firebase")
                // Update local user object
                switch key {
                case "hapticsEnabled":
                    authManager.currentUser?.preferences.hapticsEnabled = value
                default:
                    break
                }
            }
        }
    }
}
