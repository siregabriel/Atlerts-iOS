//
//  Event.swift
//  Atlerts
//
//  Created by Gabriel Rosales Montes  on 05/01/26.
//
import Foundation
import FirebaseFirestore

struct Event: Identifiable, Codable {
    @DocumentID var id: String?
    var title: String
    var description: String
    var date: Date
    var location: String?
    
    // Esto es para que Swift sepa leer las fechas de Firebase correctamente
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case date
        case location
    }
}
