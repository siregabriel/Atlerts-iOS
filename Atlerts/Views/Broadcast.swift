//
//  Broadcast.swift
//  Atlerts
//
//  Created by Gabriel Rosales Montes  on 03/01/26.
//
import Foundation
import FirebaseFirestore

struct Broadcast: Identifiable, Codable {
    @DocumentID var id: String?
    let text: String
    let senderName: String
    let timestamp: Date
    // Opcional: role para saber quién lo envió
}
