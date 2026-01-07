//
//  ViewModifiers.swift
//  Atlerts
//
//  Created by Gabriel Rosales Montes.
//

import SwiftUI

// =========================================================
// 1. EXTENSIONES (Para usar los efectos fácilmente)
// =========================================================
extension View {
    
    /// Agrega un efecto de brillo (Shimmer) que pasa sobre la vista.
    /// Uso: .shimmering()
    func shimmering(active: Bool = true, duration: Double = 1.5, bounce: Bool = false) -> some View {
        self.modifier(AtlasShimmer(active: active, duration: duration, bounce: bounce))
    }
    
    /// Agrega un efecto de "Magia" con estrellitas y resplandor.
    /// Uso: .magicalSparkles()
    func magicalSparkles() -> some View {
        self.modifier(SparkleEffect())
    }
}

// =========================================================
// 2. EFECTO SHIMMER (Brillo en movimiento)
// =========================================================
struct AtlasShimmer: ViewModifier {
    var active: Bool
    var duration: Double
    var bounce: Bool
    
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geo in
                    LinearGradient(
                        gradient: Gradient(colors: [
                            .clear,
                            .white.opacity(0.6), // Color del brillo
                            .clear
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .frame(width: geo.size.width * 2) // Doble ancho para el recorrido
                    .offset(x: active ? phase : -geo.size.width)
                    .onAppear {
                        if active {
                            var animation = Animation.linear(duration: duration)
                            if !bounce {
                                animation = animation.repeatForever(autoreverses: false)
                            } else {
                                animation = animation.repeatForever(autoreverses: true)
                            }
                            
                            withAnimation(animation) {
                                phase = geo.size.width
                            }
                        }
                    }
                }
                // Usamos la vista original como máscara para que el brillo no se salga
                .mask(content)
            )
    }
}

// =========================================================
// 3. EFECTO SPARKLE (Estrellitas Mágicas)
// =========================================================
struct SparkleEffect: ViewModifier {
    func body(content: Content) -> some View {
        ZStack {
            // A. El contenido original (El logo) con un resplandor detrás (Glow)
            content
                .shadow(color: .white.opacity(0.6), radius: 8, x: 0, y: 0)
            
            // B. Estrellitas posicionadas manualmente alrededor
            
            // Arriba Izquierda
            SingleStar(delay: 0.0, size: 10)
                .offset(x: -40, y: -15)
            
            // Arriba Derecha
            SingleStar(delay: 0.5, size: 12)
                .offset(x: 45, y: -20)
            
            // Abajo Izquierda
            SingleStar(delay: 1.0, size: 8)
                .offset(x: -35, y: 15)
            
            // Abajo Derecha
            SingleStar(delay: 1.5, size: 10)
                .offset(x: 50, y: 10)
            
            // Una extra brillante arriba centro
            SingleStar(delay: 0.8, size: 14)
                .offset(x: 0, y: -25)
        }
    }
}

// =========================================================
// 4. COMPONENTE ESTRELLA INDIVIDUAL
// =========================================================
struct SingleStar: View {
    var delay: Double
    var size: CGFloat = 12
    @State private var isAnimating = false

    var body: some View {
        Image(systemName: "sparkle") // Icono nativo de SF Symbols
            .font(.system(size: size))
            .foregroundColor(.white)
            // Animaciones de escala, opacidad y rotación
            .scaleEffect(isAnimating ? 1.0 : 0.0)
            .opacity(isAnimating ? 1.0 : 0.0)
            .rotationEffect(.degrees(isAnimating ? 15 : -15))
            .onAppear {
                withAnimation(
                    Animation.easeInOut(duration: 1.2)
                        .repeatForever(autoreverses: true)
                        .delay(delay) // Cada estrella empieza en un tiempo diferente
                ) {
                    isAnimating = true
                }
            }
    }
}
