import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage
import Combine
import AudioToolbox
import AVFoundation

// 1. MODELO DE DATOS (ACTUALIZADO PARA ARCHIVOS)
struct BroadcastItem: Identifiable {
    let id: String
    let text: String
    let senderName: String
    let role: String
    let timestamp: Date
    let imageUrl: String?
    
    // 🔥 NUEVOS CAMPOS PARA ARCHIVOS
    let fileUrl: String?
    let fileName: String?
    let fileType: String?
    
    // Ayuda a saber si es imagen o doc
    var isImage: Bool {
        if let type = fileType, type.starts(with: "image/") { return true }
        if let url = imageUrl ?? fileUrl {
            return url.lowercased().contains(".jpg") || url.lowercased().contains(".png") || url.lowercased().contains(".jpeg")
        }
        return false
    }
}

// 2. VIEW MODEL
class BroadcastListViewModel: ObservableObject {
    @Published var broadcasts: [BroadcastItem] = []
    @Published var newBroadcastText = ""
    @Published var selectedImage: UIImage?
    @Published var isSending = false
    
    var audioPlayer: AVAudioPlayer?
    private var isFirstLoad = true
    private var db = Firestore.firestore()
    
    init() { fetchBroadcasts() }
    
    func fetchBroadcasts() {
        db.collection("broadcasts").order(by: "timestamp", descending: true).addSnapshotListener { snap, _ in
            guard let docs = snap?.documents else { return }
            
            let fetchedBroadcasts = docs.compactMap { doc -> BroadcastItem? in
                let data = doc.data()
                let text = data["text"] as? String ?? ""
                let sender = data["senderName"] as? String ?? "Usuario"
                let role = data["role"] as? String ?? "client"
                let imgUrl = data["imageUrl"] as? String
                
                // 🔥 RECUPERAMOS LOS DATOS DEL ARCHIVO
                let fileUrl = data["fileUrl"] as? String
                let fileName = data["fileName"] as? String
                let fileType = data["fileType"] as? String
                
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
                    imageUrl: imgUrl,
                    fileUrl: fileUrl,     // Nuevo
                    fileName: fileName,   // Nuevo
                    fileType: fileType    // Nuevo
                )
            }
            
            // SONIDO ALERTA
            if !self.isFirstLoad && fetchedBroadcasts.count > self.broadcasts.count {
                self.reproducirSonidoPersonalizado()
            }
            
            self.broadcasts = fetchedBroadcasts
            self.isFirstLoad = false
        }
    }
    
    func reproducirSonidoPersonalizado() {
        if let soundURL = Bundle.main.url(forResource: "alerta", withExtension: "mp3") {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
                audioPlayer?.prepareToPlay()
                audioPlayer?.play()
            } catch { print("Error sonido: \(error)") }
        }
    }
    
    func sendBroadcast() {
        guard let user = Auth.auth().currentUser else { return }
        guard !newBroadcastText.isEmpty || selectedImage != nil else { return }
        
        isSending = true
        
        // A. CON IMAGEN (DESDE MÓVIL SOLO IMÁGENES POR AHORA)
        if let image = selectedImage, let imageData = image.jpegData(compressionQuality: 0.5) {
            let filename = UUID().uuidString
            let ref = Storage.storage().reference(withPath: "broadcast_images/\(filename).jpg")
            
            ref.putData(imageData, metadata: nil) { _, error in
                if let error = error {
                    print("Error: \(error)")
                    self.isSending = false
                    return
                }
                ref.downloadURL { url, _ in
                    guard let downloadUrl = url else { return }
                    // Al subir desde móvil, lo tratamos como imagen
                    self.saveToFirestore(text: self.newBroadcastText, user: user, fileUrl: downloadUrl.absoluteString, isImage: true)
                }
            }
        }
        // B. SOLO TEXTO
        else {
            saveToFirestore(text: newBroadcastText, user: user, fileUrl: nil, isImage: false)
        }
    }
    
    private func saveToFirestore(text: String, user: User, fileUrl: String?, isImage: Bool) {
        db.collection("users").document(user.uid).getDocument { snap, _ in
            let name = snap?.data()?["name"] as? String ?? "Usuario"
            let role = snap?.data()?["role"] as? String ?? "client"
            
            var data: [String: Any] = [
                "text": text,
                "senderName": name,
                "role": role,
                "timestamp": Timestamp(date: Date())
            ]
            
            if let url = fileUrl {
                data["imageUrl"] = url // Compatibilidad
                data["fileUrl"] = url
                if isImage {
                    data["fileType"] = "image/jpeg"
                    data["fileName"] = "image_mobile.jpg"
                }
            }
            
            self.db.collection("broadcasts").addDocument(data: data) { error in
                DispatchQueue.main.async {
                    self.newBroadcastText = ""
                    self.selectedImage = nil
                    self.isSending = false
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
                        
                        // 🔥 LOGICA INTELIGENTE DE ARCHIVOS 🔥
                        if let fileUrl = msg.fileUrl ?? msg.imageUrl, let url = URL(string: fileUrl) {
                            
                            if msg.isImage {
                                // CASO A: ES UNA IMAGEN -> MOSTRARLA
                                AsyncImage(url: url) { image in
                                    image.resizable().scaledToFit().cornerRadius(10)
                                } placeholder: {
                                    ZStack { Color.gray.opacity(0.1); ProgressView() }.frame(height: 150)
                                }
                                .frame(maxHeight: 250)
                                .onTapGesture {
                                    // Opcional: Abrir imagen en pantalla completa si quieres
                                }
                            } else {
                                // CASO B: ES UN DOCUMENTO (PDF, DOC, EXCEL) -> BOTÓN
                                Link(destination: url) {
                                    HStack {
                                        Image(systemName: "doc.text.fill")
                                            .font(.title2)
                                        VStack(alignment: .leading) {
                                            Text(msg.fileName ?? "Attachment")
                                                .font(.headline)
                                                .lineLimit(1)
                                            Text("Tap to view or download")
                                                .font(.caption)
                                        }
                                        Spacer()
                                        Image(systemName: "arrow.up.right.square")
                                    }
                                    .padding()
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(10)
                                    .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                // INPUT AREA (Sin cambios, solo envía imágenes desde móvil)
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
                        
                        TextField("Write an announcement...", text: $viewModel.newBroadcastText, axis: .vertical)
                            .padding(10)
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(20)
                        
                        if viewModel.isSending {
                            ProgressView().padding(.bottom, 8)
                        } else {
                            Button(action: { viewModel.sendBroadcast() }) {
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
            .navigationTitle("Broadcast")
            .sheet(isPresented: $showImagePicker) {
                BroadcastPhotoPicker(image: $viewModel.selectedImage)
            }
        }
    }
}
// ATTACHMENT VIEW
struct AttachmentView: View {
    let fileUrl: String?
    let fileName: String?
    let fileType: String?
    let imageUrl: String? // Por compatibilidad

    // Ayuda a saber si es imagen o doc
    var isImage: Bool {
        if let type = fileType, type.starts(with: "image/") { return true }
        if let url = imageUrl ?? fileUrl {
            return url.lowercased().contains(".jpg") || url.lowercased().contains(".png") || url.lowercased().contains(".jpeg")
        }
        return false
    }

    var body: some View {
        if let link = fileUrl ?? imageUrl, let url = URL(string: link) {
            Group {
                if isImage {
                    // MODO FOTO
                    AsyncImage(url: url) { image in
                        image.resizable().scaledToFit().cornerRadius(12)
                    } placeholder: {
                        ZStack { Color.gray.opacity(0.1); ProgressView() }.frame(height: 200)
                    }
                } else {
                    // MODO DOCUMENTO (PDF, Excel, Word)
                    Link(destination: url) {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle().fill(Color.blue.opacity(0.1))
                                    .frame(width: 40, height: 40)
                                Image(systemName: "doc.text.fill")
                                    .foregroundColor(.blue)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(fileName ?? "Attachment")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.primary)
                                    .lineLimit(1)
                                
                                Text("Tap to download")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "arrow.down.circle.fill")
                                .font(.title2)
                                .foregroundColor(.blue.opacity(0.8))
                        }
                        .padding(12)
                        .background(Color.white) // O Color(UIColor.systemBackground)
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                    }
                }
            }
            .padding(.top, 8)
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
