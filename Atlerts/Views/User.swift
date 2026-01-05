//
//  User.swift
//  Atlerts
//
//  Created by Gabriel Rosales Montes  on 03/01/26.
//
import Foundation
import FirebaseFirestore

struct AppUser: Identifiable, Codable { // 👈 NO cambies el nombre
    @DocumentID var id: String?
    let uid: String
    let name: String
    let email: String
    
    // 👇 CAMBIO 1: De 'let' a 'var' (para poder editarla)
    // 👇 CAMBIO 2: Agrega '?' al final (para que sea opcional)
    var profileImageURL: String?
    
    let role: String
    
    // 👇 CAMBIO 3: Agrega esto (tu ViewModel lo busca, si no está, falla)
    var community: String?
}
