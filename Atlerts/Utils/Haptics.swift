//
//  Haptics.swift
//  Atlerts
//
//  Created by Gabriel Rosales Montes  on 07/01/26.
//
import SwiftUI
import UIKit

class Haptics {
    static let shared = Haptics()
    
    private init() { }

    // 1. GOLPE SECO (Para botones, likes, enviar mensaje)
    // Estilos: .light (suave), .medium (normal), .heavy (fuerte/sólido)
    func play(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }

    // 2. NOTIFICACIÓN (Para éxitos o errores)
    // Tipos: .success (dos toques suaves), .warning, .error
    func notify(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }
}
