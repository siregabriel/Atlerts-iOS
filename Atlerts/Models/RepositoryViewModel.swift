import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import Combine

class RepositoryViewModel: ObservableObject {
    @Published var files: [RepositoryFile] = []
    @Published var isLoading = false
    
    private var db = Firestore.firestore()
    
    init() {
        fetchFiles()
    }
    
    func fetchFiles() {
            guard Auth.auth().currentUser != nil else { return }
            isLoading = true
            
            db.collection("files")
                .whereField("assignedTo", isEqualTo: "ALL")
                .order(by: "createdAt", descending: true)
                .addSnapshotListener { snapshot, error in
                    self.isLoading = false
                    
                    if let error = error {
                        print("❌ Error de Firestore: \(error.localizedDescription)")
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        print("⚠️ No llegaron documentos")
                        return
                    }
                    
                    print("✅ Encontrados \(documents.count) documentos. Intentando leerlos...")
                    
                    self.files = documents.compactMap { doc -> RepositoryFile? in
                        do {
                            return try doc.data(as: RepositoryFile.self)
                        } catch {
                            // ESTO NOS DIRÁ SI HAY ERROR DE FORMATO
                            print("❌ Error leyendo archivo '\(doc.documentID)': \(error)")
                            return nil
                        }
                    }
                }
        }
}
