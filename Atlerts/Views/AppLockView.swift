//
//  AppLockView.swift
//  Atlerts
//
//  Created by Gabriel Rosales Montes  on 12/01/26.
//
//
//  AppLockView.swift
//  Atlerts
//
//  Created by Gabriel Rosales Montes on 12/01/26.
//

import SwiftUI
import LocalAuthentication // <-- La magia de Apple
import Combine

class AppLockManager: ObservableObject {
    @Published var isUnlocked = false
    
    func authenticate() {
        let context = LAContext()
        var error: NSError?
        
        // Verificamos si el dispositivo tiene FaceID/TouchID
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Unlock to enter to Atlerts"
            
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authenticationError in
                DispatchQueue.main.async {
                    if success {
                        self.isUnlocked = true
                    } else {
                        // Si falla (canceló o no reconoció), se queda bloqueado
                        self.isUnlocked = false
                    }
                }
            }
        } else {
            // Si el dispositivo es muy viejo o no tiene clave, lo dejamos pasar
            self.isUnlocked = true
        }
    }
}

struct AppLockView: View {
    @StateObject var lockManager = AppLockManager()
    
    // Aquí recibimos el contenido real de tu app para mostrarlo solo si se abre el candado
    let content: AnyView
    
    init<Content: View>(@ViewBuilder content: () -> Content) {
        self.content = AnyView(content())
    }
    
    var body: some View {
        Group {
            if lockManager.isUnlocked {
                // 🔓 ABIERTO: Mostramos la App normal
                content
            } else {
                // 🔒 CERRADO: Pantalla de Bloqueo
                ZStack {
                    Color.black.ignoresSafeArea()
                    
                    VStack(spacing: 20) {
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.white)
                        
                        Text("Atlerts is locked")
                            .font(.title2)
                            .foregroundColor(.white)
                            .fontWeight(.bold)
                        
                        Button(action: {
                            lockManager.authenticate()
                        }) {
                            Text("Unlock with FaceID")
                                .fontWeight(.semibold)
                                .foregroundColor(.black)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(12)
                        }
                    }
                }
                .onAppear {
                    // Intenta desbloquear automáticamente al abrir
                    lockManager.authenticate()
                }
            }
        }
    }
}
