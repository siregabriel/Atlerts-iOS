//
//  AtlertsUser.swift
//  Atlerts
//
//  Created by Gabriel Rosales Montes  on 03/01/26.
//
import Foundation
import FirebaseFirestore

struct AtlertsUser: Identifiable, Codable {
    @DocumentID var id: String?
    let uid: String?
    let name: String?
    let email: String?
    let role: String?
    var profileImageURL: String?
    let community: String? // <--- ESTA ES LA LÍNEA CLAVE QUE FALTABA
}
