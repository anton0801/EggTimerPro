
import SwiftUI
import PhotosUI

struct Recipe: Identifiable, Codable {
    var id: UUID
    let category: String
    let title: String
    let ingredients: [String]
    let steps: [String]
    let imageData: Data?
    let imageColorHex: String
    
    var imageColor: Color {
        Color(hex: imageColorHex)
    }
    
    enum CodingKeys: String, CodingKey {
        case id, category, title, ingredients, steps, imageData, imageColorHex
    }
    
    init(id: UUID = UUID(), category: String, title: String, ingredients: [String], steps: [String], imageData: Data? = nil, imageColor: Color) {
        self.id = id
        self.category = category
        self.title = title
        self.ingredients = ingredients
        self.steps = steps
        self.imageData = imageData
        self.imageColorHex = imageColor.toHex() ?? "#FFD93D"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        category = try container.decode(String.self, forKey: .category)
        title = try container.decode(String.self, forKey: .title)
        ingredients = try container.decode([String].self, forKey: .ingredients)
        steps = try container.decode([String].self, forKey: .steps)
        imageData = try container.decodeIfPresent(Data.self, forKey: .imageData)
        imageColorHex = try container.decode(String.self, forKey: .imageColorHex)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(category, forKey: .category)
        try container.encode(title, forKey: .title)
        try container.encode(ingredients, forKey: .ingredients)
        try container.encode(steps, forKey: .steps)
        try container.encodeIfPresent(imageData, forKey: .imageData)
        try container.encode(imageColorHex, forKey: .imageColorHex)
    }
}

extension Color {
    func toHex() -> String? {
        let uic = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        if uic.getRed(&r, green: &g, blue: &b, alpha: &a) {
            let rgb: Int = (Int)(r*255)<<16 | (Int)(g*255)<<8 | (Int)(b*255)<<0
            return String(format: "#%06x", rgb)
        }
        return nil
    }
    
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

struct RecipesView: View {
    @EnvironmentObject var recipeData: RecipeData // Shared recipe data
    @EnvironmentObject var timerState: TimerState // Required for TabViewScreen
    @State private var searchText: String = ""
    @State private var selectedCategory: String = "All"
    @State private var showingCreateRecipe: Bool = false
    
    // Color scheme
    let yolkYellow = Color(hex: "#FFD93D")
    let coralRed = Color(hex: "#FF6B6B")
    let creamyWhite = Color(hex: "#FFF9E6")
    let skyBlue = Color(hex: "#4A90E2")
    let grassGreen = Color(hex: "#3DD598")
    
    let placeholderColors: [Color] = [.yellow, .blue, .green, .red, .purple, .orange]
    
    // Dynamic categories including user-created and Favorites
    var categories: [String] {
        var uniqueCategories = Set(recipeData.allRecipes.map { $0.category })
        uniqueCategories.insert("All")
        uniqueCategories.insert("Favorites")
        return Array(uniqueCategories).sorted()
    }
    
    var filteredRecipes: [Recipe] {
        let searched = recipeData.allRecipes.filter { recipe in
            searchText.isEmpty || recipe.title.lowercased().contains(searchText.lowercased())
        }
        
        if selectedCategory == "All" {
            return searched
        } else if selectedCategory == "Favorites" {
            return searched.filter { recipeData.favoriteIds.contains($0.id) }
        } else {
            return searched.filter { $0.category == selectedCategory }
        }
    }
    
    var body: some View {
        NavigationView {
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
                            Text("Recipes")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.black)
                            Spacer()
                        }
                        .padding(.top, 20)
                        .padding(.horizontal)
                        
                        // Search and Filters Card
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white)
                                .shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 5)
                            
                            HStack(spacing: 10) {
                                TextField("Search recipes...", text: $searchText)
                                    .padding()
                                    .background(Color.white.opacity(0.8))
                                    .cornerRadius(10)
                                    .shadow(color: .gray.opacity(0.2), radius: 3, x: 0, y: 3)
                                
                                Picker("Category", selection: $selectedCategory) {
                                    ForEach(categories, id: \.self) { category in
                                        Text(category)
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                                .padding()
                                .background(skyBlue.opacity(0.2))
                                .cornerRadius(10)
                                .shadow(color: .gray.opacity(0.2), radius: 3, x: 0, y: 3)
                                .frame(maxWidth: 150)
                            }
                            .padding(.vertical, 15)
                            .padding(.horizontal)
                        }
                        .padding(.horizontal)
                        
                        // Create Recipe Button
                        Button(action: {
                            showingCreateRecipe = true
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
                                    Text("Create Your Own Recipe")
                                        .font(.headline)
                                        .foregroundColor(.black)
                                )
                        }
                        .padding(.horizontal)
                        .sheet(isPresented: $showingCreateRecipe) {
                            CreateRecipeView(userRecipes: $recipeData.userRecipes, placeholderColors: placeholderColors)
                        }
                        
                        // Recipes Grid Card
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white)
                                .shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 5)
                            
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                                ForEach(filteredRecipes) { recipe in
                                    let isDeletable = recipeData.userRecipes.contains { $0.id == recipe.id }
                                    let onDelete: (() -> Void)? = isDeletable ? {
                                        recipeData.userRecipes.removeAll { $0.id == recipe.id }
                                    } : nil
                                    
                                    NavigationLink(destination: RecipeDetailView(recipe: recipe, favoriteIds: $recipeData.favoriteIds, onDelete: onDelete)) {
                                        VStack {
                                            if let data = recipe.imageData, let uiImage = UIImage(data: data) {
                                                Image(uiImage: uiImage)
                                                    .resizable()
                                                    .scaledToFill()
                                                    .frame(width: 150, height: 150)
                                                    .clipped()
                                                    .cornerRadius(20)
                                                    .shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 5)
                                            } else {
                                                Rectangle()
                                                    .fill(recipe.imageColor.opacity(0.5))
                                                    .frame(width: 150, height: 150)
                                                    .cornerRadius(20)
                                                    .shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 5)
                                            }
                                            
                                            Text(recipe.title)
                                                .font(.headline)
                                                .foregroundColor(.black)
                                                .multilineTextAlignment(.center)
                                        }
                                        .padding()
                                        .background(Color.white.opacity(0.9))
                                        .cornerRadius(15)
                                        .shadow(color: .gray.opacity(0.2), radius: 3, x: 0, y: 3)
                                    }
                                }
                            }
                            .padding(.vertical, 15)
                        }
                        .padding(.horizontal)
                    }
                    .padding(.bottom, 20)
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                // Load userRecipes
                if let data = UserDefaults.standard.data(forKey: "userRecipes"),
                   let decoded = try? JSONDecoder().decode([Recipe].self, from: data) {
                    recipeData.userRecipes = decoded
                }
                // Load favoriteIds
                if let favoritesData = UserDefaults.standard.data(forKey: "favoriteIds"),
                   let favorites = try? JSONDecoder().decode([String].self, from: favoritesData) {
                    recipeData.favoriteIds = Set(favorites.compactMap { UUID(uuidString: $0) })
                }
            }
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
}

struct RecipeDetailView: View {
    let recipe: Recipe
    @Binding var favoriteIds: Set<UUID>
    let onDelete: (() -> Void)?
    @Environment(\.presentationMode) private var presentationMode // For iOS 15 compatibility
    
    private var isFavorite: Bool {
        favoriteIds.contains(recipe.id)
    }
    
    let yolkYellow = Color(hex: "#FFD93D")
    let coralRed = Color(hex: "#FF6B6B")
    let creamyWhite = Color(hex: "#FFF9E6")
    let skyBlue = Color(hex: "#4A90E2")
    let grassGreen = Color(hex: "#3DD598")
    
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
                    // Title and Back Button
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white)
                            .shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 5)
                        
                        HStack {
                            Button(action: {
                                presentationMode.wrappedValue.dismiss()
                            }) {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(skyBlue.opacity(0.7))
                                    .frame(width: 40, height: 40)
                                    .shadow(color: .gray.opacity(0.2), radius: 3, x: 0, y: 3)
                                    .overlay(
                                        Image(systemName: "chevron.left")
                                            .foregroundColor(.black)
                                    )
                            }
                            
                            Text(recipe.title)
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.black)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                            
                            Spacer()
                        }
                        .padding(.vertical, 15)
                        .padding(.horizontal)
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)
                    
                    // Image Card
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white)
                            .shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 5)
                        
                        if let data = recipe.imageData, let uiImage = UIImage(data: data) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 250, height: 250)
                                .clipped()
                                .cornerRadius(20)
                                .shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 5)
                                .padding(.vertical, 15)
                                .padding(.horizontal, 10)
                        } else {
                            Rectangle()
                                .fill(recipe.imageColor.opacity(0.5))
                                .frame(width: 250, height: 250)
                                .cornerRadius(20)
                                .shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 5)
                                .padding(.vertical, 15)
                                .padding(.horizontal, 10)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Ingredients Card
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white)
                            .shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 5)
                        
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Ingredients")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.black)
                            
                            ForEach(recipe.ingredients, id: \.self) { ingredient in
                                HStack {
                                    Rectangle()
                                        .fill(yolkYellow.opacity(0.5))
                                        .frame(width: 30, height: 30)
                                        .cornerRadius(8)
                                        .shadow(color: .gray.opacity(0.3), radius: 3, x: 0, y: 3)
                                    
                                    Text(ingredient)
                                        .foregroundColor(.black)
                                }
                                .padding(.vertical, 5)
                            }
                        }
                        .padding(.vertical, 15)
                        .padding(.horizontal)
                    }
                    .padding(.horizontal)
                    
                    // Steps Card
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white)
                            .shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 5)
                        
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Steps")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.black)
                            
                            ForEach(Array(recipe.steps.enumerated()), id: \.offset) { index, step in
                                HStack(alignment: .top) {
                                    Rectangle()
                                        .fill(grassGreen.opacity(0.5))
                                        .frame(width: 50, height: 50)
                                        .cornerRadius(10)
                                        .shadow(color: .gray.opacity(0.3), radius: 3, x: 0, y: 3)
                                    
                                    VStack(alignment: .leading) {
                                        Text("Step \(index + 1)")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                        Text(step)
                                            .foregroundColor(.black)
                                    }
                                }
                                .padding(.vertical, 10)
                            }
                        }
                        .padding(.vertical, 15)
                        .padding(.horizontal)
                    }
                    .padding(.horizontal)
                    
                    // Favorite Button
                    Button(action: {
                        if isFavorite {
                            favoriteIds.remove(recipe.id)
                        } else {
                            favoriteIds.insert(recipe.id)
                        }
                    }) {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(isFavorite ? grassGreen.opacity(0.7) : yolkYellow.opacity(0.7))
                            .frame(height: 50)
                            .shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 5)
                            .overlay(
                                HStack {
                                    Image(systemName: isFavorite ? "star.fill" : "star")
                                        .foregroundColor(isFavorite ? grassGreen : yolkYellow)
                                    Text(isFavorite ? "Remove from Favorites" : "Add to Favorites")
                                        .font(.headline)
                                        .foregroundColor(.black)
                                }
                            )
                    }
                    .padding(.horizontal)
                    
                    // Delete Button (if applicable)
                    if let onDelete = onDelete {
                        Button(action: onDelete) {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(coralRed)
                                .frame(height: 50)
                                .shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 5)
                                .overlay(
                                    Text("Delete Recipe")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                )
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.bottom, 20)
            }
        }
        .navigationBarHidden(true)
    }
}

struct CreateRecipeView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var userRecipes: [Recipe]
    
    let placeholderColors: [Color]
    
    @State private var title: String = ""
    @State private var category: String = ""
    @State private var ingredients: [String] = ["", "", ""]
    @State private var steps: [String] = ["", "", ""]
    @State private var selectedImageData: Data? = nil
    @State private var showingImagePicker: Bool = false
    @State private var showAlert: Bool = false
    
    let yolkYellow = Color(hex: "#FFD93D")
    let coralRed = Color(hex: "#FF6B6B")
    let creamyWhite = Color(hex: "#FFF9E6")
    let skyBlue = Color(hex: "#4A90E2")
    let grassGreen = Color(hex: "#3DD598")
    
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
                        Text("Create Recipe")
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
                            // Image Picker
                            Button(action: {
                                showingImagePicker = true
                            }) {
                                if let selectedImageData,
                                   let uiImage = UIImage(data: selectedImageData) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 250, height: 250)
                                        .clipped()
                                        .cornerRadius(20)
                                        .shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 5)
                                } else {
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.5))
                                        .frame(width: 250, height: 250)
                                        .cornerRadius(20)
                                        .shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 5)
                                        .overlay(
                                            Text("Tap to add image (optional)")
                                                .foregroundColor(.black)
                                                .font(.headline)
                                        )
                                }
                            }
                            .padding(.horizontal)
                            .sheet(isPresented: $showingImagePicker) {
                                ImagePicker(imageData: $selectedImageData)
                            }
                            
                            // Title and Category
                            TextField("Recipe Title", text: $title)
                                .padding()
                                .background(Color.white.opacity(0.8))
                                .cornerRadius(10)
                                .shadow(color: .gray.opacity(0.2), radius: 3, x: 0, y: 3)
                            
                            TextField("Category", text: $category)
                                .padding()
                                .background(Color.white.opacity(0.8))
                                .cornerRadius(10)
                                .shadow(color: .gray.opacity(0.2), radius: 3, x: 0, y: 3)
                            
                            // Ingredients
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Ingredients")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.black)
                                
                                ForEach(0..<ingredients.count, id: \.self) { index in
                                    TextField("Ingredient \(index + 1)", text: $ingredients[index])
                                        .padding()
                                        .background(Color.white.opacity(0.8))
                                        .cornerRadius(10)
                                        .shadow(color: .gray.opacity(0.2), radius: 3, x: 0, y: 3)
                                }
                                
                                Button(action: {
                                    ingredients.append("")
                                }) {
                                    Text("Add Ingredient")
                                        .font(.headline)
                                        .foregroundColor(.black)
                                        .padding()
                                        .frame(maxWidth: .infinity)
                                        .background(skyBlue.opacity(0.7))
                                        .cornerRadius(10)
                                        .shadow(color: .gray.opacity(0.2), radius: 3, x: 0, y: 3)
                                }
                            }
                            
                            // Steps
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Steps")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.black)
                                
                                ForEach(0..<steps.count, id: \.self) { index in
                                    TextField("Step \(index + 1)", text: $steps[index])
                                        .padding()
                                        .background(Color.white.opacity(0.8))
                                        .cornerRadius(10)
                                        .shadow(color: .gray.opacity(0.2), radius: 3, x: 0, y: 3)
                                }
                                
                                Button(action: {
                                    steps.append("")
                                }) {
                                    Text("Add Step")
                                        .font(.headline)
                                        .foregroundColor(.black)
                                        .padding()
                                        .frame(maxWidth: .infinity)
                                        .background(skyBlue.opacity(0.7))
                                        .cornerRadius(10)
                                        .shadow(color: .gray.opacity(0.2), radius: 3, x: 0, y: 3)
                                }
                            }
                            
                            // Save Button
                            Button(action: {
                                let filteredIngredients = ingredients.filter { !$0.isEmpty }
                                let filteredSteps = steps.filter { !$0.isEmpty }
                                
                                if title.isEmpty || filteredIngredients.isEmpty || filteredSteps.isEmpty {
                                    showAlert = true
                                } else {
                                    let color = placeholderColors.randomElement() ?? .gray
                                    let newRecipe = Recipe(
                                        category: category,
                                        title: title,
                                        ingredients: filteredIngredients,
                                        steps: filteredSteps,
                                        imageData: selectedImageData,
                                        imageColor: color
                                    )
                                    userRecipes.append(newRecipe)
                                    dismiss()
                                }
                            }) {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(grassGreen)
                                    .frame(height: 50)
                                    .shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 5)
                                    .overlay(
                                        Text("Save Recipe")
                                            .font(.headline)
                                            .foregroundColor(.black)
                                    )
                            }
                            .padding(.bottom, 20)
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
        .alert("Invalid Recipe", isPresented: $showAlert) {
            Button("OK") { }
        } message: {
            Text("Please provide a title, at least one ingredient, and at least one step. Photo is optional.")
        }
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var imageData: Data?

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)

            guard let provider = results.first?.itemProvider else { return }

            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { image, _ in
                    if let uiImage = image as? UIImage, let data = uiImage.jpegData(compressionQuality: 1.0) {
                        DispatchQueue.main.async {
                            self.parent.imageData = data
                        }
                    }
                }
            }
        }
    }
}

struct RecipesView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            RecipesView()
                .environmentObject(RecipeData())
                .environmentObject(TimerState(onTimerFinish: {}))
        }
    }
}
