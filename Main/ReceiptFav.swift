
import SwiftUI
import WebKit

struct FavoritesView: View {
    @EnvironmentObject var recipeData: RecipeData
    let yolkYellow = Color(hex: "#FFD93D")
    let creamyWhite = Color(hex: "#FFF9E6")
    
    var favoriteRecipes: [Recipe] {
        recipeData.allRecipes.filter { recipeData.favoriteIds.contains($0.id) }
    }
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [creamyWhite, creamyWhite.opacity(0.8)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    Text("Favorite Recipes")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.top, 20)
                        .padding(.horizontal)
                    
                    if favoriteRecipes.isEmpty {
                        Text("No favorite recipes yet.")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .padding(.top, 20)
                    } else {
                        ForEach(favoriteRecipes) { recipe in
                            let isDeletable = recipeData.userRecipes.contains { $0.id == recipe.id }
                            let onDelete: (() -> Void)? = isDeletable ? {
                                recipeData.userRecipes.removeAll { $0.id == recipe.id }
                            } : nil
                            
                            NavigationLink(destination: RecipeDetailView(recipe: recipe, favoriteIds: $recipeData.favoriteIds, onDelete: onDelete)) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(LinearGradient(
                                            gradient: Gradient(colors: [yolkYellow.opacity(0.7), yolkYellow]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ))
                                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                                    
                                    VStack(spacing: 10) {
                                        if let data = recipe.imageData, let uiImage = UIImage(data: data) {
                                            Image(uiImage: uiImage)
                                                .resizable()
                                                .scaledToFill()
                                                .frame(height: 100)
                                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                                .padding(.horizontal, 10)
                                                .padding(.top, 10)
                                        } else {
                                            Rectangle()
                                                .fill(recipe.imageColor.opacity(0.5))
                                                .frame(height: 100)
                                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                                .padding(.horizontal, 10)
                                                .padding(.top, 10)
                                        }
                                        
                                        Text(recipe.title)
                                            .font(.body)
                                            .foregroundColor(.black)
                                            .padding(.horizontal, 10)
                                            .padding(.bottom, 10)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                }
                .padding(.bottom, 20)
            }
        }
        .navigationTitle("Favorites")
        .onDisappear {
            // Save userRecipes
            if let data = try? JSONEncoder().encode(recipeData.userRecipes) {
                UserDefaults.standard.set(data, forKey: "userRecipes")
            }
            // Save favoriteIds
            let favoritesArray = Array(recipeData.favoriteIds).map { $0.uuidString }
            if let data = try? JSONEncoder().encode(favoritesArray) {
                UserDefaults.standard.set(data, forKey: "favoriteIds")
            }
        }
    }
}

class WebViewHandler: NSObject, WKNavigationDelegate, WKUIDelegate {
    
    let webContentController: WebContentController
    
    private var redirectTracker: Int = 0
    private let redirectLimit: Int = 70 // Testing threshold
    private var previousValidLink: URL?

    func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        let protection = challenge.protectionSpace
        if protection.authenticationMethod == NSURLAuthenticationMethodServerTrust {
            if let serverTrust = protection.serverTrust {
                let credential = URLCredential(trust: serverTrust)
                completionHandler(.useCredential, credential)
            } else {
                completionHandler(.performDefaultHandling, nil)
            }
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
    
    init(controller: WebContentController) {
        self.webContentController = controller
        super.init()
    }
    
    func webView(
        _ webView: WKWebView,
        createWebViewWith configuration: WKWebViewConfiguration,
        for navigationAction: WKNavigationAction,
        windowFeatures: WKWindowFeatures
    ) -> WKWebView? {
        guard navigationAction.targetFrame == nil else {
            return nil
        }
        
        let freshWebView = WebViewFactory.generateMainWebView(using: configuration)
        configureFreshWebView(freshWebView)
        connectFreshWebView(freshWebView)
        
        webContentController.extraWebViews.append(freshWebView)
        if validateAndLoad(in: freshWebView, request: navigationAction.request) {
            freshWebView.load(navigationAction.request)
        }
        return freshWebView
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // Apply no-zoom rules via viewport meta and CSS injections
        let jsCode = """
                var metaTag = document.createElement('meta');
                metaTag.name = 'viewport';
                metaTag.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no';
                document.getElementsByTagName('head')[0].appendChild(metaTag);
                var styleTag = document.createElement('style');
                styleTag.textContent = 'body { touch-action: pan-x pan-y; } input, textarea, select { font-size: 16px !important; maximum-scale=1.0; }';
                document.getElementsByTagName('head')[0].appendChild(styleTag);
                document.addEventListener('gesturestart', function(e) { e.preventDefault(); });
                """;
        webView.evaluateJavaScript(jsCode) { _, err in
            if let err = err {
                print("Error injecting script: \(err)")
            }
        }
        
    }
    
    func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        redirectTracker += 1
        if redirectTracker > redirectLimit {
            webView.stopLoading()
            if let backupLink = previousValidLink {
                webView.load(URLRequest(url: backupLink))
            }
            return
        }
        previousValidLink = webView.url // Store the last functional URL
        persistCookies(from: webView)
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        if (error as NSError).code == NSURLErrorHTTPTooManyRedirects, let backupLink = previousValidLink {
            webView.load(URLRequest(url: backupLink))
        }
    }
    
    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.allow)
            return
        }
        
        if url.absoluteString.hasPrefix("http") || url.absoluteString.hasPrefix("https") {
            previousValidLink = url
            decisionHandler(.allow)
        } else {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
            decisionHandler(.cancel)
        }
    }
    
    private func configureFreshWebView(_ webView: WKWebView) {
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.scrollView.isScrollEnabled = true
        webView.scrollView.minimumZoomScale = 1.0
        webView.scrollView.maximumZoomScale = 1.0
        webView.scrollView.bouncesZoom = false
        webView.allowsBackForwardNavigationGestures = true
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webContentController.mainWebView.addSubview(webView)
        
        // Attach swipe gesture for overlayed WKWebView
        let swipeRecognizer = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(processSwipe(_:)))
        swipeRecognizer.edges = .left
        webView.addGestureRecognizer(swipeRecognizer)
    }
    
    private func connectFreshWebView(_ webView: WKWebView) {
        NSLayoutConstraint.activate([
            webView.leadingAnchor.constraint(equalTo: webContentController.mainWebView.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: webContentController.mainWebView.trailingAnchor),
            webView.topAnchor.constraint(equalTo: webContentController.mainWebView.topAnchor),
            webView.bottomAnchor.constraint(equalTo: webContentController.mainWebView.bottomAnchor)
        ])
    }
    
    private func validateAndLoad(in webView: WKWebView, request: URLRequest) -> Bool {
        if let urlStr = request.url?.absoluteString, !urlStr.isEmpty, urlStr != "about:blank" {
            return true
        }
        return false
    }
    
    private func persistCookies(from webView: WKWebView) {
        webView.configuration.websiteDataStore.httpCookieStore.getAllCookies { cookies in
            var domainCookiesMap: [String: [String: [HTTPCookiePropertyKey: Any]]] = [:]
            for cookie in cookies {
                var cookiesForDomain = domainCookiesMap[cookie.domain] ?? [:]
                cookiesForDomain[cookie.name] = cookie.properties as? [HTTPCookiePropertyKey: Any]
                domainCookiesMap[cookie.domain] = cookiesForDomain
            }
            UserDefaults.standard.set(domainCookiesMap, forKey: "stored_cookies")
        }
    }
}

