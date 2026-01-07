//
//  AboutView.swift
//  Atlerts
//
//  Created by Gabriel Rosales Montes  on 07/01/26.
//
//
//  AboutView.swift
//  Atlerts
//
//  Created by Gabriel Rosales Montes on 07/01/26.
//

import SwiftUI

struct AboutView: View {
    @Environment(\.presentationMode) var presentationMode
    
    // Obtener la versión real de la App desde el sistema
    let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"

    var body: some View {
        ZStack {
            // Fondo gris muy suave para dar limpieza
            Color(UIColor.systemGroupedBackground).ignoresSafeArea()
            
            VStack(spacing: 30) {
                
                // 1. HEADER CON LOGO
                VStack(spacing: 20) {
                    Image("atlerts-name-logo") // Asegúrate de usar tu logo a color o el que prefieras
                        .resizable()
                        .scaledToFit()
                        .frame(width: 180, height: 80)
                        .padding(.top, 40)
                    
                    Text("Version \(appVersion) (Build \(buildNumber))")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                // 2. DESCRIPCIÓN
                VStack(spacing: 10) {
                    Text("by Atlas Senior Living")
                        .font(.headline)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                    
                    Text("This app connects the entire Atlas Senior Living team, facilitating communication, documents, and important announcements in real time.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)
                }
                
                Spacer()
                
                // 3. CRÉDITOS / COPYRIGHT
                VStack(spacing: 5) {
                    Text("Designed & Developed by Gabriel Rosales Montes\n for the Atlas Digital Marketing Team")
                        .font(.caption2)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                    
                    Text("Atlas Senior Living")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("© 2026 All Rights Reserved")
                        .font(.caption2)
                        .foregroundColor(.gray)
                        .padding(.top, 5)
                }
                .padding(.bottom, 30)
            }
        }
        // Si quieres una barra de navegación con título
        .navigationBarTitle("About Atlerts", displayMode: .inline)
    }
}
