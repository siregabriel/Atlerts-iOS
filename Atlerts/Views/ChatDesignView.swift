//
//  ChatDesignView.swift
//  Atlerts
//  Atlas Senior Living
//  Created by Gabriel Rosales Montes  on 31/12/25.
//  Digital Products Team

import SwiftUI

// --- 1. MODELO DE DATOS FALSO (MOCK DATA) ---
// Esto solo sirve para poder previsualizar el diseño sin conectar a Firebase aún.
struct MockMessage: Identifiable {
    let id = UUID()
    let isFromCurrentUser: Bool // ¿Lo envié yo?
    let textContent: String?    // Texto opcional
    let hasImage: Bool          // Simula si tiene imagen adjunta
}

// Un array con ejemplos de conversaciones
let sampleMessages: [MockMessage] = [
    MockMessage(isFromCurrentUser: false, textContent: "Enrollment is open now.", hasImage: false),
    MockMessage(isFromCurrentUser: true, textContent: "¡Thanks!", hasImage: false),
    MockMessage(isFromCurrentUser: false, textContent: "Picture is blurry, so we need to retake.", hasImage: true),
    MockMessage(isFromCurrentUser: true, textContent: "Got it", hasImage: false),
    MockMessage(isFromCurrentUser: true, textContent: nil, hasImage: true) // Mensaje que es solo imagen
]
// MARK: - BURBUJA
// --- 2. COMPONENTE: LA BURBUJA DEL MENSAJE ---
struct MessageBubbleView: View {
    let message: MockMessage
    
    var body: some View {
        HStack {
            // Truco de alineación: Si es MÍO, pongo un Spacer a la izquierda para empujarlo a la derecha
            if message.isFromCurrentUser { Spacer() }
            
            VStack(alignment: message.isFromCurrentUser ? .trailing : .leading, spacing: 8) {
                
                // A. Si tiene imagen, mostramos el placeholder
                if message.hasImage {
                    // En la app real, aquí iría: AsyncImage(url: URL(string: message.imageUrl))
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 200, height: 150) // Tamaño fijo para el preview
                        .overlay(
                            Image(systemName: "photo")
                                .foregroundColor(.gray)
                        )
                }
                
                // B. Si tiene texto, lo mostramos
                if let text = message.textContent {
                    Text(text)
                        .foregroundColor(message.isFromCurrentUser ? .white : .primary)
                }
            }
            .padding(12)
            // Colores de fondo según quién envía
            .background(message.isFromCurrentUser ? Color.blue : Color.gray.opacity(0.15))
            // Bordes redondeados estilo chat moderno
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            // Un pequeño margen lateral para que no pegue al borde de la pantalla
            .padding(message.isFromCurrentUser ? .leading : .trailing, 60)
            
            // Truco de alineación: Si NO es mío, pongo el Spacer a la derecha.
            if !message.isFromCurrentUser { Spacer() }
        }
    }
}

// --- 3. PANTALLA PRINCIPAL DEL CHAT ---
struct ChatDesignScreen: View {
    @State private var typingMessage: String = ""
    
    var body: some View {
        NavigationView {
            VStack {
                // --- Área de Scroll de Mensajes ---
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(sampleMessages) { message in
                                MessageBubbleView(message: message)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 10)
                    }
                }
                
                // --- Barra Inferior de Entrada (Input Bar) ---
                HStack(spacing: 12) {
                    // Botón de subir foto
                    Button(action: {
                        print("Abrir selector de fotos")
                    }) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 22))
                            .foregroundColor(.blue)
                    }
                    
                    // Campo de texto
                    TextField("Write a message...", text: $typingMessage)
                        .padding(10)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(20)
                    
                    // Botón de enviar
                    Button(action: {
                        print("Send: \(typingMessage)")
                        typingMessage = ""
                    }) {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 22))
                            // El botón se pone azul solo si hay texto escrito
                            .foregroundColor(typingMessage.isEmpty ? .gray : .blue)
                    }
                    .disabled(typingMessage.isEmpty)
                }
                .padding()
                .background(Color.white.ignoresSafeArea(edges: .bottom))
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: -5)
            }
            .navigationTitle("Atlas Senior Living")
#if !os(macOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
        }
    }
}

// --- PREVIEW PARA XCODE ---
struct ChatDesignScreen_Previews: PreviewProvider {
    static var previews: some View {
        ChatDesignScreen()
        // Puedes descomentar esto para ver cómo se ve en modo oscuro:
        //.preferredColorScheme(.dark)
    }
}

