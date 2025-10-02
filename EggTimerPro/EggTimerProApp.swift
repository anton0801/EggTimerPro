
import SwiftUI

@main
struct MyApp: App {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding: Bool = false
    @StateObject private var recipeData = RecipeData()
    @StateObject private var timerState = TimerState(onTimerFinish: {})
    
    var body: some Scene {
        WindowGroup {
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
