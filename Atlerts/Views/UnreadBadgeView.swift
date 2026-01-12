//
//  UnreadBadgeView.swift
//  Atlerts
//
//  Created by Gabriel Rosales Montes  on 09/01/26.
//
import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct UnreadBadgeView: View {
    let targetUserId: String // ID del usuario que queremos revisar
    @State private var unreadCount: Int = 0
    
    var body: some View {
        Group {
            if unreadCount > 0 {
                ZStack {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 20, height: 20)
                    
                    Text("\(unreadCount)")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
            }
        }
        .onAppear {
            listenForUnreadMessages()
        }
    }
    
    func listenForUnreadMessages() {
        guard let currentUid = Auth.auth().currentUser?.uid else { return }
        
        // Escuchar mensajes de ESTE usuario (targetUserId) hacia MÍ (currentUid) que no estén leídos
        Firestore.firestore().collection("messages")
            .whereField("senderId", isEqualTo: targetUserId)
            .whereField("receiverId", isEqualTo: currentUid)
            .whereField("isRead", isEqualTo: false)
            .addSnapshotListener { snapshot, _ in
                // Actualizar el contador en tiempo real
                self.unreadCount = snapshot?.documents.count ?? 0
            }
    }
}
