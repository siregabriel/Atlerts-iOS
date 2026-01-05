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
    private var db = Firestore.firestore()
    
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
                
                if viewModel.isLoading {
                    ProgressView()
                } else if viewModel.users.isEmpty {
                    Text("No hay usuarios registrados")
                        .foregroundColor(.gray)
                } else {
                    List(viewModel.users) { user in
                        
                        // LÓGICA DE NAVEGACIÓN
                        if user.uid == currentUid {
                            // Si eres tú, mostramos el diseño igual que los demás
                            // (Quitamos la opacidad y el fondo transparente)
                            UserRowDesign(user: user, currentUid: currentUid)
                        } else {
                            // Si es otro, activamos el enlace al Chat
                            NavigationLink {
                                ChatView(user: user)
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
            .navigationTitle("Directorio")
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
            
            // --- AVATAR ---
            ZStack {
                if let urlString = user.profileImageURL, let url = URL(string: urlString) {
                    AsyncImage(url: url) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        Color.gray.opacity(0.3)
                    }
                } else {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .foregroundColor(.gray)
                }
            }
            .frame(width: 50, height: 50)
            .clipShape(Circle())
            
            // --- TEXTOS ---
            VStack(alignment: .leading, spacing: 4) {
                // Nombre
                Text(user.uid == currentUid ? "\(user.name ?? "Usuario") (Tú)" : (user.name ?? "Usuario"))
                    .font(.headline)
                    .foregroundColor(.primary)
                
                // ROL y COMUNIDAD
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
                        Image(systemName: "iphone")
                            .font(.caption2)
                            .foregroundColor(.gray)
                        Text("Cliente")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    Text("•").font(.caption).foregroundColor(.gray)
                    
                    Image(systemName: "building.2.fill")
                        .font(.caption2)
                        .foregroundColor(.blue)
                    Text(user.community ?? "Sin Asignar")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
