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
    
    // 🔥 NUEVO: Variable para el texto de búsqueda
    @Published var searchText: String = ""
    
    private var db = Firestore.firestore()
    
    // 🔥 NUEVO: Lógica de filtrado en tiempo real
    var filteredUsers: [AtlertsUser] {
        if searchText.isEmpty {
            return users
        } else {
            return users.filter { user in
                // Busca por nombre O por comunidad (ignorando mayúsculas/minúsculas)
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
                
                // 🔥 NUEVO: VStack para colocar la barra de búsqueda arriba
                VStack(spacing: 0) {
                    
                    // 🔥 NUEVO: BARRA DE BÚSQUEDA
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        
                        TextField("Search users...", text: $viewModel.searchText)
                            .foregroundColor(.primary)
                        
                        if !viewModel.searchText.isEmpty {
                            Button(action: {
                                viewModel.searchText = ""
                                // Esconder teclado
                                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding(10)
                    .background(Color(UIColor.systemGray6)) // Fondo gris suave
                    .cornerRadius(10)
                    .padding(.horizontal)
                    .padding(.bottom, 10)
                    .padding(.top, 10) // Un poco de aire arriba
                    
                    // LÓGICA DE ESTADOS (Loading / Empty / List)
                    if viewModel.isLoading {
                        Spacer()
                        ProgressView()
                        Spacer()
                    } else if viewModel.filteredUsers.isEmpty { // 🔥 CAMBIO: Usamos filteredUsers
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
                        // 🔥 CAMBIO: Iteramos sobre 'filteredUsers' en lugar de 'users'
                        List(viewModel.filteredUsers) { user in
                            
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
                } // Fin VStack
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
            
            // --- AVATAR CON EFECTO SUAVE ---
            ZStack {
                if let urlString = user.profileImageURL, let url = URL(string: urlString) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            // Mientras carga, mostramos el círculo gris
                            Color.gray.opacity(0.3)
                        case .success(let image):
                            // Cuando termina, mostramos la imagen con animación
                            image.resizable()
                                 .scaledToFill()
                                 .transition(.opacity.animation(.easeInOut(duration: 0.5))) // ✨ EL TRUCO
                        case .failure:
                            // Si falla, mostramos icono por defecto
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .foregroundColor(.gray)
                        @unknown default:
                            EmptyView()
                        }
                    }
                } else {
                    // Si no tiene URL
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
                    Text(user.community ?? "Not Assigned")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
