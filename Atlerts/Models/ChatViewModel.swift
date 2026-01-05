//
//  ChatViewModel.swift
//  Atlerts
//
//  Created by Gabriel Rosales Montes  on 03/01/26.
//
import Foundation
import UIKit
import Combine
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage

class ChatViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var newMessageText = ""
    
    private var db = Firestore.firestore()
    private var listener: ListenerRegistration?
    
    // Variables para saber con quién hablamos
    var chatRoomId: String = ""
    var otherUserName: String = "Messages"
    var otherUserPhoto: String = ""
    
    // CONFIGURAR EL CHAT (Esta es la clave)
    // Si 'recipient' es nil, asumimos que es el chat de Soporte
    func configureChat(recipient: AppUser?) {
        guard let myUID = Auth.auth().currentUser?.uid else { return }
        
        if let otherUser = recipient {
            // --- CHAT PRIVADO CON OTRO USUARIO ---
            self.otherUserName = otherUser.name
            self.otherUserPhoto = otherUser.profileImageURL ?? ""
            
            // Generamos un ID único ordenando los UIDs (Para que A-B sea igual a B-A)
            let uids = [myUID, otherUser.uid].sorted()
            self.chatRoomId = uids.joined(separator: "_") // Ejemplo: "abc_xyz"
            
        } else {
            // --- CHAT DE SOPORTE (Lógica anterior) ---
            self.otherUserName = "Soporte Técnico"
            self.chatRoomId = myUID // Usamos mi propio ID como sala de soporte
        }
        
        // Empezar a escuchar en la sala correcta
        fetchMessages()
    }
    
    // EN ChatViewModel.swift

    func fetchMessages() {
            // Limpiamos mensajes viejos al cambiar de chat
            self.messages = []
            listener?.remove()
            
            // Si no hay sala configurada, no hacemos nada
            if chatRoomId.isEmpty { return }
            
            print("🎧 Escuchando chat en sala: \(chatRoomId)")
            
            listener = db.collection("chats").document(chatRoomId).collection("messages")
                .order(by: "timestamp", descending: false)
                .addSnapshotListener { querySnapshot, error in
                    guard let documents = querySnapshot?.documents else { return }
                    
                    self.messages = documents.compactMap { doc -> Message? in
                        let data = doc.data()
                        let timestamp = (data["timestamp"] as? Timestamp)?.dateValue() ?? Date()
                        
                        return Message(
                            id: doc.documentID,
                            text: data["text"] as? String ?? "",
                            senderId: data["senderId"] as? String ?? "",
                            timestamp: timestamp,
                            // 👇 AQUÍ ESTABA EL ERROR: Agregamos ?? "" para asegurar que sea String
                            userPhotoURL: data["userPhotoURL"] as? String ?? "",
                            // 👇 AQUÍ TAMBIÉN: Agregamos un valor por defecto
                            userName: data["userName"] as? String ?? "Usuario",
                            
                            // Este lo dejamos opcional porque la imagen no siempre existe
                            imageURL: data["imageURL"] as? String
                        )
                    }
                    
                    // Auto-scroll al final
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        self.newMessageText = " " // Truco para forzar refresco de UI
                        self.newMessageText = ""
                    }
                }
        }
    
    func sendMessage() {
        guard let myUID = Auth.auth().currentUser?.uid else { return }
        if newMessageText.trimmingCharacters(in: .whitespaces).isEmpty { return }
        
        let textToSend = newMessageText
        newMessageText = ""
        
        // Buscamos mis datos actuales para enviarlos con el mensaje
        db.collection("users").document(myUID).getDocument { snapshot, _ in
            let userData = snapshot?.data()
            let myName = userData?["name"] as? String ?? "Usuario"
            let myPhoto = userData?["profileImageURL"] as? String ?? ""
            
            let data: [String: Any] = [
                "text": textToSend,
                "senderId": myUID,
                "timestamp": Timestamp(date: Date()),
                "userName": myName,
                "userPhotoURL": myPhoto
            ]
            
            // Guardamos en la sala configurada (chatRoomId)
            self.db.collection("chats").document(self.chatRoomId).collection("messages").addDocument(data: data)
        }
    }
    
// --- 03-JAN-2026 NUEVA FUNCIÓN: ADJUNTAR FOTO ---
func sendImageMessage(image: UIImage) {
    guard (Auth.auth().currentUser?.uid) != nil else { return }

    // 1. Comprimir la imagen para que no pese mucho (calidad media 0.5)
    guard let imageData = image.jpegData(compressionQuality: 0.5) else { return }

    // 2. Crear nombre único para la foto (chat_photos/UUID.jpg)
    let filename = UUID().uuidString
    let ref = Storage.storage().reference().child("chat_photos/\(filename).jpg")

    print("⬆️ Uploading picture...")

    // 3. Subir
    ref.putData(imageData, metadata: nil) { _, error in
        if let error = error {
            print("Error uploading chat image: \(error)")
            return
        }

        // 4. Obtener el link de descarga
        ref.downloadURL { url, _ in
            guard let url = url else { return }
            self.saveMessageToFirestore(text: "📷 Imagen", imageURL: url.absoluteString)
        }
    }
}

// --- AUXILIAR: GUARDAR EN BASE DE DATOS ---
// (He movido la lógica de guardar aquí para no repetirla en texto y foto)
private func saveMessageToFirestore(text: String, imageURL: String? = nil) {
    guard let myUID = Auth.auth().currentUser?.uid else { return }

    // Buscamos mis datos de perfil para adjuntarlos
    db.collection("users").document(myUID).getDocument { snapshot, _ in
        let userData = snapshot?.data()
        let myName = userData?["name"] as? String ?? "Usuario"
        let myPhoto = userData?["profileImageURL"] as? String ?? ""

        var data: [String: Any] = [
            "text": text,
            "senderId": myUID,
            "timestamp": Timestamp(date: Date()),
            "userName": myName,
            "userPhotoURL": myPhoto
        ]

        // Si es imagen, agregamos el campo extra
        if let img = imageURL {
            data["imageURL"] = img
        }

        // Guardamos
        self.db.collection("chats").document(self.chatRoomId).collection("messages").addDocument(data: data)
        print("✅ Mensaje enviado")
    }
}

deinit {
    listener?.remove()
}
}
