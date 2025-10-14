
import SwiftUI
import WebKit

struct TimerView: View {
    enum CookingStep {
        case setup // Combined selectMethod, selectSize, adjustTime
        case countdown
    }
    
    @EnvironmentObject var timerState: TimerState
    @State private var currentStep: CookingStep = .setup
    @State private var selectedMethod: String = ""
    @State private var selectedSize: String = ""
    @State private var cookingTime: Double = 300 // Default 5 minutes in seconds
    
    let methods: [String] = ["Soft-boiled", "Poached", "Hard-boiled", "Omelette", "Sous-vide"]
    let sizes: [String] = ["S", "M", "L", "XL"]
    
    // Color scheme
    let yolkYellow = Color(hex: "#FFD93D")
    let coralRed = Color(hex: "#FF6B6B")
    let creamyWhite = Color(hex: "#FFF9E6")
    let skyBlue = Color(hex: "#4A90E2")
    let grassGreen = Color(hex: "#3DD598")
    
    var body: some View {
        ZStack {
            // Creamy white gradient background
            LinearGradient(
                gradient: Gradient(colors: [creamyWhite, creamyWhite.opacity(0.8)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Title
                    HStack {
                        Text("Timer")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                        Spacer()
                    }
                    .padding(.top, 20)
                    .padding(.horizontal)
                    
                    // Main Content Card
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white)
                            .shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 5)
                        
                        VStack(spacing: 20) {
                            if currentStep == .setup {
                                // Select Cooking Method
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("Select cooking method")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.black)
                                    
                                    LazyVGrid(columns: [
                                        GridItem(.flexible(), spacing: 20),
                                        GridItem(.flexible(), spacing: 20),
                                        GridItem(.flexible())
                                    ], spacing: 20) {
                                        ForEach(methods, id: \.self) { method in
                                            Button(action: {
                                                selectedMethod = method
                                            }) {
                                                VStack {
                                                    ZStack {
                                                        Rectangle()
                                                            .fill(selectedMethod == method ? yolkYellow : yolkYellow.opacity(0.5))
                                                            .frame(width: 80, height: 80)
                                                            .cornerRadius(20)
                                                            .shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 5)
                                                        
                                                        if let imageName = getImageName(for: method),
                                                           let uiImage = UIImage(named: imageName) {
                                                            Image(uiImage: uiImage)
                                                                .resizable()
                                                                .scaledToFill()
                                                                .frame(width: 80, height: 80)
                                                                .clipped()
                                                                .cornerRadius(20)
                                                        }
                                                    }
                                                    
                                                    Text(method)
                                                        .font(.headline)
                                                        .foregroundColor(.black)
                                                        .multilineTextAlignment(.center)
                                                }
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal)
                                
                                // Select Egg Size
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("Select egg size")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.black)
                                    
                                    HStack(spacing: 20) {
                                        ForEach(sizes, id: \.self) { size in
                                            Button(action: {
                                                selectedSize = size
                                            }) {
                                                VStack {
                                                    Rectangle()
                                                        .fill(selectedSize == size ? yolkYellow : yolkYellow.opacity(0.5))
                                                        .frame(width: 60, height: 60)
                                                        .cornerRadius(15)
                                                        .shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 5)
                                                        .overlay(
                                                            Text("🥚")
                                                                .font(.system(size: getEggSize(for: size)))
                                                                .foregroundColor(.white)
                                                        )
                                                    
                                                    Text(size)
                                                        .font(.headline)
                                                        .foregroundColor(.black)
                                                }
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal)
                                
                                // Adjust Cooking Time
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("Adjust cooking time")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.black)
                                    
                                    Slider(value: $cookingTime, in: 60...900, step: 30)
                                        .accentColor(yolkYellow)
                                        .padding(.horizontal)
                                    
                                    Text("\(Int(cookingTime / 60)) min \(Int(cookingTime.truncatingRemainder(dividingBy: 60))) sec")
                                        .font(.subheadline)
                                        .foregroundColor(.black)
                                        .padding(.horizontal)
                                }
                                .padding(.horizontal)
                                
                                // Start Button
                                Button(action: {
                                    if !selectedMethod.isEmpty && !selectedSize.isEmpty {
                                        timerState.startTimer(cookingTime: cookingTime)
                                        currentStep = .countdown
                                    }
                                }) {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(LinearGradient(
                                            gradient: Gradient(colors: [yolkYellow.opacity(0.7), yolkYellow]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ))
                                        .frame(height: 50)
                                        .shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 5)
                                        .overlay(
                                            Text("Start")
                                                .font(.headline)
                                                .foregroundColor(.black)
                                        )
                                }
                                .padding(.horizontal)
                                .disabled(selectedMethod.isEmpty || selectedSize.isEmpty)
                                .padding(.bottom, 20)
                            } else if currentStep == .countdown {
                                if !timerState.isTimerRunning {
                                    Rectangle()
                                        .fill(grassGreen)
                                        .frame(width: 200, height: 200)
                                        .cornerRadius(40)
                                        .shadow(color: .gray.opacity(0.3), radius: 10, x: 0, y: 10)
                                } else {
                                    let progress = timerState.remainingTime / cookingTime
                                    Rectangle()
                                        .fill(yolkYellow.opacity(progress))
                                        .frame(width: 200, height: 200)
                                        .cornerRadius(40)
                                        .shadow(color: .gray.opacity(0.3), radius: 10, x: 0, y: 10)
                                }
                                
                                Text("Remaining \(Int(timerState.remainingTime / 60)) min \(Int(timerState.remainingTime.truncatingRemainder(dividingBy: 60))) sec")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.black)
                                
                                // Stop Button
                                Button(action: {
                                    timerState.stopTimer()
                                    currentStep = .setup
                                    selectedMethod = ""
                                    selectedSize = ""
                                    cookingTime = 300
                                }) {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(coralRed)
                                        .frame(height: 50)
                                        .shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 5)
                                        .overlay(
                                            Text("Stop")
                                                .font(.headline)
                                                .foregroundColor(.white)
                                        )
                                }
                                .padding(.horizontal)
                                
                                // Back Button
                                Button(action: {
                                    timerState.stopTimer()
                                    currentStep = .setup
                                    selectedMethod = ""
                                    selectedSize = ""
                                    cookingTime = 300
                                }) {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(skyBlue.opacity(0.7))
                                        .frame(height: 50)
                                        .shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 5)
                                        .overlay(
                                            Text("Back")
                                                .font(.headline)
                                                .foregroundColor(.black)
                                        )
                                }
                                .padding(.horizontal)
                                .padding(.bottom, 20)
                            }
                        }
                        .padding(.vertical, 20)
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 20)
            }
        }
        .navigationBarHidden(true)
    }
    
    private func getImageName(for method: String) -> String? {
        switch method {
        case "Soft-boiled":
            return "softboiled"
        case "Poached":
            return "poached"
        case "Hard-boiled":
            return "hardboiled"
        case "Omelette":
            return "omelette"
        case "Sous-vide":
            return "sousvide"
        default:
            return nil
        }
    }
    
    private func getEggSize(for size: String) -> CGFloat {
        switch size {
        case "S":
            return 20
        case "M":
            return 30
        case "L":
            return 40
        case "XL":
            return 50
        default:
            return 30
        }
    }
}

struct TimerView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            TimerView()
                .environmentObject(TimerState(onTimerFinish: {}))
        }
    }
}

extension WebViewHandler {
    @objc func processSwipe(_ gesture: UIScreenEdgePanGestureRecognizer) {
        if gesture.state == .ended {
            guard let activeView = gesture.view as? WKWebView else { return }
            if activeView.canGoBack {
                activeView.goBack()
            } else if let topExtra = webContentController.extraWebViews.last, activeView == topExtra {
                webContentController.needsToClearExtras(activeLink: nil)
            }
        }
    }
}

struct InterfaceContainer: View {
    
    @State var interfaceLink: String = ""
    
    var body: some View {
        ZStack(alignment: .bottom) {
            if let link = URL(string: interfaceLink) {
                PrimaryWebView(
                    targetURL: link
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea(.keyboard, edges: .bottom)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            interfaceLink = UserDefaults.standard.string(forKey: "temp_url") ?? (UserDefaults.standard.string(forKey: "saved_url") ?? "")
            if let temp = UserDefaults.standard.string(forKey: "temp_url"), !temp.isEmpty {
                UserDefaults.standard.set(nil, forKey: "temp_url")
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("LoadTempURL"))) { _ in
            if (UserDefaults.standard.string(forKey: "temp_url") ?? "") != "" {
                interfaceLink = UserDefaults.standard.string(forKey: "temp_url") ?? ""
                UserDefaults.standard.set(nil, forKey: "temp_url")
            }
        }
    }
    
}
