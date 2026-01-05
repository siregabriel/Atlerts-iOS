//
//  DirectoryViewModel.swift
//  Atlerts
//
//  Created by Gabriel Rosales Montes  on 03/01/26.
//
import SwiftUI
import Combine
import FirebaseFirestore
import FirebaseAuth

class DirectoryViewModel: ObservableObject {
    @Published var users: [AppUser] = []
    @Published var isLoading = false
    
    private var db = Firestore.firestore()
    
    init() {
        fetchUsers()
    }
    
    func fetchUsers() {
        guard let myUID = Auth.auth().currentUser?.uid else { return }
        isLoading = true
        
        db.collection("users").getDocuments { snapshot, error in
            self.isLoading = false
            if let error = error {
                print("Error cargando usuarios: \(error)")
                return
            }
            
            guard let docs = snapshot?.documents else { return }
            
            // Mapeamos los documentos a nuestro modelo AppUser
            self.users = docs.compactMap { doc -> AppUser? in
                let data = doc.data()
                let uid = data["uid"] as? String ?? ""
                
                // FILTRO: No mostrarme a mí mismo en la lista
                if uid == myUID { return nil }
                
                return AppUser(
                    id: doc.documentID,
                    uid: uid,
                    name: data["name"] as? String ?? "Usuario",
                    email: data["email"] as? String ?? "",
                    profileImageURL: data["profileImageURL"] as? String ?? "",
                    role: data["role"] as? String ?? "client"
                )
            }
        }
    }
}
