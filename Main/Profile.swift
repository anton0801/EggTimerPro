
import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var recipeData: RecipeData // Required for TabViewScreen
    @EnvironmentObject var timerState: TimerState // Required for TabViewScreen
    @AppStorage("notificationsEnabled") private var notificationsEnabled: Bool = true
    @AppStorage("selectedLanguage") private var selectedLanguage: String = "English"
    @AppStorage("eggCount") private var eggCount: Int = 0
    
    // Color scheme
    let yolkYellow = Color(hex: "#FFD93D")
    let creamyWhite = Color(hex: "#FFF9E6")
    let skyBlue = Color(hex: "#4A90E2")
    
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
                    // Title
                    HStack {
                        Text("Profile")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                        Spacer()
                    }
                    .padding(.top, 20)
                    .padding(.horizontal)
                    
                    // Avatar Card
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white)
                            .shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 5)
                        
                        Circle()
                            .fill(yolkYellow.opacity(0.5))
                            .frame(width: 100, height: 100)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 60, height: 60)
                                    .foregroundColor(.black)
                            )
                            .padding(.vertical, 15)
                    }
                    .padding(.horizontal)
                    
                    // Achievements Card
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white)
                            .shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 5)
                        
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Achievements")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.black)
                            
                            VStack(spacing: 5) {
                                HStack {
                                    Text("Master Poached")
                                        .foregroundColor(.black)
                                    Spacer()
                                    Text("\(min(eggCount, 100))/100 Eggs")
                                        .foregroundColor(.black)
                                }
                                
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(height: 20)
                                    
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.black)
                                        .frame(width: CGFloat(min(eggCount, 100)) / 100 * 200, height: 20)
                                }
                            }
                        }
                        .padding(.vertical, 15)
                        .padding(.horizontal)
                    }
                    .padding(.horizontal)
                    
                    // Sticker Collection Card
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white)
                            .shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 5)
                        
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Stickers")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.black)
                            
                            HStack(spacing: 10) {
                                Circle()
                                    .fill(yolkYellow.opacity(0.5))
                                    .frame(width: 50, height: 50)
                                    .overlay(
                                        Text("🥚")
                                            .font(.title2)
                                            .foregroundColor(.black)
                                    )
                                
                                Circle()
                                    .fill(yolkYellow.opacity(0.5))
                                    .frame(width: 50, height: 50)
                                    .overlay(
                                        Text("🍳")
                                            .font(.title2)
                                            .foregroundColor(.black)
                                    )
                                
                                Circle()
                                    .fill(yolkYellow.opacity(0.5))
                                    .frame(width: 50, height: 50)
                                    .overlay(
                                        Text("🐔")
                                            .font(.title2)
                                            .foregroundColor(.black)
                                    )
                            }
                        }
                        .padding(.vertical, 15)
                        .padding(.horizontal)
                    }
                    .padding(.horizontal)
                    
                    // Settings Card
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white)
                            .shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 5)
                        
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Settings")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.black)
                            
                            HStack {
                                Text("Language")
                                    .font(.subheadline)
                                    .foregroundColor(.black)
                                Spacer()
                                Picker("Language", selection: $selectedLanguage) {
                                    Text("English").tag("English")
                                    Text("Russian").tag("Russian")
                                }
                                .pickerStyle(.menu)
                                .labelsHidden()
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .background(skyBlue.opacity(0.2))
                                .cornerRadius(10)
                                .shadow(color: .gray.opacity(0.2), radius: 3, x: 0, y: 3)
                            }
                            
                            HStack {
                                Text("Notifications")
                                    .font(.subheadline)
                                    .foregroundColor(.black)
                                Spacer()
                                Toggle("", isOn: $notificationsEnabled)
                                    .labelsHidden()
                                    .tint(yolkYellow)
                            }
                        }
                        .padding(.vertical, 15)
                        .padding(.horizontal)
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 20)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            // Sync eggCount with timerState if needed
            timerState.eggCount = eggCount
        }
        .onChange(of: timerState.eggCount) { newValue in
            eggCount = newValue
        }
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ProfileView()
                .environmentObject(RecipeData())
                .environmentObject(TimerState(onTimerFinish: {}))
        }
    }
}
