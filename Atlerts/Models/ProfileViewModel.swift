import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine
import FirebaseStorage // Necesario para subir fotos
import UIKit // Necesario para manejar UIImage

@MainActor
class ProfileViewModel: ObservableObject {
    @Published var user: AtlertsUser?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var db = Firestore.firestore()
    private var storage = Storage.storage()
    
    init() {
        fetchUserProfile()
    }
    
    func fetchUserProfile() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        print("🔍 Buscando usuario: \(uid)") // Pista 1
        
        db.collection("users").document(uid).addSnapshotListener { snap, error in
            if let error = error {
                print("❌ Error de conexión: \(error.localizedDescription)")
                return
            }
            
            guard let document = snap, document.exists else {
                print("⚠️ El documento del usuario NO EXISTE en Firestore")
                return
            }
            
            // IMPRIMIR DATOS CRUDOS (Aquí sabremos la verdad)
            let datos = document.data() ?? [:]
            print("📦 DATOS EN LA NUBE: \(datos)")
            
            // Intentar decodificar
            do {
                self.user = try document.data(as: AtlertsUser.self)
                print("✅ Decodificación EXITOSA. URL en struct: \(self.user?.profileImageURL ?? "NIL")")
            } catch {
                print("💥 ERROR AL LEER EL MODELO: \(error)")
                // Esto nos dirá qué campo está fallando (puede que no sea la imagen, sino otro)
            }
        }
    }
    
    // --- NUEVAS FUNCIONES PARA FOTO DE PERFIL ---
    
    func uploadProfileImage(image: UIImage) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        guard let imageData = image.jpegData(compressionQuality: 0.5) else { return } // Comprimir a JPG (calidad 50%)
        
        isLoading = true
        errorMessage = nil
        
        // Referencia: profile_images/UID/profile.jpg
        let storageRef = storage.reference().child("profile_images/\(uid)/profile.jpg")
        
        // Metadatos para que el navegador sepa que es una imagen
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        storageRef.putData(imageData, metadata: metadata) { [weak self] metadata, error in
            guard let self = self else { return }
            
            if let error = error {
                Task { @MainActor in
                    self.isLoading = false
                    self.errorMessage = "Error al subir imagen: \(error.localizedDescription)"
                }
                return
            }
            
            // Una vez subida, obtenemos el link público
            storageRef.downloadURL { url, error in
                if let url = url {
                    // updateUserProfileImageUrl handles hopping to the main actor internally
                    self.updateUserProfileImageUrl(url: url.absoluteString)
                } else {
                    Task { @MainActor in
                        self.isLoading = false
                        self.errorMessage = "No se pudo obtener el enlace de la imagen."
                    }
                }
            }
        }
    }
    
    private func updateUserProfileImageUrl(url: String) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        // Actualizamos solo el campo profileImageURL en Firestore
        db.collection("users").document(uid).updateData([
            "profileImageURL": url
        ]) { [weak self] error in
            // Capture a weak reference by value to avoid capturing 'self' in a @Sendable context
            let weakSelf = self
            Task { @MainActor in
                guard let strongSelf = weakSelf else { return }
                strongSelf.isLoading = false
                if let error = error {
                    strongSelf.errorMessage = "Error al guardar enlace: \(error.localizedDescription)"
                } else {
                    // Éxito, el listener fetchUserProfile actualizará la vista automáticamente
                    print("Foto de perfil actualizada")
                }
            }
        }
    }
    
    // Función existente
    func signOut() {
        do {
            try Auth.auth().signOut()
        } catch {
            errorMessage = "Error al cerrar sesión"
        }
    }
    
    // AGREGAR ESTO EN: Models/ProfileViewModel.swift

    // Función para obtener datos de OTRO usuario (no el logueado)
    func getPublicUserProfile(userId: String, completion: @escaping (AtlertsUser?) -> Void) {
        let db = Firestore.firestore()
        // SOLUCIÓN APLICADA: Se agregó "completion:" y se cerraron correctamente los paréntesis
        db.collection("users").document(userId).getDocument(completion: { snapshot, error in
            guard let data = snapshot?.data(), error == nil else {
                print("Error al obtener perfil público: \(error?.localizedDescription ?? "")")
                completion(nil)
                return
            }
            
            // AQUÍ ASUMO LOS CAMPOS DE TU MODELO 'AtlertsUser'.
            // AJUSTA SI TUS NOMBRES DE VARIABLES SON DIFERENTES.
            // CORRECCIÓN: Código limpio y ordenado para evitar errores de sintaxis
        let publicUser = AtlertsUser(
            id: userId,
            uid: userId,
            name: data["name"] as? String ?? "Usuario",
            email: data["email"] as? String ?? "",
            role: data["role"] as? String ?? "user",
            profileImageURL: data["profileImageURL"] as? String ?? "",
            community: data["community"] as? String ?? ""
        )
        completion(publicUser)
        })
    }
}
