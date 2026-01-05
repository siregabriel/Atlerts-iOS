import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import Combine

// 1. VIEW MODEL (Mantenemos el nombre único para evitar conflictos)
class UserProfileViewModel: ObservableObject {
    @Published var user: AtlertsUser?
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var showAlert = false
    @Published var alertMessage = ""
    
    private var db = Firestore.firestore()
    
    init() {
        fetchUserProfile()
    }
    
    func fetchUserProfile() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        db.collection("users").document(uid).addSnapshotListener { snap, _ in
            self.user = try? snap?.data(as: AtlertsUser.self)
        }
    }
    
    // LA LÓGICA DE SUBIDA DE IMAGEN (ARREGLADA)
    func saveProfileImage(image: UIImage) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        isLoading = true
        
        guard let imageData = image.jpegData(compressionQuality: 0.5) else {
            isLoading = false
            return
        }
        
        let ref = Storage.storage().reference(withPath: "profile_images/\(uid).jpg")
        
        ref.putData(imageData, metadata: nil) { _, error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                self.isLoading = false
                return
            }
            
            ref.downloadURL { url, error in
                guard let downloadURL = url else {
                    self.isLoading = false
                    return
                }
                
                self.db.collection("users").document(uid).updateData([
                    "profileImageURL": downloadURL.absoluteString
                ]) { _ in
                    self.isLoading = false
                }
            }
        }
    }
    
    func deleteAccount() {
        guard let user = Auth.auth().currentUser else { return }
        // Borramos el documento de usuario primero
        db.collection("users").document(user.uid).delete { _ in
            // Luego borramos la cuenta de autenticación
            user.delete { error in
                if let error = error {
                    self.alertMessage = "Error: \(error.localizedDescription)"
                    self.showAlert = true
                }
            }
        }
    }
    
    func logout() {
        try? Auth.auth().signOut()
    }
}

// 2. VISTA (DISEÑO RESTAURADO Y MEJORADO)
struct ProfileView: View {
    @StateObject var viewModel = UserProfileViewModel()
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var showDeleteAlert = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.systemGroupedBackground).ignoresSafeArea()
                
                if viewModel.isLoading {
                    ProgressView("Actualizando perfil...")
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                        .shadow(radius: 5)
                        .zIndex(1)
                }
                
                List {
                    // SECCIÓN 1: CABECERA DE PERFIL
                    Section {
                        VStack(spacing: 15) {
                            // FOTO
                            Button {
                                showImagePicker = true
                            } label: {
                                ZStack {
                                    if let image = selectedImage {
                                        Image(uiImage: image)
                                            .resizable().scaledToFill()
                                            .frame(width: 100, height: 100).clipShape(Circle())
                                    } else if let urlStr = viewModel.user?.profileImageURL, let url = URL(string: urlStr) {
                                        AsyncImage(url: url) { image in
                                            image.resizable().scaledToFill()
                                        } placeholder: {
                                            Color.gray.opacity(0.3)
                                        }
                                        .frame(width: 100, height: 100).clipShape(Circle())
                                    } else {
                                        Image(systemName: "person.circle.fill")
                                            .resizable().foregroundColor(.gray)
                                            .frame(width: 100, height: 100)
                                    }
                                    
                                    // Icono cámara
                                    Image(systemName: "camera.fill")
                                        .font(.caption)
                                        .foregroundColor(.white)
                                        .padding(8)
                                        .background(Color.blue)
                                        .clipShape(Circle())
                                        .offset(x: 35, y: 35)
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            // DATOS
                            VStack(spacing: 5) {
                                Text(viewModel.user?.name ?? "Cargando...")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                
                                Text(viewModel.user?.email ?? "")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                
                                // BADGE DE ROL (Restaurado)
                                if let role = viewModel.user?.role {
                                    HStack(spacing: 4) {
                                        Image(systemName: role == "moderator" ? "shield.fill" : "person.fill")
                                        Text(role == "moderator" ? "Super Admin" : "Cliente")
                                    }
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(role == "moderator" ? Color.yellow.opacity(0.2) : Color.gray.opacity(0.2))
                                    .foregroundColor(role == "moderator" ? .orange : .gray)
                                    .cornerRadius(20)
                                    .padding(.top, 4)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                    }
                    .listRowBackground(Color.clear) // Fondo transparente para que se vea limpio
                    
                    // SECCIÓN 2: INFORMACIÓN CORPORATIVA
                    Section(header: Text("Información")) {
                        HStack {
                            Image(systemName: "building.2.fill").foregroundColor(.blue)
                            Text("Comunidad")
                            Spacer()
                            Text(viewModel.user?.community ?? "Sin asignar").foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Image(systemName: "envelope.fill").foregroundColor(.blue)
                            Text("Email")
                            Spacer()
                            Text(viewModel.user?.email ?? "").foregroundColor(.secondary).font(.caption)
                        }
                    }
                    
                    // SECCIÓN 3: ZONA DE PELIGRO Y SESIÓN
                    Section {
                        Button(action: { viewModel.logout() }) {
                            HStack {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                Text("Cerrar Sesión")
                            }
                            .foregroundColor(.red)
                        }
                        
                        Button(action: { showDeleteAlert = true }) {
                            HStack {
                                Image(systemName: "trash")
                                Text("Eliminar Cuenta")
                            }
                            .foregroundColor(.red)
                        }
                    }
                }
            }
            .navigationTitle("Mi Perfil")
            .sheet(isPresented: $showImagePicker) {
                ProfileImagePicker(image: $selectedImage)
                    .onDisappear {
                        if let img = selectedImage {
                            viewModel.saveProfileImage(image: img)
                        }
                    }
            }
            .alert(isPresented: $showDeleteAlert) {
                Alert(
                    title: Text("¿Eliminar cuenta?"),
                    message: Text("Esta acción no se puede deshacer. Perderás acceso a la app."),
                    primaryButton: .destructive(Text("Eliminar")) {
                        viewModel.deleteAccount()
                    },
                    secondaryButton: .cancel()
                )
            }
        }
    }
}

// 3. IMAGE PICKER (Mantenemos el nombre único)
struct ProfileImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        return picker
    }
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ProfileImagePicker
        init(_ parent: ProfileImagePicker) { self.parent = parent }
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[.originalImage] as? UIImage { parent.image = uiImage }
            picker.dismiss(animated: true)
        }
    }
}
