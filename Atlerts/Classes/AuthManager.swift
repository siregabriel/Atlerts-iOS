//
//  AuthManager.swift
//  Atlerts
//
//  Created by Gabriel Rosales Montes  on 01/01/26.
//
import Foundation
import Combine
import SwiftUI       // <--- ESTA LÍNEA ES LA SOLUCIÓN
import FirebaseAuth
import FirebaseFirestore

class AuthManager: ObservableObject {
    // Variable global compartida (Singleton)
    static let shared = AuthManager()
    
    // Publicamos el estado para que la vista se entere cuando cambia
    @Published var userSession: FirebaseAuth.User?
    
    init() {
        // Al iniciar, verificamos si ya había una sesión guardada
        self.userSession = Auth.auth().currentUser
    }
    
    // FUNCIÓN DE LOGIN
    func login(email: String, pass: String, completion: @escaping (Bool, String?) -> Void) {
        Auth.auth().signIn(withEmail: email, password: pass) { result, error in
            if let error = error {
                print("Error al loguear: \(error.localizedDescription)")
                completion(false, error.localizedDescription)
                return
            }
            
            // Si el login es correcto, actualizamos la sesión
            self.userSession = result?.user
            print("Login exitoso. Usuario UID: \(result?.user.uid ?? "")")
            completion(true, nil)
        }
    }
    
    // FUNCIÓN DE LOGOUT
    func logout() {
        do {
            try Auth.auth().signOut()
            self.userSession = nil
        } catch {
            print("Error al cerrar sesión: \(error.localizedDescription)")
        }
    }
}

