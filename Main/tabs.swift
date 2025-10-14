
import SwiftUI
import WebKit
import Combine

struct TabViewScreen: View {
    @EnvironmentObject var recipeData: RecipeData
    @EnvironmentObject var timerState: TimerState
    @AppStorage("selectedTab") private var selectedTab: Int = 0
    let yolkYellow = Color(hex: "#FFD93D")
    let creamyWhite = Color(hex: "#FFF9E6")
    
    var body: some View {
        ZStack {
            // Creamy white gradient background
            LinearGradient(
                gradient: Gradient(colors: [creamyWhite, creamyWhite.opacity(0.8)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack {
                // Content for selected tab
                switch selectedTab {
                case 0:
                    HomeView()
                case 1:
                    TimerView()
                case 2:
                    RecipesView()
                case 3:
                    DailyView()
                case 4:
                    ProfileView()
                default:
                    HomeView()
                }
                
                Spacer()
            }
            
            // Custom Tab Bar
            VStack {
                Spacer()
                HStack {
                    TabButton(index: 0, icon: "house", label: "Home", isSelected: selectedTab == 0, yolkYellow: yolkYellow) {
                        selectedTab = 0
                    }
                    TabButton(index: 1, icon: "timer", label: "Timer", isSelected: selectedTab == 1, yolkYellow: yolkYellow) {
                        selectedTab = 1
                    }
                    TabButton(index: 2, icon: "fork.knife", label: "Recipes", isSelected: selectedTab == 2, yolkYellow: yolkYellow) {
                        selectedTab = 2
                    }
                    TabButton(index: 3, icon: "book", label: "Diary", isSelected: selectedTab == 3, yolkYellow: yolkYellow) {
                        selectedTab = 3
                    }
                    TabButton(index: 4, icon: "person", label: "Profile", isSelected: selectedTab == 4, yolkYellow: yolkYellow) {
                        selectedTab = 4
                    }
                }
                .padding(.vertical, 25)
                .padding(.horizontal)
                .background(Color.white.opacity(0.9))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 2)
            }
            .ignoresSafeArea(edges: .bottom)
        }
        .navigationTitle("Tabs")
    }
}

struct TabButton: View {
    let index: Int
    let icon: String
    let label: String
    let isSelected: Bool
    let yolkYellow: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .foregroundColor(isSelected ? yolkYellow : .gray)
                Text(label)
                    .font(.caption)
                    .foregroundColor(isSelected ? yolkYellow : .gray)
            }
            .frame(maxWidth: .infinity)
        }
    }
}


class WebContentController: ObservableObject {
    @Published var mainWebView: WKWebView!
    @Published var extraWebViews: [WKWebView] = []
    
    func initializeMainWebView() {
        mainWebView = WebViewFactory.generateMainWebView()
        mainWebView.scrollView.minimumZoomScale = 1.0
        mainWebView.scrollView.maximumZoomScale = 1.0
        mainWebView.scrollView.bouncesZoom = false
        mainWebView.allowsBackForwardNavigationGestures = true
    }
    
    func restoreSavedCookies() {
        guard let savedCookies = UserDefaults.standard.dictionary(forKey: "stored_cookies") as? [String: [String: [HTTPCookiePropertyKey: AnyObject]]] else { return }
        let store = mainWebView.configuration.websiteDataStore.httpCookieStore
        
        savedCookies.values.flatMap { $0.values }.forEach { props in
            if let cookie = HTTPCookie(properties: props as! [HTTPCookiePropertyKey: Any]) {
                store.setCookie(cookie)
            }
        }
    }
    
    func updateContent() {
        mainWebView.reload()
    }
    
    func needsToClearExtras(activeLink: URL?) {
        if !extraWebViews.isEmpty {
            if let topExtra = extraWebViews.last {
                topExtra.removeFromSuperview()
                extraWebViews.removeLast()
            }
            if let link = activeLink {
                mainWebView.load(URLRequest(url: link))
            }
        } else if mainWebView.canGoBack {
            mainWebView.goBack()
        }
    }
    
    func dismissTopExtra() {
        if let topExtra = extraWebViews.last {
            topExtra.removeFromSuperview()
            extraWebViews.removeLast()
            //objectWillChange.send()
        }
    }
    
}

struct PrimaryWebView: UIViewRepresentable {
    let targetURL: URL
    @StateObject private var controller = WebContentController()
    
    func makeUIView(context: Context) -> WKWebView {
        controller.initializeMainWebView()
        controller.mainWebView.uiDelegate = context.coordinator
        controller.mainWebView.navigationDelegate = context.coordinator
    
        controller.restoreSavedCookies()
        controller.mainWebView.load(URLRequest(url: targetURL))
        return controller.mainWebView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        // webView.load(URLRequest(url: targetURL))
    }
    
    func makeCoordinator() -> WebViewHandler {
        WebViewHandler(controller: controller)
    }
    
}


struct TabViewScreen_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            TabViewScreen()
                .environmentObject(RecipeData())
                .environmentObject(TimerState(onTimerFinish: {}))
        }
    }
}
