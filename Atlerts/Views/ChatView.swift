//
//  ChatView.swift
//  Atlerts
//
//  Created by Gabriel Rosales Montes on 03/01/26.
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
        guard let fromId = Auth.auth().currentUser?.uid, let toId = user.uid else { return }
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

// 🔥 FORMA PERSONALIZADA PARA EL PICO DEL GLOBO
struct ChatBubbleShape: Shape {
    let isCurrentUser: Bool
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: [
                .topLeft,
                .topRight,
                isCurrentUser ? .bottomLeft : .bottomRight // Redondeamos la esquina contraria al pico
            ],
            cornerRadii: CGSize(width: 16, height: 16)
        )
        return Path(path.cgPath)
    }
}

// 3. VISTA DEL CHAT
struct ChatView: View {
    let user: AtlertsUser
    @StateObject var viewModel: ChatScreenViewModel
    @Environment(\.presentationMode) var presentationMode
    
    init(user: AtlertsUser) {
        self.user = user
        self._viewModel = StateObject(wrappedValue: ChatScreenViewModel(user: user))
    }
    
    var body: some View {
        ZStack {
            // 1. Fondo Blanco Absoluto
            Color.white.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header manual para asegurar estilo
                /* Nota: Como usamos navigationBarTitleDisplayMode, el sistema pone el header.
                   Si prefieres uno custom, avísame. Por ahora confiamos en el nativo pero forzado a light. */
                
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
                    .onChange(of: viewModel.messages.count) { _, _ in
                        if let lastId = viewModel.messages.last?.id {
                            withAnimation { proxy.scrollTo(lastId, anchor: .bottom) }
                        }
                    }
                }
                
                // 2. BARRA DE ESCRITURA (Diseño arreglado)
                VStack(spacing: 0) {
                    Divider() // Línea separadora sutil
                    HStack(spacing: 12) {
                        // Campo de texto
                        ZStack(alignment: .leading) {
                            if viewModel.text.isEmpty {
                                Text("Escribe un mensaje...")
                                    .foregroundColor(.black) // Placeholder GRIS
                                    .padding(.leading, 18)
                            }
                            TextField("", text: $viewModel.text)
                                .foregroundColor(.black) // Texto que escribes NEGRO
                                .padding(12)
                                .padding(.leading, 6)
                                // 🔥 AQUI ESTABA EL ERROR: Usamos un gris fijo manual, no de sistema
                                .background(Color(white: 0.95))
                                .cornerRadius(20)
                                // Marco sutil opcional
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                )
                        }
                        
                        // Botón Enviar
                        Button(action: viewModel.sendMessage) {
                            Image(systemName: "paperplane.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                                .padding(10)
                                .background(Color.blue)
                                .clipShape(Circle())
                        }
                        .disabled(viewModel.text.isEmpty)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                    .background(Color.white) // Fondo de la barra BLANCO
                }
            }
        }
        .navigationTitle(user.name ?? "Chat")
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.light) // Fuerza modo claro (Textos negros) en toda la pantalla
    }
}

// 4. BURBUJA DE MENSAJE (Con pico de diálogo)
struct MessageRow: View {
    let message: ChatMessage
    let currentUid = Auth.auth().currentUser?.uid
    
    var body: some View {
        HStack(alignment: .bottom) { // Alineamos abajo para que los picos coincidan
            if message.fromId == currentUid {
                // --- MI MENSAJE (Derecha) ---
                Spacer()
                Text(message.text)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.blue)
                    // 🔥 Forma con pico a la derecha
                    .clipShape(ChatBubbleShape(isCurrentUser: true))
            } else {
                // --- OTRO MENSAJE (Izquierda) ---
                Text(message.text)
                    .foregroundColor(.black) // Texto Negro
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    // 🔥 Color Gris Claro Fijo (Color(white: 0.9))
                    .background(Color(white: 0.90))
                    // 🔥 Forma con pico a la izquierda
                    .clipShape(ChatBubbleShape(isCurrentUser: false))
                Spacer()
            }
        }
    }
}
