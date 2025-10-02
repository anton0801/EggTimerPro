
import SwiftUI
import PhotosUI

struct Note: Identifiable, Codable {
    let id = UUID()
    let text: String
    let imageData: Data?
}

struct DailyView: View {
    @EnvironmentObject var recipeData: RecipeData // Shared recipe data
    @EnvironmentObject var timerState: TimerState // Required for TabViewScreen
    @State private var isAddNoteFormPresented = false
    @State private var noteText = ""
    @State private var selectedImage: UIImage?
    @State private var isPhotoPickerPresented = false
    @State private var notes: [Note] = []
    
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
                    // Header Card
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white)
                            .shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 5)
                        
                        HStack {
                            Text("Diary")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.black)
                            
                            Spacer()
                            
                            NavigationLink(destination: FavoritesView().environmentObject(recipeData)) {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(LinearGradient(
                                        gradient: Gradient(colors: [yolkYellow.opacity(0.7), yolkYellow]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ))
                                    .frame(width: 120, height: 40)
                                    .shadow(color: .gray.opacity(0.2), radius: 3, x: 0, y: 3)
                                    .overlay(
                                        HStack(spacing: 8) {
                                            Image(systemName: "star.fill")
                                                .foregroundColor(yolkYellow)
                                            Text("Favorites")
                                                .font(.subheadline)
                                                .foregroundColor(.black)
                                        }
                                    )
                            }
                        }
                        .padding(.vertical, 15)
                        .padding(.horizontal)
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)
                    
                    // Past Preparations Card
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white)
                            .shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 5)
                        
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Past Preparations")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.black)
                            
                            ForEach(recipeData.allRecipes) { recipe in
                                NavigationLink(destination: RecipeDetailView(recipe: recipe, favoriteIds: $recipeData.favoriteIds, onDelete: {
                                    recipeData.userRecipes.removeAll { $0.id == recipe.id }
                                })) {
                                    VStack(spacing: 10) {
                                        if let data = recipe.imageData, let uiImage = UIImage(data: data) {
                                            Image(uiImage: uiImage)
                                                .resizable()
                                                .scaledToFill()
                                                .frame(height: 100)
                                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                                .padding(.horizontal, 10)
                                        } else {
                                            Rectangle()
                                                .fill(recipe.imageColor.opacity(0.5))
                                                .frame(height: 100)
                                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                                .padding(.horizontal, 10)
                                        }
                                        
                                        Text(recipe.title)
                                            .font(.body)
                                            .foregroundColor(.black)
                                            .padding(.horizontal, 10)
                                    }
                                    .padding(.vertical, 10)
                                    .background(Color.white.opacity(0.9))
                                    .cornerRadius(10)
                                    .shadow(color: .gray.opacity(0.2), radius: 3, x: 0, y: 3)
                                }
                            }
                        }
                        .padding(.vertical, 15)
                        .padding(.horizontal)
                    }
                    .padding(.horizontal)
                    
                    // Add Note Button
                    Button(action: {
                        withAnimation(.easeInOut) {
                            isAddNoteFormPresented = true
                        }
                        let impact = UIImpactFeedbackGenerator(style: .medium)
                        impact.prepare()
                        impact.impactOccurred()
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
                                Text("Add Note")
                                    .font(.headline)
                                    .foregroundColor(.black)
                            )
                    }
                    .padding(.horizontal)
                    
                    // Notes List Card
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white)
                            .shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 5)
                        
                        VStack(spacing: 15) {
                            Text("Notes")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.black)
                                .padding(.horizontal)
                            
                            ForEach(notes) { note in
                                VStack(spacing: 10) {
                                    if let imageData = note.imageData, let uiImage = UIImage(data: imageData) {
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(height: 150)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                            .padding(.horizontal, 10)
                                    }
                                    
                                    if !note.text.isEmpty {
                                        Text(note.text)
                                            .font(.body)
                                            .foregroundColor(.black)
                                            .padding(.horizontal, 10)
                                    }
                                }
                                .padding(.vertical, 10)
                                .background(Color.white.opacity(0.9))
                                .cornerRadius(10)
                                .shadow(color: .gray.opacity(0.2), radius: 3, x: 0, y: 3)
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        withAnimation {
                                            notes.removeAll { $0.id == note.id }
                                        }
                                        let impact = UIImpactFeedbackGenerator(style: .medium)
                                        impact.impactOccurred()
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 15)
                        .padding(.horizontal)
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 20)
            }
            .sheet(isPresented: $isAddNoteFormPresented) {
                ZStack {
                    LinearGradient(
                        gradient: Gradient(colors: [creamyWhite, creamyWhite.opacity(0.8)]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea()
                    
                    ScrollView {
                        VStack(spacing: 20) {
                            // Header Card
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white)
                                    .shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 5)
                                
                                HStack {
                                    Text("New Note")
                                        .font(.largeTitle)
                                        .fontWeight(.bold)
                                        .foregroundColor(.black)
                                    
                                    Spacer()
                                    
                                    Button(action: {
                                        withAnimation(.easeInOut) {
                                            isAddNoteFormPresented = false
                                            noteText = ""
                                            selectedImage = nil
                                        }
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.gray)
                                            .frame(width: 30, height: 30)
                                    }
                                }
                                .padding(.vertical, 15)
                                .padding(.horizontal)
                            }
                            .padding(.horizontal)
                            .padding(.top, 20)
                            
                            // Note Form Card
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white)
                                    .shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 5)
                                
                                VStack(spacing: 20) {
                                    TextField("Write your note here...", text: $noteText)
                                        .font(.body)
                                        .padding()
                                        .background(Color.white.opacity(0.8))
                                        .cornerRadius(10)
                                        .shadow(color: .gray.opacity(0.2), radius: 3, x: 0, y: 3)
                                    
                                    Button(action: {
                                        isPhotoPickerPresented = true
                                        let impact = UIImpactFeedbackGenerator(style: .medium)
                                        impact.prepare()
                                        impact.impactOccurred()
                                    }) {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(yolkYellow.opacity(0.2))
                                                .frame(height: 200)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .stroke(yolkYellow, lineWidth: 2)
                                                )
                                            
                                            if let image = selectedImage {
                                                Image(uiImage: image)
                                                    .resizable()
                                                    .scaledToFill()
                                                    .frame(height: 200)
                                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 12)
                                                            .stroke(yolkYellow, lineWidth: 2)
                                                    )
                                            } else {
                                                VStack(spacing: 8) {
                                                    Image(systemName: "photo")
                                                        .resizable()
                                                        .scaledToFit()
                                                        .frame(width: 50, height: 50)
                                                        .foregroundColor(yolkYellow)
                                                    Text("Add Photo")
                                                        .font(.subheadline)
                                                        .foregroundColor(.gray)
                                                }
                                            }
                                        }
                                    }
                                    .sheet(isPresented: $isPhotoPickerPresented) {
                                        PhotoPicker(selectedImage: $selectedImage)
                                    }
                                    
                                    HStack(spacing: 20) {
                                        Button(action: {
                                            withAnimation(.easeInOut) {
                                                isAddNoteFormPresented = false
                                                noteText = ""
                                                selectedImage = nil
                                            }
                                            let impact = UIImpactFeedbackGenerator(style: .light)
                                            impact.impactOccurred()
                                        }) {
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(Color.gray.opacity(0.2))
                                                .frame(height: 50)
                                                .shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 5)
                                                .overlay(
                                                    Text("Cancel")
                                                        .font(.headline)
                                                        .foregroundColor(.gray)
                                                )
                                        }
                                        
                                        Button(action: {
                                            withAnimation(.easeInOut) {
                                                if !noteText.isEmpty || selectedImage != nil {
                                                    let imageData = selectedImage?.jpegData(compressionQuality: 0.8)
                                                    let newNote = Note(text: noteText, imageData: imageData)
                                                    notes.append(newNote)
                                                }
                                                isAddNoteFormPresented = false
                                                noteText = ""
                                                selectedImage = nil
                                            }
                                            let impact = UIImpactFeedbackGenerator(style: .medium)
                                            impact.impactOccurred()
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
                                                    Text("Save")
                                                        .font(.headline)
                                                        .foregroundColor(.black)
                                                )
                                        }
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
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            // Load notes
            if let data = UserDefaults.standard.data(forKey: "notes"),
               let decoded = try? JSONDecoder().decode([Note].self, from: data) {
                notes = decoded
            }
        }
        .onDisappear {
            // Save notes
            if let data = try? JSONEncoder().encode(notes) {
                UserDefaults.standard.set(data, forKey: "notes")
            }
        }
    }
}

// Photo Picker Representable for iOS 15
struct PhotoPicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 1
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PhotoPicker
        
        init(_ parent: PhotoPicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            
            guard let provider = results.first?.itemProvider else { return }
            
            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { image, _ in
                    DispatchQueue.main.async {
                        self.parent.selectedImage = image as? UIImage
                    }
                }
            }
        }
    }
}

struct DailyView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            DailyView()
                .environmentObject(RecipeData())
                .environmentObject(TimerState(onTimerFinish: {}))
        }
    }
}
