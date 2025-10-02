
import SwiftUI

struct HomeView: View {
    @EnvironmentObject var recipeData: RecipeData
    @EnvironmentObject var timerState: TimerState
    @State private var recipeOfTheDay: Recipe? // Stores the recipe of the day
    @AppStorage("recipeOfTheDayId") private var recipeOfTheDayId: String = ""
    @State private var lastRecipeUpdateDate: Date = Date()
    @State private var lastResetDate: Date = Date()
    let yolkYellow = Color(hex: "#FFD93D")
    let creamyWhite = Color(hex: "#FFF9E6")
    
    // Check if a week has passed since last reset for egg count
    private func resetEggCountIfNeeded() {
        let calendar = Calendar.current
        let now = Date()
        if let daysSinceLastReset = calendar.dateComponents([.day], from: lastResetDate, to: now).day, daysSinceLastReset >= 7 {
            timerState.eggCount = 0
            lastResetDate = now
            UserDefaults.standard.set(lastResetDate, forKey: "lastResetDate")
        }
    }
    
    // Check if a day has passed since last recipe update
    private func updateRecipeOfTheDayIfNeeded() {
        let calendar = Calendar.current
        let now = Date()
        if let daysSinceLastUpdate = calendar.dateComponents([.day], from: lastRecipeUpdateDate, to: now).day, daysSinceLastUpdate >= 1 {
            recipeOfTheDay = recipeData.allRecipes.randomElement()
            recipeOfTheDayId = recipeOfTheDay?.id.uuidString ?? ""
            lastRecipeUpdateDate = now
            UserDefaults.standard.set(lastRecipeUpdateDate, forKey: "lastRecipeUpdateDate")
        } else if recipeOfTheDay == nil {
            // Initial selection if none exists
            recipeOfTheDay = recipeData.allRecipes.randomElement()
            recipeOfTheDayId = recipeOfTheDay?.id.uuidString ?? ""
            lastRecipeUpdateDate = now
            UserDefaults.standard.set(lastRecipeUpdateDate, forKey: "lastRecipeUpdateDate")
        }
    }
    
    var body: some View {
        NavigationView {
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
                        // Greeting with emoji on the left
                        HStack {
                            Text("🐔")
                                .font(.largeTitle)
                            Text("Welcome!")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.black)
                            Spacer()
                        }
                        .padding(.top, 20)
                        .padding(.horizontal)
                        
                        // Quick Timer Button
                        NavigationLink(destination: TimerView()) {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(LinearGradient(
                                    gradient: Gradient(colors: [yolkYellow.opacity(0.7), yolkYellow]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .frame(height: 60)
                                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                                .overlay(
                                    Text("🕑 Quick Timer")
                                        .font(.headline)
                                        .foregroundColor(.black)
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.horizontal)
                        
                        // Recipe of the Day Card
                        if let recipe = recipeOfTheDay {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white)
                                    .shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 5)
                                
                                NavigationLink(destination: RecipesView()) {
                                    VStack(spacing: 10) {
                                        Text("Recipe of the Day")
                                            .font(.title2)
                                            .fontWeight(.bold)
                                            .foregroundColor(.black)
                                            .padding(.top, 10)
                                        
                                        if let data = recipe.imageData, let uiImage = UIImage(data: data) {
                                            Image(uiImage: uiImage)
                                                .resizable()
                                                .scaledToFill()
                                                .frame(height: 150)
                                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                                .padding(.horizontal, 10)
                                        } else {
                                            Rectangle()
                                                .fill(recipe.imageColor.opacity(0.5))
                                                .frame(height: 150)
                                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                                .padding(.horizontal, 10)
                                        }
                                        
                                        Text(recipe.title)
                                            .font(.headline)
                                            .foregroundColor(.black)
                                            .padding(.horizontal, 10)
                                        
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(yolkYellow.opacity(0.7))
                                            .frame(height: 40)
                                            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                                            .overlay(
                                                Text("View")
                                                    .font(.headline)
                                                    .foregroundColor(.black)
                                            )
                                            .padding(.horizontal, 10)
                                            .padding(.bottom, 10)
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            .padding(.horizontal)
                        }
                        
                        // Statistics Card
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white)
                                .shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 5)
                            
                            VStack(spacing: 10) {
                                Text("Statistics")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.black)
                                    .padding(.top, 10)
                                
                                HStack {
                                    Image(systemName: "basket.fill")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 40, height: 40)
                                        .foregroundColor(yolkYellow)
                                    
                                    Text("You cooked ")
                                        .font(.body)
                                        .foregroundColor(.black)
                                    
                                    Text("\(timerState.eggCount)")
                                        .font(.body)
                                        .fontWeight(.bold)
                                        .foregroundColor(yolkYellow)
                                        .padding(.horizontal, 2)
                                    
                                    Text("eggs this week")
                                        .font(.body)
                                        .foregroundColor(.black)
                                }
                                .padding(.horizontal, 10)
                                .padding(.bottom, 10)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Timer Card (shown when timer is running)
                        if timerState.isTimerRunning {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(LinearGradient(
                                        gradient: Gradient(colors: [yolkYellow.opacity(0.7), yolkYellow]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ))
                                    .shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 5)
                                
                                HStack {
                                    Text("🥚")
                                        .font(.title2)
                                        .foregroundColor(.black)
                                    
                                    Text("Remaining \(Int(timerState.remainingTime / 60)) min \(Int(timerState.remainingTime.truncatingRemainder(dividingBy: 60))) sec")
                                        .font(.title2)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.black)
                                }
                                .padding(.vertical, 15)
                                .padding(.horizontal, 10)
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.bottom, 20)
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                // Load dates from UserDefaults
                lastRecipeUpdateDate = UserDefaults.standard.object(forKey: "lastRecipeUpdateDate") as? Date ?? Date()
                lastResetDate = UserDefaults.standard.object(forKey: "lastResetDate") as? Date ?? Date()
                
                resetEggCountIfNeeded()
                updateRecipeOfTheDayIfNeeded()
                // Load recipeOfTheDay from saved ID
                let idString = recipeOfTheDayId
                if let id = UUID(uuidString: idString),
                   let savedRecipe = recipeData.allRecipes.first(where: { $0.id == id }) {
                    recipeOfTheDay = savedRecipe
                }
            }
            .onDisappear {
                // Save dates to UserDefaults
                UserDefaults.standard.set(lastRecipeUpdateDate, forKey: "lastRecipeUpdateDate")
                UserDefaults.standard.set(lastResetDate, forKey: "lastResetDate")
            }
            .onChange(of: timerState.eggCount) { _ in
                // Save eggCount changes
                UserDefaults.standard.set(timerState.eggCount, forKey: "eggCount")
            }
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .environmentObject(RecipeData())
            .environmentObject(TimerState(onTimerFinish: {}))
    }
}
