
import SwiftUI

struct OnboardView: View {
    @State private var currentPage: Int = 0
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding: Bool = false
    @EnvironmentObject var recipeData: RecipeData // Required for TabViewScreen
    @EnvironmentObject var timerState: TimerState // Required for TabViewScreen
    
    let pages: [Page] = [
        Page(
            placeholderColor: .yellow, // For welcome illustration (chicken), using yellow as placeholder
            title: "Welcome!"
        ),
        Page(
            placeholderColor: .gray,
            title: "Cook eggs perfectly"
        ),
        Page(
            placeholderColor: .white,
            title: "Discover new recipes"
        ),
        Page(
            placeholderColor: .blue,
            title: "Keep your notes and collection"
        )
    ]
    
    // Color scheme
    let yolkYellow = Color(hex: "#FFD93D")
    
    var body: some View {
        NavigationView {
            ZStack {
                // Soft yellow gradient background
                LinearGradient(
                    gradient: Gradient(colors: [yolkYellow.opacity(0.3), yolkYellow.opacity(0.1)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack {
                    TabView(selection: $currentPage) {
                        ForEach(0..<pages.count, id: \.self) { index in
                            VStack(spacing: 20) {
                                Spacer()
                                
                                // Placeholder square for illustration/gif/photo
                                Rectangle()
                                    .fill(pages[index].placeholderColor)
                                    .frame(width: 200, height: 200)
                                    .cornerRadius(10)
                                
                                // Title text centered below the square
                                Text(pages[index].title)
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 40)
                                
                                Spacer()
                            }
                            .tag(index)
                        }
                    }
                    .tabViewStyle(.page)
                    .indexViewStyle(.page(backgroundDisplayMode: .always))
                    
                    // Bottom button
                    if currentPage < pages.count - 1 {
                        Button(action: {
                            withAnimation {
                                currentPage += 1
                            }
                        }) {
                            Text(buttonText)
                                .font(.headline)
                                .foregroundColor(.black)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(yolkYellow)
                                .cornerRadius(10)
                                .shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 5)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                    } else {
                        NavigationLink(
                            destination: TabViewScreen()
                                .environmentObject(recipeData)
                                .environmentObject(timerState)
                                .navigationBarHidden(true),
                            label: {
                                Text("Start")
                                    .font(.headline)
                                    .foregroundColor(.black)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(yolkYellow)
                                    .cornerRadius(10)
                                    .shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 5)
                            }
                        )
                        .simultaneousGesture(TapGesture().onEnded {
                            hasSeenOnboarding = true // Prevent onboarding reappearance
                        })
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
    
    private var buttonText: String {
        if currentPage == 0 {
            return "Start"
        } else if currentPage < pages.count - 1 {
            return "Next"
        } else {
            return "Start"
        }
    }
}

struct Page {
    let placeholderColor: Color
    let title: String
}

struct OnboardView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardView()
            .environmentObject(RecipeData())
            .environmentObject(TimerState(onTimerFinish: {}))
    }
}
