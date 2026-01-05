//
//  RepositoryFile.swift
//  Atlerts
//
//  Created by Gabriel Rosales Montes  on 03/01/26.
//
import Foundation
import FirebaseFirestore

struct RepositoryFile: Identifiable, Codable {
    @DocumentID var id: String?
    let name: String      // Nombre bonito "Contrato"
    let url: String       // Link de descarga
    let type: String      // pdf, xls, img
    let size: String      // "1.2 MB"
    let assignedTo: String
    let createdAt: Date
}
