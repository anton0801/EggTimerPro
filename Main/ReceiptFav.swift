
import SwiftUI

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
