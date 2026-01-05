import SwiftUI
import FirebaseAuth

struct RootView: View {
    @State private var userSession: User? = nil
    @State private var authStateDidChangeHandle: AuthStateDidChangeListenerHandle? = nil
    
    var body: some View {
        Group {
            if userSession != nil {
                // Si hay usuario, vamos a la App
                ContentView()
            } else {
                // Si NO hay usuario, mostramos tu Login (que acabamos de arreglar)
                LoginView()
            }
        }
        .onAppear {
            authStateDidChangeHandle = Auth.auth().addStateDidChangeListener { _, user in
                self.userSession = user
            }
        }
        .onDisappear {
            if let handle = authStateDidChangeHandle {
                Auth.auth().removeStateDidChangeListener(handle)
                authStateDidChangeHandle = nil
            }
        }
    }
}
