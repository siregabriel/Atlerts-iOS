//
//  ChatView.swift
//  Atlerts
//
//  Created by Gabriel Rosales Montes  on 03/01/26.
//
import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import Combine

// 1. MODELO DEL MENSAJE
struct ChatMessage: Identifiable, Codable {
    @DocumentID var id: String?
    let fromId: String
    let toId: String
    let text: String
    let timestamp: Date
}

// 2. VIEW MODEL
class ChatScreenViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var text = ""
    
    let user: AtlertsUser
    private var db = Firestore.firestore()
    
    init(user: AtlertsUser) {
        self.user = user
        fetchMessages()
    }
    
    func fetchMessages() {
        // CORRECCIÓN 1: Usamos 'toId' en el guard y lo usamos abajo para que no de warning
        guard let fromId = Auth.auth().currentUser?.uid, let toId = user.uid else { return }
        
        // Usamos toId directamente en lugar de volver a llamar a user.uid
        let conversationId = fromId < toId ? "\(fromId)_\(toId)" : "\(toId)_\(fromId)"
        
        db.collection("conversations")
            .document(conversationId)
            .collection("messages")
            .order(by: "timestamp", descending: false)
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else { return }
                self.messages = documents.compactMap { try? $0.data(as: ChatMessage.self) }
            }
    }
    
    func sendMessage() {
        // CORRECCIÓN 2: Lo mismo aquí, limpiamos la variable no usada
        guard let fromId = Auth.auth().currentUser?.uid, let toId = user.uid, !text.isEmpty else { return }
        
        let conversationId = fromId < toId ? "\(fromId)_\(toId)" : "\(toId)_\(fromId)"
        
        let msg = ChatMessage(fromId: fromId, toId: toId, text: text, timestamp: Date())
        
        do {
            try db.collection("conversations")
                .document(conversationId)
                .collection("messages")
                .addDocument(from: msg)
            
            self.text = ""
        } catch {
            print("Error enviando mensaje: \(error)")
        }
    }
}

// 3. VISTA DEL CHAT
struct ChatView: View {
    let user: AtlertsUser
    @StateObject var viewModel: ChatScreenViewModel
    
    init(user: AtlertsUser) {
        self.user = user
        self._viewModel = StateObject(wrappedValue: ChatScreenViewModel(user: user))
    }
    
    var body: some View {
        VStack {
            // LISTA DE MENSAJES
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.messages) { message in
                            MessageRow(message: message)
                        }
                    }
                    .padding()
                }
                // CORRECCIÓN 3: Sintaxis compatible con iOS 17 para quitar el warning amarillo
                // Usamos "old, new in" (o _, _ in)
                .onChange(of: viewModel.messages.count) { _, _ in
                    if let lastId = viewModel.messages.last?.id {
                        withAnimation {
                            proxy.scrollTo(lastId, anchor: .bottom)
                        }
                    }
                }
            }
            
            // ÁREA DE TEXTO
            HStack {
                TextField("Escribe un mensaje...", text: $viewModel.text)
                    .padding(12)
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(20)
                
                Button(action: viewModel.sendMessage) {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(.white)
                        .padding(10)
                        .background(Color.blue)
                        .clipShape(Circle())
                }
                .disabled(viewModel.text.isEmpty)
            }
            .padding()
            .background(Color.white)
        }
        .navigationTitle(user.name ?? "Chat")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(UIColor.systemGroupedBackground))
    }
}

// 4. BURBUJA DE MENSAJE
struct MessageRow: View {
    let message: ChatMessage
    let currentUid = Auth.auth().currentUser?.uid
    
    var body: some View {
        HStack {
            if message.fromId == currentUid {
                Spacer()
                Text(message.text)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(16)
                    .mask(RoundedRectangle(cornerRadius: 16, style: .continuous))
            } else {
                Text(message.text)
                    .foregroundColor(.black)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                Spacer()
            }
        }
    }
}
