import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import Combine
import UIKit

// ---------------------------------------------------------
// 🔥 SOLUCIÓN FINAL: CONEXIÓN AL OBSERVER ARREGLADO
// ---------------------------------------------------------
// Cambiamos la instancia local rota por el Observer global que ya limpiamos.
// (La clase AtlertsBadgeManager se ha eliminado de aquí para evitar conflictos).
let appBadgeGlobal = GlobalBadgeObserver()

// ---------------------------------------------------------
// 1. DETECTOR DE SESIÓN
// ---------------------------------------------------------
class AuthViewModel: ObservableObject {
    @Published var userSession: User?
    
    init() {
        _ = Auth.auth().addStateDidChangeListener { auth, user in
            self.userSession = user
        }
    }
}

// ---------------------------------------------------------
// 2. VISTA PRINCIPAL (ContentView)
// ---------------------------------------------------------
struct ContentView: View {
    @StateObject var viewModel = AuthViewModel()
    @State private var showSplash = true
    
    var body: some View {
        ZStack {
            // CAPA 1: La App Real
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
            
            // CAPA 2: SPLASH SCREEN
            if showSplash {
                SplashView()
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .onAppear {
            UIApplication.shared.addGlobalKeyboardDismissal()
            
            // Timer del Splash
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
                withAnimation(.easeOut(duration: 0.5)) {
                    self.showSplash = false
                }
            }
        }
    }
}

// ---------------------------------------------------------
// 3. BARRA DE PESTAÑAS (MainTabView)
// ---------------------------------------------------------
struct MainTabView: View {
    // Usamos la variable global (ahora conectada al GlobalBadgeObserver correcto)
    @ObservedObject var badgeManager = appBadgeGlobal

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
                // 🔥 AQUI EL BADGE (Ahora lee la base de datos limpia)
                .badge(badgeManager.totalUnread)

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
            
            // Pestaña 5: TRAINING
            TrainingView()
                .tabItem {
                    Image(systemName: "play.tv.fill")
                    Text("Training")
                }
            
            // PESTAÑA 6: CALENDARIO
            CalendarView()
                .tabItem {
                    Image(systemName: "calendar")
                    Text("Calendar")
                }

            // PESTAÑA 7: FORMS
            FormsView()
                .tabItem {
                    Image(systemName: "list.clipboard.fill")
                    Text("Forms")
                }

            // Pestaña 8: PERFIL
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle.fill")
                }

        }
        .accentColor(.blue)
    }
}

// ---------------------------------------------------------
// EXTENSIONES Y EXTRAS
// ---------------------------------------------------------
extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    func addGlobalKeyboardDismissal() {
        guard let windowScene = connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else { return }
        
        let tapGesture = UITapGestureRecognizer(target: window, action: #selector(UIView.endEditing))
        tapGesture.cancelsTouchesInView = false
        tapGesture.requiresExclusiveTouchType = false
        
        window.addGestureRecognizer(tapGesture)
    }
}

struct RotatingRaysBackground: View {
    @State private var isRotating = false

    var body: some View {
        ZStack {
            RadialGradient(
                gradient: Gradient(colors: [
                    Color(red: 1.0, green: 0.98, blue: 0.8),
                    Color(red: 0.85, green: 0.65, blue: 0.13),
                    Color(red: 0.5, green: 0.35, blue: 0.05)
                ]),
                center: .center,
                startRadius: 5,
                endRadius: 600
            )
            
            GeometryReader { geo in
                ZStack {
                    ForEach(0..<12) { i in
                        Rectangle()
                            .fill(Color.white.opacity(0.08))
                            .frame(width: 50, height: geo.size.height * 2)
                            .offset(y: -geo.size.height / 2)
                            .rotationEffect(.degrees(Double(i) * 30))
                    }
                }
                .frame(width: geo.size.width, height: geo.size.height, alignment: .center)
                .rotationEffect(.degrees(isRotating ? 360 : 0))
                .animation(
                    .linear(duration: 25).repeatForever(autoreverses: false),
                    value: isRotating
                )
            }
            
            LinearGradient(
                gradient: Gradient(colors: [.clear, .white.opacity(0.15), .clear]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .blendMode(.overlay)
        }
        .ignoresSafeArea()
        .onAppear {
            isRotating = true
        }
    }
}
