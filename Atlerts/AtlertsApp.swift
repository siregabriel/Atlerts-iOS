//
//  AtlertsApp.swift
//  Atlerts
//
//  Created by Gabriel Rosales Montes  on 31/12/25.
//

import SwiftUI
import UserNotifications // <-- Necesario para permisos
import FirebaseMessaging // <-- Necesario para Push Notifications

#if canImport(FirebaseCore)
import FirebaseCore // <--- Importante
#endif

// 1. Creamos un "Adaptador" para conectar con AppDelegate
// (Agregamos UNUserNotificationCenterDelegate y MessagingDelegate para arreglar los push)
class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    
    // Aquí arranca el cerebro de Firebase
#if canImport(FirebaseCore)
    FirebaseApp.configure()
    print("✅ Firebase configurado exitosamente")
#else
    print("⚠️ FirebaseCore no está disponible. Omite configuración de Firebase.")
#endif
      
    // --- CONFIGURACIÓN EXTRA PARA NOTIFICACIONES ---
    // Asignamos los delegados para escuchar eventos aunque la app esté abierta
    Messaging.messaging().delegate = self
    UNUserNotificationCenter.current().delegate = self
    
    // Pedimos permiso para Alertas, Globos y Sonidos
    let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
    UNUserNotificationCenter.current().requestAuthorization(
        options: authOptions,
        completionHandler: { _, _ in }
    )
    
    application.registerForRemoteNotifications()
    // -----------------------------------------------
    
    return true
  }
    
    // --- MÉTODOS NUEVOS OBLIGATORIOS PARA PUSH ---
    
    // 1. Para que el token de Firebase se refresque correctamente
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("Firebase token: \(String(describing: fcmToken))")
    }
    
    // 2. Conexión crítica entre APNs (Apple) y Firebase
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }
    
    // 3. 🔥 SOLUCIÓN: Permite que la notificación se vea con la App ABIERTA
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Forzamos que salga el Banner, Sonido y Badge
        completionHandler([.banner, .sound, .badge])
    }
    
    // 4. Manejo del clic en la notificación
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        completionHandler()
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
