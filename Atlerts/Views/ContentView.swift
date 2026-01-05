import SwiftUI
import FirebaseAuth
import Combine

// 1. DETECTOR DE SESIÓN
// Escucha si el usuario está conectado o desconectado en tiempo real.
class AuthViewModel: ObservableObject {
    @Published var userSession: User?
    
    init() {
        // Usamos "_ =" para que Xcode no muestre la advertencia amarilla de "unused result"
        _ = Auth.auth().addStateDidChangeListener { auth, user in
            self.userSession = user
        }
    }
}

// 2. VISTA PRINCIPAL (Controlador de flujo)
struct ContentView: View {
    @StateObject var viewModel = AuthViewModel()
    
    var body: some View {
        Group {
            // Si Firebase detecta sesión, vamos a la App Principal
            if viewModel.userSession != nil {
                MainTabView()
            } else {
                // Si no, mostramos el Login
                LoginView()
            }
        }
    }
}

// 3. BARRA DE PESTAÑAS (La navegación principal)
struct MainTabView: View {
    var body: some View {
        TabView {
            // Pestaña 1: INICIO (Tu nueva pantalla bonita)
            HomeView()
                .tabItem {
                    Label("Inicio", systemImage: "house.fill")
                }
            
            // Pestaña 2: DIRECTORIO (Para buscar gente y chatear)
            DirectoryView()
                .tabItem {
                    Label("Directorio", systemImage: "person.3.fill")
                }
            
            // Pestaña 3: DOCUMENTOS
            DocumentsView()
                .tabItem {
                    Label("Docs", systemImage: "folder.fill")
                }
            
            // Pestaña 4: BROADCAST (Alertas)
            BroadcastView()
                .tabItem {
                    Label("Broadcast", systemImage: "bell.fill")
                }
            
            // Pestaña 5: PERFIL
            ProfileView()
                .tabItem {
                    Label("Perfil", systemImage: "person.crop.circle.fill")
                }
            
            // PESTAÑA 6: CALENDARIO (NUEVO)
            CalendarView()
                .tabItem {
                    Image(systemName: "calendar")
                    Text("Calendar")
                }
        }
        // Color de acento (Azul corporativo o el que prefieras)
        .accentColor(.blue)
    }
}
