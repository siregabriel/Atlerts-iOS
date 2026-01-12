//
//  DirectoryView.swift
//  Atlerts
//
//  Created by Gabriel Rosales Montes on 03/01/26.
//
import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import Combine

// 1. VIEW MODEL
final class DirectoryListViewModel: ObservableObject {
    @Published var users: [AtlertsUser] = []
    @Published var isLoading = false
    @Published var searchText: String = ""
    
    private var db = Firestore.firestore()
    
    var filteredUsers: [AtlertsUser] {
        if searchText.isEmpty {
            return users
        } else {
            return users.filter { user in
                let nameMatch = user.name?.localizedCaseInsensitiveContains(searchText) ?? false
                let communityMatch = user.community?.localizedCaseInsensitiveContains(searchText) ?? false
                return nameMatch || communityMatch
            }
        }
    }
    
    func fetchUsers() {
        isLoading = true
        db.collection("users").order(by: "name").addSnapshotListener { snap, error in
            self.isLoading = false
            guard let documents = snap?.documents else { return }
            self.users = documents.compactMap { doc -> AtlertsUser? in
                return try? doc.data(as: AtlertsUser.self)
            }
        }
    }
}

// 2. VISTA
struct DirectoryView: View {
    @StateObject var viewModel = DirectoryListViewModel()
    let currentUid = Auth.auth().currentUser?.uid
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.systemGroupedBackground).ignoresSafeArea()
                
                VStack(spacing: 0) {
                    
                    // BARRA DE BÚSQUEDA
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        
                        TextField("Search users...", text: $viewModel.searchText)
                            .foregroundColor(.primary)
                        
                        if !viewModel.searchText.isEmpty {
                            Button(action: {
                                viewModel.searchText = ""
                                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding(10)
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(10)
                    .padding(.horizontal)
                    .padding(.bottom, 10)
                    .padding(.top, 10)
                    
                    // ESTADOS
                    if viewModel.isLoading {
                        Spacer()
                        ProgressView()
                        Spacer()
                    } else if viewModel.filteredUsers.isEmpty {
                        Spacer()
                        VStack(spacing: 10) {
                            Image(systemName: "magnifyingglass")
                                .font(.largeTitle)
                                .foregroundColor(.gray)
                            Text("No se encontraron usuarios")
                                .foregroundColor(.gray)
                        }
                        Spacer()
                    } else {
                        // LISTA
                        List(viewModel.filteredUsers) { user in
                            if user.uid == currentUid {
                                // Tu propia fila (sin navegación o navegación a tu perfil propio)
                                UserRowDesign(user: user, currentUid: currentUid)
                            } else {
                                // 🔥 AQUÍ ESTÁ EL CAMBIO:
                                // En lugar de ProfileView, usamos tu PublicProfileView
                                NavigationLink {
                                    PublicProfileView(targetUser: user)
                                } label: {
                                    UserRowDesign(user: user, currentUid: currentUid)
                                }
                            }
                        }
                        .refreshable {
                            viewModel.fetchUsers()
                        }
                    }
                }
            }
            .navigationTitle("People")
            .onAppear {
                viewModel.fetchUsers()
            }
        }
    }
}

// 3. DISEÑO DE LA FILA
struct UserRowDesign: View {
    let user: AtlertsUser
    let currentUid: String?
    
    var body: some View {
        HStack(spacing: 15) {
            
            // AVATAR
            ZStack {
                if let urlString = user.profileImageURL, let url = URL(string: urlString) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            Color.gray.opacity(0.3)
                        case .success(let image):
                            image.resizable()
                                .scaledToFill()
                                .transition(.opacity.animation(.easeInOut(duration: 0.5)))
                        case .failure:
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .foregroundColor(.gray)
                        @unknown default:
                            EmptyView()
                        }
                    }
                } else {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .foregroundColor(.gray)
                }
            }
            .frame(width: 50, height: 50)
            .clipShape(Circle())
            
            // TEXTOS
            VStack(alignment: .leading, spacing: 4) {
                Text(user.uid == currentUid ? "\(user.name ?? "Usuario") (Tú)" : (user.name ?? "Usuario"))
                    .font(.headline)
                    .foregroundColor(.primary)
                
                HStack(spacing: 6) {
                    if user.role == "moderator" {
                        Image(systemName: "shield.fill")
                            .font(.caption2)
                            .foregroundColor(.yellow)
                        Text("Super Admin")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.yellow)
                    } else {
                        Image(systemName: "building.2.fill")
                            .font(.caption2)
                            .foregroundColor(.blue)
                        Text(user.community ?? "Not Assigned")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // 🔥 BADGE ROJO (SOLO SI NO ES TU PROPIO USUARIO)
            if let uid = user.uid, uid != currentUid {
                DirectoryUnreadBadge(targetUid: uid)
            }
        }
        .padding(.vertical, 4)
    }
}

// 4. COMPONENTE DE NOTIFICACIÓN CORREGIDO
struct DirectoryUnreadBadge: View {
    let targetUid: String
    @State private var unreadCount: Int = 0
    
    var body: some View {
        Group {
            if unreadCount > 0 {
                ZStack {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 22, height: 22)
                    
                    Text("\(unreadCount)")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                .transition(.scale)
            } else {
                // Truco para mantener el listener activo aunque sea 0
                Color.clear.frame(width: 0, height: 0)
            }
        }
        .onAppear {
            listenForUnreadMessages()
        }
    }
    
    func listenForUnreadMessages() {
        guard let currentUid = Auth.auth().currentUser?.uid else { return }
        
        // 1. Calculamos el ID de la conversación (Igual que en el Chat)
        let uids = [currentUid, targetUid].sorted()
        let conversationId = uids.joined(separator: "_")
        
        // 2. 🔥 CORRECCIÓN CRÍTICA: Cambiado de "conversations" a "chats"
        // Ahora miramos la misma carpeta donde el Chat guarda los mensajes.
        Firestore.firestore().collection("chats")
            .document(conversationId)
            .collection("messages")
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else { return }
                
                // 3. Filtramos en el dispositivo (seguro y rápido)
                let count = documents.filter { doc in
                    let data = doc.data()
                    let sender = (data["fromId"] as? String) ?? (data["senderId"] as? String) ?? ""
                    let isRead = data["isRead"] as? Bool ?? false
                    
                    // Solo contamos mensajes del OTRO que NO estén leídos
                    return sender == targetUid && isRead == false
                }.count
                
                withAnimation {
                    self.unreadCount = count
                }
            }
    }
}
