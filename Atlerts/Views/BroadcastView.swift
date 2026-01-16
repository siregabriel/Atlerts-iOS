//
//  BroadcastView.swift
//  Atlerts
//
//  Created by Gabriel Rosales Montes on 03/01/26.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage
import Combine
import AudioToolbox
import AVFoundation

// 1. MODELO DE DATOS
struct BroadcastItem: Identifiable {
    let id: String
    let text: String
    let senderName: String
    let role: String
    let timestamp: Date
    let imageUrl: String?
    
    // CAMPOS DE ARCHIVO
    let fileUrl: String?
    let fileName: String?
    let fileType: String?
    
    // LISTA DE QUIENES YA LEYERON
    let readBy: [String]
    
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
    private var currentUserId = Auth.auth().currentUser?.uid
    
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
                let fileUrl = data["fileUrl"] as? String
                let fileName = data["fileName"] as? String
                let fileType = data["fileType"] as? String
                let readBy = data["readBy"] as? [String] ?? []
                
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
                    fileUrl: fileUrl,
                    fileName: fileName,
                    fileType: fileType,
                    readBy: readBy
                )
            }
            
            if !self.isFirstLoad && fetchedBroadcasts.count > self.broadcasts.count {
                self.reproducirSonidoPersonalizado()
            }
            
            self.broadcasts = fetchedBroadcasts
            self.isFirstLoad = false
        }
    }
    
    // MARK: - LOGICA DE RESPUESTA (REPLY)
    func sendReply(broadcastId: String, replyText: String, completion: @escaping (Bool) -> Void) {
        guard let user = Auth.auth().currentUser, !replyText.isEmpty else { return }
        
        db.collection("users").document(user.uid).getDocument { snap, _ in
            let myName = snap?.data()?["name"] as? String ?? "Usuario"
            
            let replyData: [String: Any] = [
                "text": replyText,
                "senderId": user.uid,
                "senderName": myName,
                "timestamp": Timestamp(date: Date())
            ]
            
            self.db.collection("broadcasts").document(broadcastId).collection("replies").addDocument(data: replyData) { error in
                if error == nil {
                    print("✅ Respuesta enviada a Wyman")
                    completion(true)
                } else {
                    completion(false)
                }
            }
        }
    }
    
    func markAsRead(messageId: String) {
        guard let uid = currentUserId else { return }
        if let message = broadcasts.first(where: { $0.id == messageId }) {
            if !message.readBy.contains(uid) {
                db.collection("broadcasts").document(messageId).updateData([
                    "readBy": FieldValue.arrayUnion([uid])
                ])
            }
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
                    self.saveToFirestore(text: self.newBroadcastText, user: user, fileUrl: downloadUrl.absoluteString, isImage: true)
                }
            }
        } else {
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
                "timestamp": Timestamp(date: Date()),
                "readBy": []
            ]
            
            if let url = fileUrl {
                data["imageUrl"] = url
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

// 3. VISTA PRINCIPAL
struct BroadcastView: View {
    @StateObject var viewModel = BroadcastListViewModel()
    @State private var showImagePicker = false
    
    // ESTADO PARA RESPONDER A WYMAN
    @State private var broadcastToReply: BroadcastItem? = nil
    
    var body: some View {
        NavigationView {
            VStack {
                // LISTA DE MENSAJES
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
                        
                        // ARCHIVOS / FOTOS
                        AttachmentView(fileUrl: msg.fileUrl, fileName: msg.fileName, fileType: msg.fileType, imageUrl: msg.imageUrl)
                        
                        // BARRA DE ACCIONES
                        HStack(spacing: 12) {
                            
                            // A) SI ES WYMAN -> MOSTRAR BOTONES
                            if msg.senderName.contains("Wyman") {
                                
                                // 1. Botón RESPONDER
                                Button(action: {
                                    self.broadcastToReply = msg
                                }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "arrowshape.turn.up.left.fill")
                                        Text("Reply")
                                    }
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .padding(.vertical, 6)
                                    .padding(.horizontal, 12)
                                    .background(Color.blue)
                                    .cornerRadius(8)
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                // 2. Botón VER RESPUESTAS (INBOX)
                                NavigationLink(destination: RepliesListView(broadcastId: msg.id)) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "envelope.open.fill")
                                        Text("Inbox")
                                    }
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                                    .padding(.vertical, 6)
                                    .padding(.horizontal, 12)
                                    .background(Color.gray.opacity(0.2))
                                    .cornerRadius(8)
                                }
                                .buttonStyle(PlainButtonStyle()) // 🔥 FIX: Agregado para que funcione el click individual
                            }
                            
                            Spacer()
                            
                            // 3. Botón VISTO
                            NavigationLink(destination: ReadReceiptsView(messageId: msg.id, readByIDs: msg.readBy)) {
                                HStack(spacing: 4) {
                                    Image(systemName: "eye.fill")
                                    Text("\(msg.readBy.count)")
                                }
                                .font(.caption)
                                .foregroundColor(.gray)
                                .padding(6)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                            }
                            .buttonStyle(PlainButtonStyle()) // 🔥 FIX: Agregado para que funcione el click individual
                        }
                        .padding(.top, 5)
                    }
                    .padding(.vertical, 4)
                    .onAppear {
                        viewModel.markAsRead(messageId: msg.id)
                    }
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
            .sheet(item: $broadcastToReply) { item in
                ReplyView(broadcastItem: item, viewModel: viewModel)
            }
        }
    }
}

// 4. VISTAS AUXILIARES (Visto, Attachments, Picker)
struct ReadReceiptsView: View {
    let messageId: String
    let readByIDs: [String]
    @State private var users: [AtlertsUser] = []
    @State private var isLoading = true
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView("Cargando lectores...")
            } else if users.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "eye.slash").font(.largeTitle).foregroundColor(.gray)
                    Text("Nadie lo ha visto aún.").foregroundColor(.gray)
                }
            } else {
                List(users, id: \.uid) { user in
                    HStack {
                        if let urlStr = user.profileImageURL, let url = URL(string: urlStr) {
                            AsyncImage(url: url) { image in image.resizable().scaledToFill() } placeholder: { Color.gray.opacity(0.3) }
                            .frame(width: 40, height: 40).clipShape(Circle())
                        } else {
                            Image(systemName: "person.circle.fill").resizable().frame(width: 40, height: 40).foregroundColor(.gray)
                        }
                        VStack(alignment: .leading) {
                            Text(user.name ?? "Usuario Desconocido").font(.headline)
                            Text(user.community ?? "Sin comunidad").font(.caption).foregroundColor(.gray)
                        }
                    }
                }
            }
        }
        .navigationTitle("Visto por")
        .onAppear { fetchUsers() }
    }
    
    func fetchUsers() {
        guard !readByIDs.isEmpty else { isLoading = false; return }
        let idsToFetch = Array(readByIDs.prefix(10))
        Firestore.firestore().collection("users").whereField("uid", in: idsToFetch).getDocuments { snap, error in
            Task { @MainActor in
                self.isLoading = false
                guard let docs = snap?.documents else { return }
                self.users = docs.compactMap { try? $0.data(as: AtlertsUser.self) }
            }
        }
    }
}

struct AttachmentView: View {
    let fileUrl: String?
    let fileName: String?
    let fileType: String?
    let imageUrl: String?
    var isImage: Bool {
        if let type = fileType, type.starts(with: "image/") { return true }
        if let url = imageUrl ?? fileUrl { return url.lowercased().contains(".jpg") || url.lowercased().contains(".png") || url.lowercased().contains(".jpeg") }
        return false
    }
    var body: some View {
        if let link = fileUrl ?? imageUrl, let url = URL(string: link) {
            Group {
                if isImage {
                    AsyncImage(url: url) { image in image.resizable().scaledToFit().cornerRadius(12) } placeholder: { ZStack { Color.gray.opacity(0.1); ProgressView() }.frame(height: 200) }
                } else {
                    Link(destination: url) {
                        HStack(spacing: 12) {
                            ZStack { Circle().fill(Color.blue.opacity(0.1)).frame(width: 40, height: 40); Image(systemName: "doc.text.fill").foregroundColor(.blue) }
                            VStack(alignment: .leading, spacing: 2) {
                                Text(fileName ?? "Attachment").font(.system(size: 14, weight: .semibold)).foregroundColor(.primary).lineLimit(1)
                                Text("Toc para descargar").font(.caption).foregroundColor(.blue)
                            }
                            Spacer(); Image(systemName: "arrow.down.circle.fill").font(.title2).foregroundColor(.blue.opacity(0.8))
                        }
                        .padding(12).background(Color.white).cornerRadius(12).shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                    }
                }
            }
            .padding(.top, 8)
        }
    }
}

struct BroadcastPhotoPicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController(); picker.delegate = context.coordinator; return picker
    }
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: BroadcastPhotoPicker; init(_ parent: BroadcastPhotoPicker) { self.parent = parent }
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[.originalImage] as? UIImage { parent.image = uiImage }; picker.dismiss(animated: true)
        }
    }
}

struct ReplyView: View {
    let broadcastItem: BroadcastItem
    @ObservedObject var viewModel: BroadcastListViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var replyText = ""
    @State private var isSendingReply = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Reply to Wyman:").font(.caption).foregroundColor(.gray)
                    
                    Text(broadcastItem.text)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    
                }.padding(.horizontal).padding(.top)
                
                TextEditor(text: $replyText).frame(height: 150).padding(4).background(Color(UIColor.secondarySystemBackground)).cornerRadius(12).padding(.horizontal)
                
                Spacer()
                
                if isSendingReply { ProgressView() } else {
                    Button(action: {
                        isSendingReply = true
                        viewModel.sendReply(broadcastId: broadcastItem.id, replyText: replyText) { success in
                            isSendingReply = false; if success { presentationMode.wrappedValue.dismiss() }
                        }
                    }) {
                        Text("Send Reply").font(.headline).foregroundColor(.white).frame(maxWidth: .infinity).padding().background(replyText.isEmpty ? Color.gray : Color.blue).cornerRadius(15)
                    }.padding().disabled(replyText.isEmpty)
                }
            }
            .navigationTitle("Reply").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .navigationBarLeading) { Button("Cancel") { presentationMode.wrappedValue.dismiss() } } }
        }
    }
}

// 🔥🔥 NUEVA VISTA: BUZÓN DE RESPUESTAS 🔥🔥
struct ReplyItem: Identifiable, Decodable {
    @DocumentID var id: String?
    let text: String
    let senderName: String
    let timestamp: Date?
}

struct RepliesListView: View {
    let broadcastId: String
    @State private var replies: [ReplyItem] = []
    @State private var isLoading = true
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView()
            } else if replies.isEmpty {
                VStack(spacing: 15) {
                    Image(systemName: "tray.fill")
                        .font(.largeTitle)
                        .foregroundColor(.gray)
                    Text("Sin respuestas aún")
                        .foregroundColor(.gray)
                }
            } else {
                List(replies) { reply in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(reply.senderName)
                                .font(.headline)
                                .foregroundColor(.blue)
                            Spacer()
                            if let date = reply.timestamp {
                                Text(date, style: .time)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                        Text(reply.text)
                            .font(.body)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Inbox")
        .onAppear {
            fetchReplies()
        }
    }
    
    func fetchReplies() {
        Firestore.firestore().collection("broadcasts").document(broadcastId).collection("replies")
            .order(by: "timestamp", descending: true)
            .getDocuments { snap, error in
                Task { @MainActor in
                    self.isLoading = false
                    guard let docs = snap?.documents else { return }
                    self.replies = docs.compactMap { doc -> ReplyItem? in
                        try? doc.data(as: ReplyItem.self)
                    }
                }
            }
    }
}
