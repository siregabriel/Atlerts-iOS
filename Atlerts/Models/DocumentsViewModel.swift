//
//  DocumentsViewModel.swift
//  Atlerts
//
//  Created by Gabriel Rosales Montes  on 04/01/26.
//
import Foundation
import FirebaseFirestore
import Combine

class DocumentsViewModel: ObservableObject {
    @Published var documents: [AtlasDocument] = []
    @Published var isLoading = false
    private var db = Firestore.firestore()
    
    func fetchDocuments() {
        isLoading = true
        // Escuchamos la colección "documents" que creaste en la Web
        db.collection("documents")
            .order(by: "timestamp", descending: true)
            .addSnapshotListener { snapshot, error in
                self.isLoading = false
                if let error = error {
                    print("Error leyendo docs: \(error.localizedDescription)")
                    return
                }
                guard let docs = snapshot?.documents else { return }
                
                self.documents = docs.compactMap { doc -> AtlasDocument? in
                    try? doc.data(as: AtlasDocument.self)
                }
            }
    }
}
