//
//  LoginView.swift
//  Atlerts
//
//  Created by Gabriel Rosales Montes  on 03/01/26.
//
import SwiftUI
import FirebaseAuth

// 1. CAMBIAMOS EL NOMBRE DE LA ESTRUCTURA A 'LoginView'
struct LoginView: View {
    // --- 1. VARIABLES DE ANIMACIÓN ---
    @State private var startAnimation = false
    @State private var showBadge = false
    @State private var showText = false
    @State private var endSplash = false
    
    // --- 2. VARIABLES DE DATOS Y SEGURIDAD ---
    @State private var emailText = ""
    @State private var passwordText = ""
    // Borramos isLoggedIn de aquí, porque RootView lo controlará desde fuera
    @State private var loginError = ""
    @State private var showErrorMessage = false
    
    var body: some View {
        ZStack {
            // A. FONDO (Común para todo)
            Color(hex: "0f2027")
                .ignoresSafeArea()
            
            // B. FORMULARIO DE LOGIN (Aparece detrás del splash)
            VStack(spacing: 25) {
                
                // Logo estático superior
                VStack(spacing: 15) {
                    Image("atlas-globe-icon-large") // O systemName: "shield.check.fill"
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 100, height: 100)
                        .foregroundColor(.white)
                    
                    Text("Atlerts")
                        .font(.system(size: 28, weight: .bold, design: .default))
                        .foregroundColor(.white)
                }
                .padding(.top, 60)
                
                HStack {
                    Text(" by Atlas Senior Living")
                        .foregroundColor(Color.white.opacity(0.5))
                        .fontWeight(.bold)
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
                }
                
                // Campos de Texto
                VStack(spacing: 15) {
                    HStack {
                        Image(systemName: "envelope.fill").foregroundColor(.gray)
                        TextField("Email (corporate)", text: $emailText)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .colorScheme(.light)
                    }
                    .padding()
                    .background(Color.white).cornerRadius(12)
                    
                    HStack {
                        Image(systemName: "lock.fill").foregroundColor(.gray)
                        SecureField("Password", text: $passwordText)
                    }
                    .padding()
                    .background(Color.white).cornerRadius(12)
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
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 30)
                
                Spacer()
                
                HStack {
                    Text("¿Not account yet? Contact admin to get started.")
                        .foregroundColor(Color.white.opacity(0.9))
                        .fontWeight(.bold)
                        .padding(40)
                        .font(Font.system(size: 15, design: .default))
                        .multilineTextAlignment(.center)
                }
                
                Text("2026 Made with love from the Digital Marketing Team.")
                    .font(.system(size: 12, design: .default))
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.bottom, 20)
            }
            .opacity(endSplash ? 1 : 0) // Solo se ve cuando termina el splash
            
            
            // C. PANTALLA SPLASH (Capa superior animada)
            if !endSplash {
                ZStack {
                    LinearGradient(gradient: Gradient(colors: [Color(hex: "0f2027"), Color(hex: "203a43"), Color(hex: "2c5364")]),
                                   startPoint: .top,
                                   endPoint: .bottom)
                    .ignoresSafeArea()
                    
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
                            
                            // Sello 18+
                            VStack {
                                Spacer()
                                HStack {
                                    Spacer()
                                }
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
        // ELIMINAMOS EL .fullScreenCover Y EL SIGN OUT AL INICIO PARA QUE NO CIERRE SESIÓN SOLO
        .onAppear {
             ejecutarSecuencia()
        }
    }
    
    // --- 3. LÓGICA DE SEGURIDAD ---
    func intentarLogin() {
        // 1. Validar campos vacíos
        if emailText.isEmpty || passwordText.isEmpty {
            loginError = "Please fill in all fields."
            withAnimation { showErrorMessage = true }
            return
        }
        
        // 2. Consultar a Firebase
        AuthManager.shared.login(email: emailText, pass: passwordText) { success, errorMsg in
            if success {
                print("✅ Correct login")
                showErrorMessage = false
                // YA NO NECESITAMOS HACER NADA MÁS.
                // Firebase le avisará a RootView automáticamente.
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
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.8) {
            withAnimation(.easeInOut(duration: 0.6)) {
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
