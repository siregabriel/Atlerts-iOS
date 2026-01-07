//
//  BroadcastViewModel.swift
//  Atlerts
//
//  Created by Gabriel Rosales Montes  on 03/01/26.
//
import Foundation
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage // Necesario para subir fotos
import UIKit
import Combine
import AudioToolbox

class BroadcastViewModel: ObservableObject {
    @Published var broadcasts: [BroadcastMessage] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var db = Firestore.firestore()
    private var storage = Storage.storage()
    
    init() {
        fetchBroadcasts()
    }
    
    func fetchBroadcasts() {
        isLoading = true
        db.collection("broadcasts")
            .order(by: "timestamp", descending: true)
            .addSnapshotListener { snapshot, error in
                self.isLoading = false
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    return
                }
                guard let documents = snapshot?.documents else { return }
                self.broadcasts = documents.compactMap { doc -> BroadcastMessage? in
                    try? doc.data(as: BroadcastMessage.self)
                }
            }
    }
    
    // --- FUNCIÓN MAESTRA: ENVIAR CON O SIN FOTO ---
    func enviarBroadcast(texto: String, imagen: UIImage?) {
        guard !texto.isEmpty else { return }
        self.isLoading = true
        
        if let imagen = imagen {
            // 1. Si hay imagen, la subimos primero
            subirImagenBroadcast(imagen) { urlDescarga in
                // 2. Luego guardamos el mensaje con el link
                self.guardarEnFirestore(texto: texto, imageURL: urlDescarga)
            }
        } else {
            // Si no hay imagen, guardamos directo (url es nil)
            guardarEnFirestore(texto: texto, imageURL: nil)
        }
    }
    
    private func subirImagenBroadcast(_ image: UIImage, completion: @escaping (String?) -> Void) {
        // Creamos un nombre único para la foto
        let filename = UUID().uuidString + ".jpg"
        let ref = storage.reference().child("broadcast_images/\(filename)")
        
        guard let imageData = image.jpegData(compressionQuality: 0.5) else {
            completion(nil)
            return
        }
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        ref.putData(imageData, metadata: metadata) { _, error in
            if let error = error {
                print("Error subiendo imagen: \(error)")
                completion(nil)
                return
            }
            ref.downloadURL { url, _ in
                completion(url?.absoluteString)
            }
        }
    }
    
    private func guardarEnFirestore(texto: String, imageURL: String?) {
        var data: [String: Any] = [
            "text": texto,
            "senderName": "Admin (App)",
            "timestamp": FieldValue.serverTimestamp(),
            "role": "moderator"
        ]
        
        // Si hay foto, la agregamos al paquete
        if let url = imageURL {
            data["imageURL"] = url
        }
        
        db.collection("broadcasts").addDocument(data: data) { error in
            self.isLoading = false // Terminamos de cargar
            if let error = error {
                self.errorMessage = "Error: \(error.localizedDescription)"
            } else {
                print("¡Enviado con éxito!")
            }
        }
    }
    
    func borrarBroadcast(id: String) {
        db.collection("broadcasts").document(id).delete()
    }
}
