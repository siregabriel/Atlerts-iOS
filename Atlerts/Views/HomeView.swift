//
//  HomeView.swift
//  Atlerts
//
//  Created by Gabriel Rosales Montes  on 04/01/26.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import Combine

// 1. VIEW MODEL
class HomeViewModel: ObservableObject {
    @Published var userName: String = "Atlas Team"
    
    // Variables para el bloque de Novedades
    @Published var newsTitle: String = "Novedades Atlas"
    @Published var newsBody: String = "Recuerda revisar los nuevos protocolos de seguridad en la sección de Documentos."
    
    // 🔥 NUEVO: Variable de estado para controlar la carga
    @Published var isLoading: Bool = true
    
    private var db = Firestore.firestore()
    
    // --- LÓGICA DE ESTACIONES AUTOMÁTICA ---
    var currentTheme: String {
        let date = Date()
        let calendar = Calendar.current
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)
        
        if (month == 12 && day == 31) || (month == 1 && day == 1) { return "party" }
        if month == 12 || month == 1 || month == 2 { return "snow" }
        if month >= 3 && month <= 5 { return "flowers" }
        if month >= 6 && month <= 9 { return "sun" }
        if month == 10 || month == 11 { return "leaves" }
        
        return "none"
    }
    
    func fetchData() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        // A. OBTENER NOMBRE
        db.collection("users").document(uid).getDocument { snap, _ in
            if let data = snap?.data(), let name = data["name"] as? String {
                let firstName = name.components(separatedBy: " ").first ?? name
                self.userName = firstName
            }
        }
        
        // B. OBTENER NOTICIAS
        db.collection("app_settings").document("home_content").addSnapshotListener { snap, error in
            // Cuando recibimos datos, apagamos el esqueleto
            if let data = snap?.data() {
                if let title = data["title"] as? String, !title.isEmpty { self.newsTitle = title }
                if let body = data["body"] as? String, !body.isEmpty { self.newsBody = body }
            }
            
            // Pequeño retraso visual para que se aprecie la animación (opcional, se siente más premium)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation {
                    self.isLoading = false
                }
            }
        }
    }
}

// 2. MOTOR DE EFECTOS (PARTÍCULAS)
struct ParticleEffectView: View {
    let type: String
    @State private var particles: [Particle] = []
    
    struct Particle: Identifiable {
        let id = UUID()
        var x: CGFloat; var y: CGFloat; var speed: CGFloat; var size: CGFloat; var rotation: Double; var opacity: Double
    }
    
    var config: (icon: String, color: Color) {
        switch type {
        case "snow": return ("snowflake", .white)
        case "leaves": return ("leaf.fill", .orange)
        case "party": return ("confetti.fill", .yellow)
        case "flowers": return ("camera.macro", .pink)
        case "sun": return ("sun.max.fill", .yellow)
        default: return ("", .clear)
        }
    }
    
    let timer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(particles) { particle in
                    Image(systemName: config.icon)
                        .font(.system(size: particle.size))
                        .foregroundColor(config.color)
                        .position(x: particle.x, y: particle.y)
                        .rotationEffect(.degrees(particle.rotation))
                        .opacity(particle.opacity)
                }
            }
            .onReceive(timer) { _ in
                if particles.count < 30 && Int.random(in: 0...5) == 0 {
                    let size = CGFloat.random(in: 12...24)
                    particles.append(Particle(x: CGFloat.random(in: 0...geo.size.width), y: -50, speed: CGFloat.random(in: 2...5), size: size, rotation: Double.random(in: 0...360), opacity: Double.random(in: 0.5...0.9)))
                }
                for i in particles.indices {
                    particles[i].y += particles[i].speed
                    particles[i].rotation += 2
                    if type == "leaves" || type == "flowers" { particles[i].x += sin(particles[i].y / 40) * 1.0 }
                }
                particles.removeAll { $0.y > geo.size.height + 50 }
            }
        }
        .allowsHitTesting(false)
    }
}

// 3. VISTA PRINCIPAL
struct HomeView: View {
    @StateObject var viewModel = HomeViewModel()
    
    var body: some View {
        NavigationView {
            ZStack {
                // ================= FONDO =================
                Image("atlerts-app-home-background")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                // =========================================
                
                ScrollView {
                    VStack(spacing: 25) {
                        
                        // HEADER
                        HStack {
                            VStack(alignment: .leading, spacing: 5) {
                                Text("Welcome back,")
                                    .font(.subheadline).foregroundColor(Color.white).textCase(.uppercase)
                                    .shadow(color: Color.black.opacity(0.5), radius: 5, x: 2, y: 2)
                                Text(viewModel.userName)
                                    .font(.system(size: 34, weight: .bold)).foregroundColor(Color.white)
                                    .shadow(color: Color.black.opacity(0.5), radius: 5, x: 2, y: 2)
                            }
                            Spacer()
                            Image("atlas-white")
                                .resizable().frame(width: 180, height: 60)
                                .foregroundColor(.blue).opacity(0.8)
                                .shadow(color: Color.black.opacity(0.5), radius: 5, x: 2, y: 2)
                        }
                        .padding(.horizontal).padding(.top, 90)
                        
                        // =======================================================
                        // 💀 AQUÍ ESTÁ EL BLOQUE 2: SKELETON VS REAL CARD 💀
                        // =======================================================
                        
                        if viewModel.isLoading {
                            // --- ESTADO DE CARGA (SKELETON) ---
                            ZStack {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.white.opacity(0.2)) // Fondo base
                                
                                VStack(alignment: .leading, spacing: 15) {
                                    // Simula Título
                                    HStack {
                                        Circle().frame(width: 20, height: 20).opacity(0.3)
                                        RoundedRectangle(cornerRadius: 4).frame(width: 120, height: 20).opacity(0.3)
                                    }
                                    // Simula Texto
                                    VStack(alignment: .leading, spacing: 8) {
                                        RoundedRectangle(cornerRadius: 4).frame(height: 12).opacity(0.3)
                                        RoundedRectangle(cornerRadius: 4).frame(width: 200, height: 12).opacity(0.3)
                                        RoundedRectangle(cornerRadius: 4).frame(width: 150, height: 12).opacity(0.3)
                                    }
                                }
                                .padding(20)
                            }
                            .frame(height: 150)
                            .padding(.horizontal)
                            .skeletonLoading() // <--- EL EFECTO DE BRILLO (Viene de Utils.swift)
                            
                        } else {
                            // --- ESTADO REAL (TARJETA CON DATOS) ---
                            ZStack {
                                // 1. Fondo Degradado
                                LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.9), Color.purple.opacity(0.9)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                                
                                // 2. EFECTO AUTOMÁTICO
                                if viewModel.currentTheme != "none" {
                                    ParticleEffectView(type: viewModel.currentTheme)
                                        .mask(RoundedRectangle(cornerRadius: 16))
                                }
                                
                                // 3. Contenido de Texto
                                VStack(alignment: .leading, spacing: 10) {
                                    HStack {
                                        Image(systemName: "star.fill").foregroundColor(.yellow)
                                        Text(viewModel.newsTitle)
                                            .font(.headline).foregroundColor(.white)
                                    }
                                    Text(viewModel.newsBody)
                                        .font(.subheadline)
                                        .foregroundColor(.white.opacity(0.9))
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .cornerRadius(16)
                            .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                            .padding(.horizontal)
                            .transition(.opacity) // Transición suave al aparecer
                        }
                        
                        // --- ENLACES RÁPIDOS ---
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Apps & Shortcuts").font(.headline).padding(.horizontal).foregroundColor(Color.white)
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 15) {
                                ExternalLinkCard(title: "Payactive", icon: "payactive-logo", color: .green, url: "https://www.paychex.com/login")
                                ExternalLinkCard(title: "Paychex", icon: "paychex-logo", color: .orange, url: "https://login.reliaslearning.com")
                                ExternalLinkCard(title: "Relias", icon: "relias-logo", color: .blue, url: "https://atlasseniorliving.com")
                                //ExternalLinkCard(title: "Support", icon: "wrench.and.screwdriver.fill", color: .gray, url: "https://google.com")
                            }
                            .padding(.horizontal)
                        }
                        Spacer()
                    }
                    .padding(.bottom, 30)
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                viewModel.fetchData()
            }
        }
    }
}

// 4. COMPONENTE TARJETA (CON VIBRACIÓN HÁPTICA 📳)
struct ExternalLinkCard: View {
    let title: String, icon: String, color: Color, url: String
    
    var body: some View {
        Link(destination: URL(string: url)!) {
            VStack(spacing: 12) {
                if UIImage(named: icon) != nil {
                    Image(icon)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 60, height: 60)
                        .clipShape(Circle())
                        .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
                } else {
                    Image(systemName: icon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                        .foregroundColor(color)
                }
                
                Text(title)
                    .font(.footnote)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(Color.white.opacity(0.5))
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
        // 🔥 ESTA LÍNEA AÑADE LA VIBRACIÓN AL TOCAR 🔥
        .simultaneousGesture(TapGesture().onEnded {
            haptic(.medium)
        })
    }
}
