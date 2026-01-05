//
//  MaintenanceView.swift
//  Atlerts
//
//  Created by Gabriel Rosales Montes  on 05/01/26.
//
import SwiftUI

struct MaintenanceView: View {
    var body: some View {
        ZStack {
            Color(red: 0.8, green: 0, blue: 0) // Fondo rojo intenso
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.white)
                
                Text("Under Maintenance")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("We are improving the app.\nWe will come back soon.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white.opacity(0.8))
                    .padding()
            }
        }
    }
}
