import SwiftUI
import FirebaseFirestore
import FirebaseCore
import Combine

class SystemManager: ObservableObject {
    @Published var isMaintenanceMode: Bool = false
    
    private var db = Firestore.firestore()
    
    init() {
        listenToSystemStatus()
    }
    
    func listenToSystemStatus() {
        // CORRECCIÓN: Usamos ".document" en lugar de ".doc" para compatibilidad
        db.collection("app_settings").document("status").addSnapshotListener { document, error in
            
            guard let document = document, document.exists, let data = document.data() else {
                DispatchQueue.main.async {
                    self.isMaintenanceMode = false
                }
                return
            }
            
            if let status = data["is_maintenance"] as? Bool {
                DispatchQueue.main.async {
                    withAnimation {
                        self.isMaintenanceMode = status
                    }
                }
            }
        }
    }
}
