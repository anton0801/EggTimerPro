
import SwiftUI
import Combine // Added import for ObservableObject and @Published

class RecipeData: ObservableObject {
    @Published var userRecipes: [Recipe] = []
    @Published var favoriteIds: Set<UUID> = []
    
    // Fixed UUIDs for initial recipes
    private let eggBenedictId = UUID(uuidString: "550e8400-e29b-41d4-a716-446655440000")!
    private let eggCustardId = UUID(uuidString: "6ba7b810-9dad-11d1-80b4-00c04fd430c8")!
    private let scrambledEggsId = UUID(uuidString: "123e4567-e89b-12d3-a456-426614174000")!
    private let omeletteId = UUID(uuidString: "987fcdeb-1234-5678-9abc-def012345678")!
    
    // Initial sample recipes with fixed IDs
    let initialRecipes: [Recipe] = [
        Recipe(
            id: UUID(uuidString: "550e8400-e29b-41d4-a716-446655440000")!,
            category: "Breakfasts",
            title: "Egg Benedict",
            ingredients: ["2 eggs", "2 English muffins", "4 slices Canadian bacon", "Hollandaise sauce", "Salt and pepper"],
            steps: ["Poach the eggs in simmering water.", "Toast the English muffins.", "Cook the Canadian bacon.", "Assemble by placing bacon on muffins, top with poached eggs and hollandaise sauce."],
            imageData: UIImage(named: "eggbenedict")?.jpegData(compressionQuality: 1.0),
            imageColor: .yellow
        ),
        Recipe(
            id: UUID(uuidString: "6ba7b810-9dad-11d1-80b4-00c04fd430c8")!,
            category: "Desserts",
            title: "Egg Custard",
            ingredients: ["2 eggs", "2 cups milk", "1/2 cup sugar", "1 tsp vanilla extract"],
            steps: ["Preheat oven to 350°F.", "Mix eggs, milk, sugar, and vanilla.", "Pour into baking dish.", "Bake for 30-40 minutes until set."],
            imageData: UIImage(named: "eggcustard")?.jpegData(compressionQuality: 1.0),
            imageColor: .blue
        ),
        Recipe(
            id: UUID(uuidString: "123e4567-e89b-12d3-a456-426614174000")!,
            category: "Quick Meals",
            title: "Scrambled Eggs",
            ingredients: ["3 eggs", "2 tbsp milk", "Salt and pepper", "1 tbsp butter"],
            steps: ["Beat eggs with milk, salt and pepper.", "Melt butter in pan over medium heat.", "Pour in egg mixture and stir until cooked."],
            imageData: UIImage(named: "scrambledeggs")?.jpegData(compressionQuality: 1.0),
            imageColor: .green
        ),
        Recipe(
            id: UUID(uuidString: "987fcdeb-1234-5678-9abc-def012345678")!,
            category: "Lunches and Dinners",
            title: "Omelette with Veggies",
            ingredients: ["2 eggs", "1/4 cup chopped bell peppers", "1/4 cup chopped onions", "1/4 cup cheese", "Salt and pepper"],
            steps: ["Beat eggs with salt and pepper.", "Sauté veggies in pan.", "Pour eggs over veggies, cook until set, add cheese, fold and serve."],
            imageData: UIImage(named: "omelettevegies")?.jpegData(compressionQuality: 1.0),
            imageColor: .red
        )
    ]
    
    init() {
        // Load userRecipes
        if let data = UserDefaults.standard.data(forKey: "userRecipes"),
           let decoded = try? JSONDecoder().decode([Recipe].self, from: data) {
            userRecipes = decoded
        }
        // Load favoriteIds
        if let favoritesData = UserDefaults.standard.data(forKey: "favoriteIds"),
           let favorites = try? JSONDecoder().decode([String].self, from: favoritesData) {
            favoriteIds = Set(favorites.compactMap { UUID(uuidString: $0) })
        }
    }
    
    var allRecipes: [Recipe] {
        initialRecipes + userRecipes
    }
}
