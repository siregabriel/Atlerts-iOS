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
    
    // 🔥 CONTROLADOR DE SPLASH:
    @State private var showSplash = true
    
    var body: some View {
        ZStack {
            
            // CAPA 1: La App Real (Se carga pero espera oculta o aparece tras el splash)
            if !showSplash {
                if viewModel.userSession != nil {
                    // Si hay sesión -> App Principal
                    MainTabView()
                        .transition(.opacity)
                } else {
                    // Si no hay sesión -> Login
                    LoginView()
                        .transition(.opacity)
                }
            }
            
            // CAPA 2: PANTALLA DE SPLASH (Siempre encima al inicio)
            if showSplash {
                SplashView()
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        // ⚠️ HE QUITADO EL .onTapGesture AQUÍ PORQUE BLOQUEABA LA LISTA
        .onAppear {
            // ⏳ TIEMPO DE ESPERA: 3.5 segundos
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
                withAnimation(.easeOut(duration: 0.5)) {
                    self.showSplash = false
                }
            }
        }
    }
}

// 3. BARRA DE PESTAÑAS (La navegación principal)
struct MainTabView: View {
    var body: some View {
        TabView {
            // Pestaña 1: INICIO
            HomeView()
                .tabItem {
                    Image("atlas-globe-icon-24")
                        .renderingMode(.template)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 32, height: 24)
                    Text("Home")
                }

            // Pestaña 2: DIRECTORIO
            DirectoryView()
                .tabItem {
                    Label("Directory", systemImage: "person.3.fill")
                }

            // Pestaña 3: DOCUMENTOS
            DocumentsView()
                .tabItem {
                    Label("Docs", systemImage: "folder.fill")
                }

            // Pestaña 4: BROADCAST
            BroadcastView()
                .tabItem {
                    Label("Broadcast", systemImage: "bell.fill")
                }

            // PESTAÑA 5: CALENDARIO
            CalendarView()
                .tabItem {
                    Image(systemName: "calendar")
                    Text("Calendar")
                }

            // PESTAÑA 6: FORMS
            FormsView()
                .tabItem {
                    Image(systemName: "list.clipboard.fill")
                    Text("Forms")
                }

            // Pestaña 7: PERFIL
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle.fill")
                }
        }
        .accentColor(.blue)
    }
}

// ---------------------------------------------------------
// 🔥 EXTENSIÓN PARA OCULTAR EL TECLADO
// (La dejamos aquí por si la usamos puntualmente en otro lado, pero ya no afecta globalmente)
// ---------------------------------------------------------
extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
