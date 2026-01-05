//
//  AtlasDocument.swift
//  Atlerts
//
//  Created by Gabriel Rosales Montes  on 04/01/26.
//
import Foundation
import FirebaseFirestore

struct AtlasDocument: Identifiable, Codable {
    @DocumentID var id: String?
    let title: String
    let url: String
    let filename: String?
    let timestamp: Timestamp?
    
    // Agrega esto para que no falle si falta algún dato extra
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case url
        case filename
        case timestamp
    }
}
