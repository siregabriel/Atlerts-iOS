//
//  LoginView.swift
//  Atlerts
//
//  Created by Gabriel Rosales Montes  on 03/01/26.
//
import SwiftUI
import FirebaseAuth

struct LoginView: View {
    // --- 1. VARIABLES DE ANIMACIÓN ---
    @State private var startAnimation = false
    @State private var showBadge = false
    @State private var showText = false
    @State private var endSplash = false
    
    // --- 2. VARIABLES DE DATOS Y SEGURIDAD ---
    @State private var emailText = ""
    @State private var passwordText = ""
    @State private var loginError = ""
    @State private var showErrorMessage = false
    
    var body: some View {
        ZStack {
            // =================================================
            // A. FONDO NUEVO (Imagen + Capa Oscura) 🖼️
            // =================================================
            Image("atlerts-app-home-background") // Misma imagen que el Home
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
            
            Color.black.opacity(0.6) // Capa oscura para que resalten los textos
                .ignoresSafeArea()
            
            // =================================================
            // B. FORMULARIO DE LOGIN (Aparece detrás del splash)
            // =================================================
            VStack(spacing: 25) {
                
                // Logo estático superior
                VStack(spacing: 15) {
                    Image("atlas-globe-icon-large")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 100, height: 100)
                        .foregroundColor(.white)
                        .padding(.top, 60)
                    
                    Image("atlerts-name-logo")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(height: 40)
                                //.shimmering(duration: 2.0)
                                .magicalSparkles()
                }
                .padding(.top, 60)
                
                HStack {
                    Text(" by Atlas Senior Living")
                        .foregroundColor(Color.white.opacity(0.9)) // Un poco más visible
                        .fontWeight(.regular)
                        .font(.system(size: 16, design: .default))
                }
                
                Spacer()
                
                // Mensaje de Error (Rojo)
                if showErrorMessage {
                    Text(loginError)
                        .foregroundColor(.red)
                        .font(.caption)
                        .fontWeight(.bold)
                        .padding(.horizontal)
                        .multilineTextAlignment(.center)
                        .padding(10)
                        .background(Color.black.opacity(0.6)) // Fondo negro suave para el error
                        .cornerRadius(8)
                }
                
                // Campos de Texto
                VStack(spacing: 15) {
                    HStack {
                        Image(systemName: "envelope.fill").foregroundColor(.gray)
                        TextField("Email (corporate)", text: $emailText)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            // 🔥 Esto hace que el placeholder sea gris oscuro (legible)
                            .colorScheme(.light)
                            .foregroundColor(.black)
                    }
                    .padding()
                    .background(Color.white).cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2) // Sombra suave
                    
                    HStack {
                        Image(systemName: "lock.fill").foregroundColor(.gray)
                        SecureField("Password", text: $passwordText)
                            // 🔥 CORRECCIÓN AQUÍ: Agregamos colorScheme(.light)
                            // Esto fuerza a que el placeholder "Password" sea oscuro, no blanco.
                            .colorScheme(.light)
                            .foregroundColor(.black)
                    }
                    .padding()
                    .background(Color.white).cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2) // Sombra suave
                }
                .padding(.horizontal, 30)
                
                // BOTÓN DE LOGIN REAL
                Button(action: {
                    intentarLogin()
                }) {
                    Text("Log In")
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue) // Color de acento de Atlas
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .shadow(color: Color.blue.opacity(0.4), radius: 10, x: 0, y: 5) // Glow sutil
                }
                .padding(.horizontal, 30)
                
                Spacer()
                
                HStack {
                    Text("Don't have an account?\nContact support")
                        .foregroundColor(Color.white.opacity(0.9))
                        .fontWeight(.bold)
                        .padding(40)
                        .font(Font.system(size: 15, design: .default))
                        .multilineTextAlignment(.center)
                        .shadow(color: Color.black, radius: 2, x: 0, y: 1) // Sombra texto
                }
                
                    Text("2026 Made with 🩵 by the Atlas Digital Marketing Team\nV. 0.9 Build 1")
                        .font(.system(size: 11, design: .default))
                        .foregroundColor(.white.opacity(0.9))
                        .padding(.bottom, 40)
                        .multilineTextAlignment(.center)
                }
            
            
            .opacity(endSplash ? 1 : 0) // Solo se ve cuando termina el splash
            
            
            // =================================================
            // C. PANTALLA SPLASH (Capa superior animada)
            // =================================================
            if !endSplash {
                ZStack {
                    // Mantenemos el degradado original o lo cambiamos a negro
                    // para que la transición sea "Fade out" hacia la foto
                    Color.black
                        .ignoresSafeArea()
                    
                    // Si prefieres que el splash TAMBIÉN tenga la foto de fondo,
                    // descomenta las siguientes 3 líneas y borra el Color.black de arriba:
                    /*
                    Image("atlerts-app-home-background").resizable().scaledToFill().ignoresSafeArea()
                    Color.black.opacity(0.3).ignoresSafeArea()
                    */
                    
                    VStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.1))
                                .frame(width: 140, height: 140)
                                .scaleEffect(startAnimation ? 1 : 0)
                            
                            Image("atlas-globe-icon-large")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 90, height: 90)
                                .foregroundColor(.white)
                                .scaleEffect(startAnimation ? 1 : 0.5)
                                .opacity(startAnimation ? 1 : 0)
                            
                            VStack {
                                Spacer()
                                HStack { Spacer() }
                            }
                            .frame(width: 140, height: 140)
                        }
                        .animation(.spring(response: 0.6, dampingFraction: 0.6), value: startAnimation)
                        .animation(.spring(response: 0.4, dampingFraction: 0.5), value: showBadge)
                    }
                }
                .transition(.opacity)
                .zIndex(1)
            }
        }
        .onAppear {
            ejecutarSecuencia()
        }
        // Fuerza el estilo general a oscuro (para barra de estado blanca),
        // pero los TextFields los forzamos a Light individualmente arriba.
        .preferredColorScheme(.dark)
    }
    
    // --- 3. LÓGICA DE SEGURIDAD ---
    func intentarLogin() {
        if emailText.isEmpty || passwordText.isEmpty {
            loginError = "Please fill in all fields."
            withAnimation { showErrorMessage = true }
            return
        }
        
        AuthManager.shared.login(email: emailText, pass: passwordText) { success, errorMsg in
            if success {
                print("✅ Correct login")
                showErrorMessage = false
            } else {
                print("❌ Incorrect login")
                loginError = "Error: \(errorMsg ?? "Invalid credentials")"
                withAnimation { showErrorMessage = true }
            }
        }
    }
    
    // --- 4. SECUENCIA DE ANIMACIÓN ---
    func ejecutarSecuencia() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation { startAnimation = true }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            withAnimation { showBadge = true }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation { showText = true }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            // Hacemos que el splash desaparezca suavemente revelando el login
            withAnimation(.easeInOut(duration: 0.8)) {
                endSplash = true
            }
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
