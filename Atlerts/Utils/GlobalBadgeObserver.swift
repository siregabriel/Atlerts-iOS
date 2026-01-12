//
//  GlobalBadgeObserver.swift
//  Atlerts
//
//  Created by Gabriel Rosales Montes  on 09/01/26.
//
import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import Combine

class GlobalBadgeObserver: ObservableObject {
    @Published var totalUnread: Int = 0
    private var listener: ListenerRegistration?
    private var authStateListener: AuthStateDidChangeListenerHandle?
    
    init() {
        // En lugar de llamar directo, escuchamos el estado de autenticación
        startAuthListener()
    }
    
    func startAuthListener() {
        // Esto se ejecuta automáticamente cada vez que el usuario hace Login o la app inicia y recupera la sesión
        authStateListener = Auth.auth().addStateDidChangeListener { [weak self] (_, user) in
            if let user = user {
                print("👤 GlobalBadgeObserver: Usuario detectado (\(user.uid)). Iniciando listener...")
                self?.listenToAllUnreadMessages(userId: user.uid)
            } else {
                print("👤 GlobalBadgeObserver: No hay usuario. Limpiando badge.")
                self?.totalUnread = 0
                self?.stopListener()
            }
        }
    }
    
    func listenToAllUnreadMessages(userId: String) {
        // Prevenimos duplicar listeners si ya hay uno corriendo
        stopListener()
        
        let query = Firestore.firestore().collectionGroup("messages")
            .whereField("toId", isEqualTo: userId)
            .whereField("isRead", isEqualTo: false)
        
        listener = query.addSnapshotListener { [weak self] snapshot, error in
            if let error = error {
                print("⚠️ Error Global Badge: \(error.localizedDescription)")
                return
            }
            
            guard let documents = snapshot?.documents else {
                self?.totalUnread = 0
                return
            }
            
            DispatchQueue.main.async {
                // Actualizamos el contador oficial
                self?.totalUnread = documents.count
                print("🔴 Global Badge Actualizado: \(documents.count) mensajes sin leer.")
            }
        }
    }
    
    func stopListener() {
        listener?.remove()
        listener = nil
    }
    
    deinit {
        stopListener()
        if let authStateListener = authStateListener {
            Auth.auth().removeStateDidChangeListener(authStateListener)
        }
    }
}
