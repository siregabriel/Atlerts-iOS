//
//  AtlertsApp.swift
//  Atlerts
//
//  Created by Gabriel Rosales Montes  on 31/12/25.
//

import SwiftUI
#if canImport(FirebaseCore)
import FirebaseCore // <--- Importante
#endif

// 1. Creamos un "Adaptador" para conectar con AppDelegate
class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    
    // Aquí arranca el cerebro de Firebase
#if canImport(FirebaseCore)
    FirebaseApp.configure()
    print("✅ Firebase configurado exitosamente")
#else
    print("⚠️ FirebaseCore no está disponible. Omite configuración de Firebase.")
#endif
    
    return true
  }
}

@main
struct GaberificationApp: App {
    // 2. Inyectamos el adaptador en la App
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    // 2. Instanciamos a nuestro "Vigilante" (SystemManager)
        // Él estará escuchando la base de datos desde que abres la app
        @StateObject var systemManager = SystemManager()
        
        var body: some Scene {
            WindowGroup {
                // 3. AQUÍ ESTÁ LA LÓGICA DE BLOQUEO
                if systemManager.isMaintenanceMode {
                    // Si el vigilante dice TRUE (activado en la web), mostramos esto:
                    MaintenanceView()
                } else {
                    // Si dice FALSE, mostramos tu App normal (Login o Contenido)
                    // Asegúrate de que ContentView sea tu vista principal
                    ContentView()
                }
            }
        }
    }

    // Mantenemos tu configuración de Firebase (no la borres si ya la tienes en otro lado,
    // pero usualmente va aquí abajo o en un archivo aparte)
