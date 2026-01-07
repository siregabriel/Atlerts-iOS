import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import Combine

// 1. VIEW MODEL
class UserProfileViewModel: ObservableObject {
    @Published var user: AtlertsUser?
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var showAlert = false
    @Published var alertMessage = ""
    
    @State private var showChangePassword = false
    
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
        db.collection("users").document(user.uid).delete { _ in
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

// 2. VISTA (DISEÑO ORIGINAL CON MEJORA DE IMAGEN)
struct ProfileView: View {
    @StateObject var viewModel = UserProfileViewModel()
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var showDeleteAlert = false
    
    @State private var showChangePassword = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.systemGroupedBackground).ignoresSafeArea()
                
                if viewModel.isLoading {
                    ProgressView("Updating...")
                        .padding()
                        .foregroundColor(.black)
                        .background(Color.white.opacity(0.5))
                        .cornerRadius(10)
                        .shadow(radius: 5)
                        .zIndex(1)
                }
                
                List {
                    // SECCIÓN 1: CABECERA DE PERFIL
                    Section {
                        VStack(spacing: 15) {
                            // FOTO DE PERFIL
                            Button {
                                showImagePicker = true
                            } label: {
                                ZStack {
                                    // 1. SI EL USUARIO ACABA DE ELEGIR UNA FOTO DE SU CÁMARA
                                    if let image = selectedImage {
                                        Image(uiImage: image)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 110, height: 110)
                                            .clipShape(Circle())
                                            .overlay(Circle().stroke(Color.white, lineWidth: 4))
                                            .shadow(radius: 5)
                                    
                                    // 2. SI HAY URL EN FIREBASE (AQUÍ ESTÁ LA MEJORA)
                                    } else if let urlStr = viewModel.user?.profileImageURL, let url = URL(string: urlStr) {
                                        
                                        AsyncImage(url: url) { phase in
                                            switch phase {
                                            case .empty:
                                                // CARGANDO (Spinner)
                                                ZStack {
                                                    Color(UIColor.systemGray6)
                                                    ProgressView()
                                                }
                                            case .success(let image):
                                                // ÉXITO (Fade-in)
                                                image
                                                    .resizable()
                                                    .scaledToFill()
                                                    .transition(.opacity.animation(.easeOut(duration: 0.5)))
                                            case .failure:
                                                // ERROR
                                                Image(systemName: "person.circle.fill")
                                                    .resizable()
                                                    .foregroundColor(.gray)
                                            @unknown default:
                                                EmptyView()
                                            }
                                        }
                                        .frame(width: 110, height: 110)
                                        .clipShape(Circle())
                                        // ✨ EL BORDE BLANCO ELEGANTE
                                        .overlay(Circle().stroke(Color.white, lineWidth: 4))
                                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 5)

                                    // 3. SI NO HAY NADA (DEFAULT)
                                    } else {
                                        Image(systemName: "person.circle.fill")
                                            .resizable()
                                            .foregroundColor(.gray)
                                            .frame(width: 110, height: 110)
                                            .overlay(Circle().stroke(Color.white, lineWidth: 4))
                                            .shadow(radius: 5)
                                    }
                                    
                                    // ICONO DE CÁMARA (TU ESTILO ORIGINAL)
                                    Image(systemName: "camera.fill")
                                        .font(.caption)
                                        .foregroundColor(.white)
                                        .padding(8)
                                        .background(Color.blue)
                                        .clipShape(Circle())
                                        .offset(x: 38, y: 38) // Ajustado ligeramente para el nuevo tamaño
                                        .shadow(radius: 2)
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            // DATOS DEL USUARIO
                            VStack(spacing: 5) {
                                Text(viewModel.user?.name ?? "Loading...")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                
                                Text(viewModel.user?.email ?? "")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                
                                // BADGE DE ROL
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
                    .listRowBackground(Color.clear)
                    
                    // SECCIÓN 2: INFORMACIÓN
                    Section(header: Text("Information")) {
                        HStack {
                            Image(systemName: "building.2.fill").foregroundColor(.blue)
                            Text("Community")
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
                    
                    // Opción: Acerca de
                    NavigationLink(destination: AboutView()) {
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundColor(.blue)
                                .frame(width: 25)
                            Text("About this App")
                                .foregroundColor(.primary)
                            Spacer()
                        }
                    }
                    
                    // SECCIÓN 3: ACCIONES
                    Button(action: { showChangePassword = true }) {
                        HStack {
                            Image(systemName: "lock.rotation")
                                .foregroundColor(.blue)
                                .frame(width: 25)
                            Text("Change Password")
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                                .font(.caption)
                        }
                    }
                    .sheet(isPresented: $showChangePassword) {
                        ChangePasswordView()
                    }
                    
                    Section {
                        Button(action: { viewModel.logout() }) {
                            HStack {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                Text("Logout")
                            }
                            .foregroundColor(.red)
                        }
                        
                        Button(action: { showDeleteAlert = true }) {
                            HStack {
                                Image(systemName: "trash")
                                Text("Delete account")
                            }
                            .foregroundColor(.red)
                        }
                    }
                }
            }
            .navigationTitle("Profile")
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
                    title: Text("¿Delete account?"),
                    message: Text("This action cannot be undone. You will lose access to the app."),
                    primaryButton: .destructive(Text("Delete")) {
                        viewModel.deleteAccount()
                    },
                    secondaryButton: .cancel()
                )
            }
        }
    }
}

// 3. IMAGE PICKER
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
