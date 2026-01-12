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
    var otherUserId: String = ""
    
    // CONFIGURAR EL CHAT
    func configureChat(recipient: AtlertsUser?) {
        guard let myUID = Auth.auth().currentUser?.uid else { return }
        
        if let otherUser = recipient {
            self.otherUserName = otherUser.name ?? "Usuario"
            self.otherUserPhoto = otherUser.profileImageURL ?? ""
            if let uid = otherUser.uid {
                self.otherUserId = uid
            }
            
            if let otherID = otherUser.uid {
                let uids = [myUID, otherID].sorted()
                self.chatRoomId = uids.joined(separator: "_")
            }
            
        } else {
            self.otherUserName = "Soporte Técnico"
            self.chatRoomId = myUID
            self.otherUserId = "support_agent"
        }
        
        fetchMessages()
        // Intentamos marcar como leídos inmediatamente al entrar
        markMessagesAsRead()
    }
    
    func fetchMessages() {
        self.messages = []
        listener?.remove()
        
        if chatRoomId.isEmpty { return }
        
        print("🎧 Escuchando chat en sala: \(chatRoomId)")
        
        listener = db.collection("chats").document(chatRoomId).collection("messages")
            .order(by: "timestamp", descending: false)
            .addSnapshotListener { [weak self] querySnapshot, error in
                guard let self = self else { return }
                guard let documents = querySnapshot?.documents else { return }
                
                // 1. Cargamos mensajes
                self.messages = documents.compactMap { doc -> Message? in
                    let data = doc.data()
                    let timestamp = (data["timestamp"] as? Timestamp)?.dateValue() ?? Date()
                    
                    return Message(
                        id: doc.documentID,
                        text: data["text"] as? String ?? "",
                        senderId: data["senderId"] as? String ?? "",
                        timestamp: timestamp,
                        userPhotoURL: data["userPhotoURL"] as? String ?? "",
                        userName: data["userName"] as? String ?? "Usuario",
                        imageURL: data["imageURL"] as? String
                    )
                }
                
                // 🔥 CORRECCIÓN CRÍTICA: Marcar como leído INMEDIATAMENTE (Sin esperar 0.1s)
                self.markMessagesAsRead()
                
                // El truco del refresco de UI lo dejamos aparte, pero ya no bloquea la lectura
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.newMessageText = " "
                    self.newMessageText = ""
                }
            }
    }
    
    func sendMessage() {
        guard let myUID = Auth.auth().currentUser?.uid else { return }
        if newMessageText.trimmingCharacters(in: .whitespaces).isEmpty { return }
        
        let textToSend = newMessageText
        newMessageText = ""
        
        db.collection("users").document(myUID).getDocument { [weak self] snapshot, _ in
            guard let self = self else { return }
            let userData = snapshot?.data()
            let myName = userData?["name"] as? String ?? "Usuario"
            let myPhoto = userData?["profileImageURL"] as? String ?? ""
            
            let data: [String: Any] = [
                "text": textToSend,
                "senderId": myUID,
                "timestamp": Timestamp(date: Date()),
                "userName": myName,
                "userPhotoURL": myPhoto,
                "isRead": false,
                "toId": self.otherUserId
            ]
            
            self.db.collection("chats").document(self.chatRoomId).collection("messages").addDocument(data: data)
        }
    }
    
    func sendImageMessage(image: UIImage) {
        guard (Auth.auth().currentUser?.uid) != nil else { return }
        guard let imageData = image.jpegData(compressionQuality: 0.5) else { return }
        
        let filename = UUID().uuidString
        let ref = Storage.storage().reference().child("chat_photos/\(filename).jpg")
        
        ref.putData(imageData, metadata: nil) { _, error in
            if let error = error { print("Error upload: \(error)"); return }
            
            ref.downloadURL { url, _ in
                guard let url = url else { return }
                self.saveMessageToFirestore(text: "📷 Imagen", imageURL: url.absoluteString)
            }
        }
    }
    
    private func saveMessageToFirestore(text: String, imageURL: String? = nil) {
        guard let myUID = Auth.auth().currentUser?.uid else { return }
        
        db.collection("users").document(myUID).getDocument { [weak self] snapshot, _ in
            guard let self = self else { return }
            let userData = snapshot?.data()
            let myName = userData?["name"] as? String ?? "Usuario"
            let myPhoto = userData?["profileImageURL"] as? String ?? ""
            
            var data: [String: Any] = [
                "text": text,
                "senderId": myUID,
                "timestamp": Timestamp(date: Date()),
                "userName": myName,
                "userPhotoURL": myPhoto,
                "isRead": false,
                "toId": self.otherUserId
            ]
            
            if let img = imageURL { data["imageURL"] = img }
            
            self.db.collection("chats").document(self.chatRoomId).collection("messages").addDocument(data: data)
        }
    }
    
    func markMessagesAsRead() {
        guard let currentUid = Auth.auth().currentUser?.uid else { return }
        if self.otherUserId.isEmpty { return }
        
        let ref = db.collection("chats").document(self.chatRoomId).collection("messages")
        
        ref.getDocuments { [weak self] snapshot, error in
            guard self != nil else { return }
            guard let documents = snapshot?.documents else { return }
            
            for doc in documents {
                let data = doc.data()
                let senderId = (data["fromId"] as? String) ?? (data["senderId"] as? String) ?? ""
                
                // Solo marcamos si el mensaje NO es mío y NO está leído
                if senderId != currentUid {
                    let isRead = data["isRead"] as? Bool ?? false
                    if !isRead {
                        // Lo marcamos en silencio (sin print para no saturar consola)
                        doc.reference.updateData(["isRead": true])
                    }
                }
            }
        }
    }
    
    deinit {
        print("☠️ ChatViewModel liberado")
        listener?.remove()
    }
}
