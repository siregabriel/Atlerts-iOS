import SwiftUI
import FirebaseAuth
import Combine
import UIKit // 👈 NECESARIO PARA LA SOLUCIÓN DEL TECLADO

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
        // 🔥 SOLUCIÓN DEFINITIVA TECLADO 🔥
        .onAppear {
            // 1. Activamos el detector global que NO bloquea botones
            UIApplication.shared.addGlobalKeyboardDismissal()
            
            // 2. Lógica original del Splash (3.5 segundos)
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
                withAnimation(.easeOut(duration: 0.5)) {
                    self.showSplash = false
                }
            }
        }
    }
}
//MARK: BARRA DE PESTAÑAS
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
                    Label("Files", systemImage: "folder.fill")
                }

            // Pestaña 4: BROADCAST
            BroadcastView()
                .tabItem {
                    Label("Broadcast", systemImage: "megaphone.fill")
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
// 🔥 EXTENSIÓN POTENTE PARA OCULTAR EL TECLADO
// ---------------------------------------------------------
extension UIApplication {
    // Función simple para llamar manualmente si se necesita
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    // 🔥 LA SOLUCIÓN MAESTRA:
    // Agrega un gesto a toda la ventana que cierra el teclado pero DEJA PASAR los clics a los botones.
    func addGlobalKeyboardDismissal() {
        guard let windowScene = connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else { return }
        
        let tapGesture = UITapGestureRecognizer(target: window, action: #selector(UIView.endEditing))
        tapGesture.cancelsTouchesInView = false // 👈 ESTO ES LO QUE ARREGLA LAS FLECHAS
        tapGesture.requiresExclusiveTouchType = false
        
        window.addGestureRecognizer(tapGesture)
    }
}
// --- COMPONENTE DE FONDO GIRATORIO PREMIUM ---
struct RotatingRaysBackground: View {
    // Variable de estado para controlar la animación
    @State private var isRotating = false

    var body: some View {
        ZStack {
            // 1. CAPA BASE: Degradado Circular Fijo (Luz central)
            RadialGradient(
                gradient: Gradient(colors: [
                    Color(red: 1.0, green: 0.98, blue: 0.8), // Centro Luz Brillante
                    Color(red: 0.85, green: 0.65, blue: 0.13), // Oro Medio
                    Color(red: 0.5, green: 0.35, blue: 0.05)   // Borde Oscuro Profundo
                ]),
                center: .center,
                startRadius: 5,
                endRadius: 600 // Un poco más grande para cubrir bien
            )
            
            // 2. CAPA ANIMADA: Rayos de Gloria Giratorios 🔄
            GeometryReader { geo in
                ZStack {
                    ForEach(0..<12) { i in
                        Rectangle()
                            .fill(Color.white.opacity(0.08)) // Un poquito más visibles
                            .frame(width: 50, height: geo.size.height * 2) // Más anchos y largos
                            .offset(y: -geo.size.height / 2) // Salen del centro exacto
                            .rotationEffect(.degrees(Double(i) * 30)) // Distribución circular
                    }
                }
                .frame(width: geo.size.width, height: geo.size.height, alignment: .center)
                // AQUÍ ESTÁ LA MAGIA: Rotación continua
                .rotationEffect(.degrees(isRotating ? 360 : 0))
                // Animación lineal, lenta (25s por vuelta) e infinita
                .animation(
                    .linear(duration: 25).repeatForever(autoreverses: false),
                    value: isRotating
                )
            }
            
            // 3. CAPA TEXTURA: Brillo Metálico Fijo (Diagonal)
            LinearGradient(
                gradient: Gradient(colors: [.clear, .white.opacity(0.15), .clear]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .blendMode(.overlay)
        }
        .ignoresSafeArea()
        .onAppear {
            // Activa la rotación apenas aparece
            isRotating = true
        }
    }
}
