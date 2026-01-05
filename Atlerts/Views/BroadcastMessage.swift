//
//  BroadcastMessage.swift
//  Atlerts
//
//  Created by Gabriel Rosales Montes  on 04/01/26.
//
import Foundation
import FirebaseFirestore

struct BroadcastMessage: Identifiable, Codable {
    @DocumentID var id: String?
    let text: String
    let senderName: String?
    let timestamp: Timestamp?
    let role: String?
    var imageURL: String? // <--- NUEVO CAMPO (Opcional)
}
