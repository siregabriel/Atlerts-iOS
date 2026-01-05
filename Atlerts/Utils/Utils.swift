import SwiftUI

// 1. EFECTO DE CARGA (SHIMMER) - Ya lo tenías
struct ShimmerEffect: ViewModifier {
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geo in
                    Color.white.opacity(0.4)
                        .mask(
                            Rectangle()
                                .fill(
                                    LinearGradient(gradient: Gradient(colors: [.clear, .white.opacity(0.5), .clear]), startPoint: .leading, endPoint: .trailing)
                                )
                                .rotationEffect(.degrees(30))
                                .offset(x: -geo.size.width + (phase * geo.size.width * 3))
                        )
                }
            )
            .mask(content)
            .onAppear {
                withAnimation(Animation.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }
}

// 2. EXTENSIÓN MÁGICA PARA VIBRACIÓN 📳
// Esto nos permite llamar a 'haptic(.light)' o 'haptic(.success)' desde cualquier vista.
func haptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
    let generator = UIImpactFeedbackGenerator(style: style)
    generator.impactOccurred()
}

func hapticSuccess() {
    let generator = UINotificationFeedbackGenerator()
    generator.notificationOccurred(.success)
}

func hapticError() {
    let generator = UINotificationFeedbackGenerator()
    generator.notificationOccurred(.error)
}

// Extensiones de View
extension View {
    func skeletonLoading() -> some View {
        modifier(ShimmerEffect())
    }
}
