//
//  PublicProfileView.swift
//  Atlerts
//
//  Created by Gabriel Rosales Montes  on 09/01/26.
//
import SwiftUI
// Si usas SDWebImage para fotos, importalo aquí, si no usa AsyncImage

struct PublicProfileView: View {
    let targetUser: AtlertsUser // Recibimos el objeto usuario directamente
    @StateObject var viewModel = ProfileViewModel() // Reusamos tu VM existente
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 1. FOTO DE PERFIL
                // Ajusta esto si usas un componente personalizado de imagen
                AsyncImage(url: URL(string: targetUser.profileImageURL ?? "")) { phase in
                    if let image = phase.image {
                        image.resizable().aspectRatio(contentMode: .fill)
                    } else {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .foregroundColor(.gray)
                    }
                }
                .frame(width: 150, height: 150)
                .clipShape(Circle())
                .shadow(radius: 5)
                .padding(.top, 40)
                
                // 2. DATOS DEL USUARIO
                Text(targetUser.name ?? "Usuario")
                    .font(.title)
                    .fontWeight(.bold)
                
                // Haz lo mismo con el email por si acaso:
                Text(targetUser.email ?? "")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                // --- AGREGAR ESTO ---
                HStack(spacing: 6) {
                    Image(systemName: "building.2.fill")
                        .foregroundColor(.blue)
                    Text(targetUser.community ?? "Sin Comunidad")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 5) // Un poco de aire arriba
                // --------------------
                
                Divider().padding()
                
                // 3. BOTONES DE ACCIÓN
                HStack(spacing: 30) {
                    
                    Spacer()
                    
                    // Botón Chat (Navegación simulada, ajústalo a tu ChatView)
                    NavigationLink(destination: ChatView(user: targetUser)) {
                        VStack {
                            Image(systemName: "bubble.left.fill")
                                .font(.title2)
                            Text("Messages")
                                .font(.caption)
                        }
                        .frame(width: 80, height: 60)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(10)
                    }
                    
                    // Botón Archivos (Si aplica)
                    Button(action: {
                        // 1. Preparamos el enlace "mailto:"
                        // Usamos ?? "" por seguridad, aunque el botón no debería funcionar si no hay email
                        let email = targetUser.email ?? ""
                        if let url = URL(string: "mailto:\(email)") {
                            // 2. Verificamos si el dispositivo puede abrir correos
                            if UIApplication.shared.canOpenURL(url) {
                                UIApplication.shared.open(url)
                            }
                        }
                    }) {
                        VStack {
                            // Cambiamos el icono a un sobre (envelope)
                            Image(systemName: "envelope.fill")
                                .font(.title2)
                            // Cambiamos el texto
                            Text("Email")
                                .font(.caption)
                        }
                    }
                    // Deshabilitamos el botón si no tiene email para evitar errores
                    .disabled((targetUser.email ?? "").isEmpty)
                    .opacity((targetUser.email ?? "").isEmpty ? 0.5 : 1.0)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("User Profile")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
