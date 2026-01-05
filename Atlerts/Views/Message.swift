//
//  Message.swift
//  Atlerts
//
//  Created by Gabriel Rosales Montes  on 03/01/26.
//
import Foundation
// Borramos 'import FirebaseFirestore' y 'FirebaseFirestoreSwift' de aquí
// para evitar conflictos.

struct Message: Identifiable, Codable {
    let id: String          // Usamos un String normal en vez de @DocumentID
    let text: String
    let senderId: String
    let timestamp: Date
    
    // Campos opcionales para el perfil (que agregamos hace poco)
    var userPhotoURL: String?
    var userName: String?
    var imageURL: String? // Si tiene texto es nil, si es foto tiene el link
}
