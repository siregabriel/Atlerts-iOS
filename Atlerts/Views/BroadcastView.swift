import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage
import Combine

// 1. MODELO DE DATOS (MODO MANUAL)
struct BroadcastItem: Identifiable {
    let id: String
    let text: String
    let senderName: String
    let role: String
    let timestamp: Date
    let imageUrl: String?
}

// 2. VIEW MODEL
class BroadcastListViewModel: ObservableObject {
    @Published var broadcasts: [BroadcastItem] = []
    @Published var newBroadcastText = ""
    @Published var selectedImage: UIImage?
    @Published var isSending = false
    
    private var db = Firestore.firestore()
    
    init() { fetchBroadcasts() }
    
    func fetchBroadcasts() {
        db.collection("broadcasts").order(by: "timestamp", descending: true).addSnapshotListener { snap, _ in
            guard let docs = snap?.documents else { return }
            
            // MAPEO MANUAL
            self.broadcasts = docs.compactMap { doc in
                let data = doc.data()
                let text = data["text"] as? String ?? ""
                let sender = data["senderName"] as? String ?? "Usuario"
                let role = data["role"] as? String ?? "client"
                let imgUrl = data["imageUrl"] as? String
                
                let date: Date
                if let timestamp = data["timestamp"] as? Timestamp {
                    date = timestamp.dateValue()
                } else {
                    date = Date()
                }
                
                return BroadcastItem(
                    id: doc.documentID,
                    text: text,
                    senderName: sender,
                    role: role,
                    timestamp: date,
                    imageUrl: imgUrl
                )
            }
        }
    }
    
    func sendBroadcast() {
        guard let user = Auth.auth().currentUser else { return }
        guard !newBroadcastText.isEmpty || selectedImage != nil else { return }
        
        isSending = true
        
        // A. CON IMAGEN
        if let image = selectedImage, let imageData = image.jpegData(compressionQuality: 0.5) {
            let filename = UUID().uuidString
            let ref = Storage.storage().reference(withPath: "broadcast_images/\(filename).jpg")
            
            ref.putData(imageData, metadata: nil) { _, error in
                if let error = error {
                    print("Error subiendo: \(error)")
                    self.isSending = false
                    return
                }
                
                ref.downloadURL { url, _ in
                    guard let downloadUrl = url else { return }
                    self.saveToFirestore(text: self.newBroadcastText, user: user, imageUrl: downloadUrl.absoluteString)
                }
            }
        }
        // B. SOLO TEXTO
        else {
            saveToFirestore(text: newBroadcastText, user: user, imageUrl: nil)
        }
    }
    
    private func saveToFirestore(text: String, user: User, imageUrl: String?) {
        db.collection("users").document(user.uid).getDocument { snap, _ in
            let name = snap?.data()?["name"] as? String ?? "Usuario"
            let role = snap?.data()?["role"] as? String ?? "client"
            
            var data: [String: Any] = [
                "text": text,
                "senderName": name,
                "role": role,
                "timestamp": Timestamp(date: Date())
            ]
            
            if let url = imageUrl {
                data["imageUrl"] = url
            }
            
            self.db.collection("broadcasts").addDocument(data: data) { error in
                DispatchQueue.main.async {
                    self.newBroadcastText = ""
                    self.selectedImage = nil
                    self.isSending = false
                    
                    // 🔥 ¡AQUÍ ESTÁ LA VIBRACIÓN DE ÉXITO! 🔥
                    hapticSuccess()
                }
            }
        }
    }
}

// 3. VISTA
struct BroadcastView: View {
    @StateObject var viewModel = BroadcastListViewModel()
    @State private var showImagePicker = false
    
    var body: some View {
        NavigationView {
            VStack {
                // LISTA
                List(viewModel.broadcasts) { msg in
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Image(systemName: "megaphone.fill").foregroundColor(.yellow)
                            Text(msg.senderName).font(.caption).bold().foregroundColor(.secondary)
                            Spacer()
                            Text(msg.timestamp, style: .date).font(.caption2).foregroundColor(.gray)
                        }
                        
                        if !msg.text.isEmpty {
                            Text(msg.text).font(.body)
                        }
                        
                        if let urlStr = msg.imageUrl, let url = URL(string: urlStr) {
                            AsyncImage(url: url) { image in
                                image.resizable().scaledToFit().cornerRadius(10)
                            } placeholder: {
                                ZStack {
                                    Color.gray.opacity(0.1)
                                    ProgressView()
                                }.frame(height: 150)
                            }
                            .frame(maxHeight: 250)
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                // INPUT AREA
                VStack(spacing: 0) {
                    if let img = viewModel.selectedImage {
                        HStack {
                            Image(uiImage: img).resizable().scaledToFit().frame(height: 60).cornerRadius(8)
                            Button(action: { viewModel.selectedImage = nil }) {
                                Image(systemName: "xmark.circle.fill").foregroundColor(.gray)
                            }
                            Spacer()
                        }
                        .padding(.horizontal).padding(.top, 10)
                    }
                    
                    HStack(alignment: .bottom) {
                        Button(action: { showImagePicker = true }) {
                            Image(systemName: "photo").font(.title2).foregroundColor(.blue)
                        }
                        .padding(.bottom, 8)
                        
                        TextField("Escribe un aviso...", text: $viewModel.newBroadcastText, axis: .vertical)
                            .padding(10)
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(20)
                        
                        if viewModel.isSending {
                            ProgressView()
                                .padding(.bottom, 8)
                        } else {
                            // 🔥 AQUÍ ESTÁ EL BOTÓN CON VIBRACIÓN 🔥
                            Button(action: {
                                haptic(.medium) // Vibración al tocar
                                viewModel.sendBroadcast()
                            }) {
                                Image(systemName: "paperplane.fill")
                                    .font(.title2)
                                    .foregroundColor((!viewModel.newBroadcastText.isEmpty || viewModel.selectedImage != nil) ? .blue : .gray)
                            }
                            .padding(.bottom, 8)
                            .disabled(viewModel.newBroadcastText.isEmpty && viewModel.selectedImage == nil)
                        }
                    }
                    .padding()
                }
                .background(Color(UIColor.systemBackground))
                .shadow(radius: 2)
            }
            .navigationTitle("Avisos")
            .sheet(isPresented: $showImagePicker) {
                BroadcastPhotoPicker(image: $viewModel.selectedImage)
            }
        }
    }
}

// 4. IMAGE PICKER
struct BroadcastPhotoPicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        return picker
    }
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: BroadcastPhotoPicker
        init(_ parent: BroadcastPhotoPicker) { self.parent = parent }
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[.originalImage] as? UIImage { parent.image = uiImage }
            picker.dismiss(animated: true)
        }
    }
}
