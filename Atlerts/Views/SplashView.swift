//
//  SplashView.swift
//  Atlerts
//
//  Created by Gabriel Rosales Montes on 04/01/26.
//

import SwiftUI
import AVFoundation // 👈 Importante para el audio

struct SplashView: View {
    @State private var appear = false
    @State private var turnWhite = false
    
    // Variable para controlar el reproductor de sonido
    @State private var audioPlayer: AVAudioPlayer?
    
    let goldColor = Color(red: 0.85, green: 0.65, blue: 0.13)
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack {
                Image("atlas-white")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 250)
                    .colorMultiply(turnWhite ? Color.white : goldColor)
                    .shadow(color: turnWhite ? .clear : goldColor.opacity(0.5), radius: 10)
                    .scaleEffect(appear ? 1.0 : 1.15)
                    .offset(y: appear ? 0 : 20)
                    .blur(radius: appear ? 0 : 10)
                    .opacity(appear ? 1.0 : 0.0)
            }
        }
        .onAppear {
            // 1. REPRODUCIR SONIDO SUAVE
            playIntroSound()
            
            // 2. ANIMACIÓN FÍSICA
            withAnimation(.easeOut(duration: 1.6)) {
                appear = true
            }
            
            // 3. TRANSICIÓN A BLANCO
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.easeInOut(duration: 1.0)) {
                    turnWhite = true
                }
            }
        }
    }
    
    // 🔊 FUNCIÓN PARA EL SONIDO DE ENTRADA
    func playIntroSound() {
        // Busca un archivo llamado "intro.mp3" (o .wav) en tu proyecto
        if let soundURL = Bundle.main.url(forResource: "intro", withExtension: "mp3") {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
                audioPlayer?.volume = 0.5 // Volumen suave (50%)
                audioPlayer?.prepareToPlay()
                audioPlayer?.play()
            } catch {
                print("Error al reproducir intro: \(error)")
            }
        }
    }
}
