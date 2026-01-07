//
//  ChangePasswordView.swift
//  Atlerts
//
//  Created by Gabriel Rosales Montes  on 07/01/26.
//
//
//  ChangePasswordView.swift
//  Atlerts
//
//  Created by Gabriel Rosales Montes on 07/01/26.
//

import SwiftUI
import FirebaseAuth

struct ChangePasswordView: View {
    @Environment(\.presentationMode) var presentationMode
    
    // Variables para el formulario
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    
    // Estados de carga y alertas
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var alertTitle = ""
    @State private var isSuccess = false

    var body: some View {
        NavigationView {
            Form {
                // SECCIÓN 1: Seguridad Actual
                Section(header: Text("Security")
                            .textCase(.uppercase)
                            .font(.caption)
                            .foregroundColor(.gray)) {
                    SecureField("Current password", text: $currentPassword)
                }
                
                // SECCIÓN 2: Nueva Contraseña
                Section(header: Text("New password")) {
                    SecureField("New password", text: $newPassword)
                    SecureField("Confirm new password", text: $confirmPassword)
                }
                
                // SECCIÓN 3: Requisitos (Texto informativo)
                Section {
                    if !newPassword.isEmpty && newPassword.count < 6 {
                        Label("Minimum 6 characters", systemImage: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                            .font(.caption)
                    }
                }
                
                // BOTÓN DE GUARDAR
                Section {
                    Button(action: updatePassword) {
                        if isLoading {
                            HStack {
                                Spacer()
                                ProgressView()
                                Spacer()
                            }
                        } else {
                            HStack {
                                Spacer()
                                Text("Update Password")
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                Spacer()
                            }
                        }
                    }
                    .listRowBackground(Color.blue) // Botón azul
                    .disabled(isLoading || currentPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty)
                }
            }
            .navigationBarTitle("Change Password", displayMode: .inline)
            .navigationBarItems(leading: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text(alertTitle),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK")) {
                        if isSuccess {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                )
            }
        }
    }
    
    // 🔥 LÓGICA DE FIREBASE PARA CAMBIAR PASSWORD
    func updatePassword() {
        // 1. Validaciones básicas
        guard newPassword == confirmPassword else {
            alertTitle = "Error"
            alertMessage = "The new passwords do not match."
            showAlert = true
            return
        }
        
        guard newPassword.count >= 6 else {
            alertTitle = "Security"
            alertMessage = "The password must be at least 6 characters long."
            showAlert = true
            return
        }
        
        isLoading = true
        
        guard let user = Auth.auth().currentUser, let email = user.email else { return }
        
        // 2. RE-AUTENTICACIÓN (Obligatorio por seguridad en Firebase)
        let credential = EmailAuthProvider.credential(withEmail: email, password: currentPassword)
        
        user.reauthenticate(with: credential) { authResult, error in
            if let error = error {
                // Si la contraseña actual es incorrecta
                self.isLoading = false
                self.alertTitle = "Error"
                self.alertMessage = "The current password is incorrect."
                print(error.localizedDescription)
                self.showAlert = true
                return
            }
            
            // 3. SI LA RE-AUTENTICACIÓN ES EXITOSA, CAMBIAMOS EL PASSWORD
            user.updatePassword(to: self.newPassword) { error in
                self.isLoading = false
                
                if let error = error {
                    self.alertTitle = "Error"
                    self.alertMessage = error.localizedDescription
                    self.showAlert = true
                } else {
                    self.alertTitle = "¡Success!"
                    self.alertMessage = "Your password has been successfully updated."
                    self.isSuccess = true
                    self.showAlert = true
                }
            }
        }
    }
}
