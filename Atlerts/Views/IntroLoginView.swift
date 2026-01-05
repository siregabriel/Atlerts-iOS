//
//  IntroLoginView.swift
//  Atlerts
//
//  Created by Gabriel Rosales Montes  on 31/12/25.
//
import SwiftUI

struct IntroLoginView: View {
    // Variables para guardar lo que escribe el usuario
    @State private var email: String = ""
    @State private var password: String = ""
    
    // Estado para simular carga (spinner)
    @State private var isLoading: Bool = false
    
    // Estado para navegar a la app principal tras loguearse
    @State private var isLoggedIn: Bool = false
    
    var body: some View {
        if isLoggedIn {
            // Aquí iría la vista principal (TabView con Chat y Repo)
            // Por ahora ponemos un texto de ejemplo
            MainAppView()
        } else {
            ZStack {
                // 1. FONDO (Degradado Azul Profesional)
                LinearGradient(gradient: Gradient(colors: [Color(hex: "000"), Color(hex: "203a43"), Color(hex: "2c5364")]),
                               startPoint: .top,
                               endPoint: .bottom)
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 25) {
                    Spacer()
                    
                    // 2. LOGO Y TÍTULO
                    VStack(spacing: 15) {
                        // Placeholder del Logo
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.1))
                                .frame(width: 120, height: 120)
                            //logo de Atlas
                            Image("atlas-globe-icon-large")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 95, height:95)
                                .foregroundColor(.white)
                            
                            VStack {
                                Spacer()
                            }
                            .frame(width: 120, height: 120)
                        }
                        
                        Text("Atlerts")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("Atlas Senior Living - Welcome")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(.bottom, 30)
                    
                    // 3. CAMPOS DE TEXTO
                    VStack(spacing: 15) {
                        // Campo Email
                        HStack {
                            Image(systemName: "envelope.fill")
                                .foregroundColor(.gray)
                            TextField("Email (corporate)", text: $email)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .foregroundColor(.black)
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        
                        // Campo Password
                        HStack {
                            Image(systemName: "lock.fill")
                                .foregroundColor(.gray)
                            SecureField("Password", text: $password)
                                .foregroundColor(.black)
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal, 30)
                    
                    // 4. BOTÓN DE LOGIN - Gabriel custom array
                    Button(action: {
                        loginAction()
                    }) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Log In")
                                    .fontWeight(.bold)
                                Image(systemName: "arrow.right")
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal, 30)
                    .disabled(isLoading) // Evita doble click
                    
                    Spacer()
                    
                    // 5. FOOTER (Información)
                    VStack(spacing: 5) {
                        Text("¿No account yet?")
                            .foregroundColor(.white.opacity(0.6))
                            .font(.footnote)
                        
                        Text("Contact admin to get started")
                            .foregroundColor(.white)
                            .font(.footnote)
                            .fontWeight(.medium)
                    }
                    .padding(.bottom, 40)
                    //copyright
                    HStack {
                        Text("© 2026, Atlas Senior Living.")
                            .foregroundColor(.white.opacity(0.6))
                            .font(.footnote)
                    }
                }
            }
        }
    }
    
    // Función simulada de login
    func loginAction() {
        // Aquí conectaremos con Firebase Auth más adelante
        isLoading = true
        
        // Simulación de espera de red (2 segundos)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isLoading = false
            isLoggedIn = true // Navega a la app
        }
    }
}

// Extensión para usar códigos Hex de colores (copia esto al final de tu archivo)
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// Vista Main temporal para que el código compile
struct MainAppView: View {
    var body: some View {
        TabView {
            Text("Pantalla de Chat") // Aquí iría ChatDesignScreen()
                .tabItem {
                    Label("Mensajes", systemImage: "message.fill")
                }
            
            Text("Pantalla de Archivos") // Aquí iría RepositoryView()
                .tabItem {
                    Label("Documentos", systemImage: "folder.fill")
                }
        }
    }
}

struct IntroLoginView_Previews: PreviewProvider {
    static var previews: some View {
        IntroLoginView()
    }
}

