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

// FORMA PERSONALIZADA PARA EL PICO DEL GLOBO
struct ChatBubbleShape: Shape {
    let isCurrentUser: Bool
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: [
                .topLeft,
                .topRight,
                isCurrentUser ? .bottomLeft : .bottomRight
            ],
            cornerRadii: CGSize(width: 16, height: 16)
        )
        return Path(path.cgPath)
    }
}

// 3. VISTA DEL CHAT
struct ChatView: View {
    let user: AtlertsUser
    
    @StateObject var viewModel = ChatViewModel()
    @Environment(\.presentationMode) var presentationMode
    
    // 🔥 NUEVO: Variable para controlar la navegación manual
    @State private var showProfile = false
    
    var body: some View {
        ZStack {
            // 1. Fondo Blanco Absoluto
            Color.white.ignoresSafeArea()
            
            // 🔥 TRUCO: Enlace invisible que se activa con la variable 'showProfile'
            // Esto soluciona que el clic en la barra no funcione.
            NavigationLink(destination: PublicProfileView(targetUser: user), isActive: $showProfile) {
                EmptyView()
            }
            .hidden() // Lo escondemos, solo sirve de puente
            
            VStack(spacing: 0) {
                
                // LISTA DE MENSAJES
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.messages) { message in
                                MessageRow(message: message)
                                    .id(message.id)
                            }
                            
                            Color.clear
                                .frame(height: 1)
                                .id("BOTTOM")
                        }
                        .padding()
                    }
                    .onAppear {
                        viewModel.configureChat(recipient: user)
                        scrollToBottom(proxy: proxy)
                    }
                    .onChange(of: viewModel.messages.count) { _, _ in
                        scrollToBottom(proxy: proxy, animated: true)
                    }
                    .onReceive(Publishers.keyboardHeight) { _ in
                        scrollToBottom(proxy: proxy, animated: true)
                    }
                }
                .onTapGesture {
                    UIApplication.shared.endEditing()
                }
                
                // 2. BARRA DE ESCRITURA
                VStack(spacing: 0) {
                    Divider()
                    HStack(spacing: 12) {
                        ZStack(alignment: .leading) {
                            if viewModel.newMessageText.isEmpty {
                                Text("Escribe un mensaje...")
                                    .foregroundColor(.black)
                                    .padding(.leading, 18)
                            }
                            TextField("", text: $viewModel.newMessageText)
                                .foregroundColor(.black)
                                .padding(12)
                                .padding(.leading, 6)
                                .background(Color(white: 0.95))
                                .cornerRadius(20)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                )
                        }
                        
                        Button(action: {
                            viewModel.sendMessage()
                        }) {
                            Image(systemName: "paperplane.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                                .padding(10)
                                .background(Color.blue)
                                .clipShape(Circle())
                        }
                        .disabled(viewModel.newMessageText.isEmpty)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                    .background(Color.white)
                }
            }
        }
        // 🔥 BARRA SUPERIOR INTERACTIVA (Ahora usa un Botón real)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                // Usamos un BUTTON en lugar de NavigationLink directo
                Button(action: {
                    showProfile = true // Esto activa el enlace invisible del ZStack
                }) {
                    HStack(spacing: 8) {
                        // Avatar
                        if let urlStr = user.profileImageURL, let url = URL(string: urlStr) {
                            AsyncImage(url: url) { phase in
                                if let image = phase.image {
                                    image.resizable().scaledToFill()
                                } else {
                                    Color.gray.opacity(0.3)
                                }
                            }
                            .frame(width: 32, height: 32)
                            .clipShape(Circle())
                        } else {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .frame(width: 32, height: 32)
                                .foregroundColor(.gray)
                        }
                        
                        // Nombre
                        Text(user.name ?? "Chat")
                            .font(.headline)
                            .foregroundColor(.primary)
                    }
                }
            }
        }
        .preferredColorScheme(.light)
    }
    
    func scrollToBottom(proxy: ScrollViewProxy, animated: Bool = false) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if animated {
                withAnimation {
                    proxy.scrollTo("BOTTOM", anchor: .bottom)
                }
            } else {
                proxy.scrollTo("BOTTOM", anchor: .bottom)
            }
        }
    }
}

// 4. BURBUJA DE MENSAJE
struct MessageRow: View {
    let message: Message
    let currentUid = Auth.auth().currentUser?.uid
    
    var body: some View {
        HStack(alignment: .bottom) {
            if message.senderId == currentUid {
                Spacer()
                Text(message.text)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.blue)
                    .clipShape(ChatBubbleShape(isCurrentUser: true))
            } else {
                Text(message.text)
                    .foregroundColor(.black)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color(white: 0.90))
                    .clipShape(ChatBubbleShape(isCurrentUser: false))
                Spacer()
            }
        }
    }
}

// EXTENSIÓN PARA DETECTAR EL TECLADO
extension Publishers {
    static var keyboardHeight: AnyPublisher<CGFloat, Never> {
        let willShow = NotificationCenter.default.publisher(for: UIApplication.keyboardWillShowNotification)
            .map { $0.keyboardFrameEndUserInfoKey ?? .zero }
            .map { $0.height }
        
        let willHide = NotificationCenter.default.publisher(for: UIApplication.keyboardWillHideNotification)
            .map { _ in CGFloat(0) }
        
        return MergeMany(willShow, willHide)
            .eraseToAnyPublisher()
    }
}

extension Notification {
    var keyboardFrameEndUserInfoKey: CGRect? {
        return (userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
    }
}
