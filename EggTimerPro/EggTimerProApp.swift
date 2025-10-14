import SwiftUI
import Firebase
import FirebaseMessaging
import AppsFlyerLib
import AppTrackingTransparency
import Network

@main
struct MyApp: App {
    
    @UIApplicationDelegateAdaptor(ApplicationHandler.self) var applicationHandler
    
    var body: some Scene {
        WindowGroup {
            EggTImerSplashView()
        }
    }
    
}

struct ContentView: View {
    
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding: Bool = false
    @StateObject private var recipeData = RecipeData()
    @StateObject private var timerState = TimerState(onTimerFinish: {})
    
    var body: some View {
        VStack {
            if hasSeenOnboarding {
                TabViewScreen()
                    .environmentObject(recipeData)
                    .environmentObject(timerState)
            } else {
                OnboardView()
                    .environmentObject(recipeData)
                    .environmentObject(timerState)
            }
        }
    }
    
}

class ApplicationHandler: UIResponder, UIApplicationDelegate, AppsFlyerLibDelegate, MessagingDelegate, UNUserNotificationCenterDelegate {
    
    private var attributionInfo: [AnyHashable: Any] = [:]
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
        
        AppsFlyerLib.shared().appsFlyerDevKey = "5erfYyPGDAXJ5VJDrwwyej"
        AppsFlyerLib.shared().appleAppID = "6753346849"
        AppsFlyerLib.shared().delegate = self
        AppsFlyerLib.shared().start()
        
        // Messaging delegate for Firebase
        Messaging.messaging().delegate = self
        
        UNUserNotificationCenter.current().delegate = self
        
        application.registerForRemoteNotifications()
        
        if let pushData = launchOptions?[.remoteNotification] as? [AnyHashable: Any] {
            processPushData(pushData)
        }
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(activateTracking),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        
        return true
    }
    
    
    @objc private func activateTracking() {
        AppsFlyerLib.shared().start()
        if #available(iOS 14, *) {
            ATTrackingManager.requestTrackingAuthorization { status in
            }
        }
    }
    
    func onConversionDataSuccess(_ data: [AnyHashable: Any]) {
        attributionInfo = data
        NotificationCenter.default.post(name: Notification.Name("ConversionDataReceived"), object: nil, userInfo: ["conversionData": attributionInfo])
    }
    
    func onConversionDataFail(_ error: Error) {
        NotificationCenter.default.post(name: Notification.Name("ConversionDataReceived"), object: nil, userInfo: ["conversionData": [:]])
    }
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        // Handle token refresh and re-request
        messaging.token { token, error in
            if let error = error {
            }
            UserDefaults.standard.set(token, forKey: "fcm_token")
        }
        // sendConfigRequest()
    }
    
    // Handle APNS token
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
    }
    
    // Push notification handlers
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let payload = notification.request.content.userInfo
        processPushData(payload)
        completionHandler([.banner, .sound])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let payload = response.notification.request.content.userInfo
        processPushData(payload)
        completionHandler()
    }
    
    func application(_ application: UIApplication,
                     didReceiveRemoteNotification userInfo: [AnyHashable : Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        processPushData(userInfo)
        completionHandler(.newData)
    }
    
    private func processPushData(_ payload: [AnyHashable: Any]) {
        var linkStr: String?
        if let link = payload["url"] as? String {
            linkStr = link
        } else if let info = payload["data"] as? [String: Any], let link = info["url"] as? String {
            linkStr = link
        }
        
        if let linkStr = linkStr {
            UserDefaults.standard.set(linkStr, forKey: "temp_url")
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                NotificationCenter.default.post(name: NSNotification.Name("LoadTempURL"), object: nil, userInfo: ["tempUrl": linkStr])
            }
        }
    }
    
}
