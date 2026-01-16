//
//  AtlertsApp.swift
//  Atlerts
//
//  Created by Gabriel Rosales Montes on 12/01/26.
//

import SwiftUI
import FirebaseCore // Necesario para inicializar Firebase

// 1. CONFIGURACIÓN DE FIREBASE (Standard)
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
}

@main
struct AtlertsApp: App {
    // Conexión con AppDelegate para Firebase
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    // Tu Gestor de Estado del Sistema (Para el modo mantenimiento)
    // Nota: Asumo que tienes una clase SystemManager o similar. Si se llama diferente, ajusta el nombre aquí.
    @StateObject var systemManager = SystemManager()
    
    // 🔥 NUEVO: Memoria para saber si ya vio el Onboarding
    @AppStorage("hasSeenOnboarding") var hasSeenOnboarding: Bool = false
    
    var body: some Scene {
        WindowGroup {
            // --- ÁRBOL DE DECISIÓN DE LA APP ---
            
            // 1. ¿Es usuario nuevo? -> Mostrar Onboarding
            if !hasSeenOnboarding {
                OnboardingView()
            }
            else {
                // 2. Usuario recurrente -> Proteger con FaceID
                AppLockView {
                    
                    // 3. ¿La App está en mantenimiento? -> Mostrar Pantalla de Error
                    if systemManager.isMaintenanceMode {
                        MaintenanceView()
                    }
                    else {
                        // 4. Todo bien -> Entrar a la App
                        ContentView()
                            .environmentObject(systemManager) // Pasamos el manager a las vistas hijas si lo necesitan
                    }
                }
            }
        }
    }
}
