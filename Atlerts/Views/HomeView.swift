//
//  HomeView.swift
//  Atlerts
//
//  Created by Gabriel Rosales Montes on 04/01/26.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import Combine
import EventKit
import AVFoundation

// ---------------------------------------------------------
// 1. MODELO DE DATOS
// ---------------------------------------------------------

// A. Modelo para Eventos
struct HomeCalendarEvent: Identifiable {
    let id: String
    let title: String
    let date: Date
    let icon: String
    let description: String
    let location: String
    
    var dayString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        formatter.locale = Locale(identifier: "es_ES")
        return formatter.string(from: date).uppercased()
    }
    
    var timeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    var fullDateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.locale = Locale(identifier: "es_ES")
        return formatter.string(from: date).capitalized
    }
}

// B. Modelo para Broadcasts (Anuncios)
struct HomeBroadcast: Identifiable {
    let id: String
    let text: String
    let sender: String
    let date: Date
    let imageUrl: String?
    
    // CAMPOS PARA ARCHIVOS
    let fileUrl: String?
    let fileName: String?
    let fileType: String?
    
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    var fullDateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// ---------------------------------------------------------
// 2. VIEW MODEL
// ---------------------------------------------------------
class HomeViewModel: ObservableObject {
    @Published var userName: String = "Atlas Team"
    @Published var newsTitle: String = "Novedades Atlas"
    @Published var newsBody: String = "Cargando información..."
    @Published var events: [HomeCalendarEvent] = []
    @Published var isLoading: Bool = true
    @Published var remoteTheme: String = "normal"
    @Published var showWelcomeCard: Bool = true
    @Published var latestBroadcast: HomeBroadcast? = nil
    
    // 🔥 NUEVO: VARIABLE PARA EL GLOBO ROJO
    @Published var hasUnreadSuccess: Bool = false
    
    // VARIABLES DE AUDIO
    var audioPlayer: AVAudioPlayer?
    private var isFirstLoad = true
    
    private var db = Firestore.firestore()
    
    // Lógica Híbrida: Web > Fechas
    var currentTheme: String {
        let adminMood = remoteTheme.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        if adminMood == "normal" || adminMood == "none" || adminMood.isEmpty {
            return automaticSeasonalTheme
        }
        
        if adminMood == "navidad" || adminMood == "christmas" || adminMood == "snow" { return "snow" }
        if adminMood == "otoño" || adminMood == "autumn" || adminMood == "leaves" { return "leaves" }
        if adminMood == "fiesta" || adminMood == "party" { return "party" }
        if adminMood == "primavera" || adminMood == "spring" { return "flowers" }
        if adminMood == "verano" || adminMood == "summer" { return "sun" }
        
        return automaticSeasonalTheme
    }
    
    var automaticSeasonalTheme: String {
        let date = Date()
        let calendar = Calendar.current
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)
        
        if (month == 12 && day == 31) || (month == 1 && day == 1) { return "party" }
        if month == 12 || month == 1 || month == 2 { return "snow" }
        if month >= 3 && month <= 5 { return "flowers" }
        if month >= 6 && month <= 8 { return "sun" }
        if month >= 9 && month <= 11 { return "leaves" }
        
        return "none"
    }
    
    func fetchData() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        // 1. Usuario
        db.collection("users").document(uid).getDocument { snap, _ in
            if let data = snap?.data(), let name = data["name"] as? String {
                let firstName = name.components(separatedBy: " ").first ?? name
                self.userName = firstName
            }
        }
        
        // 2. Configuración Home (Welcome Card)
        db.collection("app_settings").document("home_content").addSnapshotListener { snap, error in
            if let data = snap?.data() {
                let t1 = data["title"] as? String
                let t2 = data["titulo"] as? String
                let t3 = data["header"] as? String
                self.newsTitle = t1 ?? t2 ?? t3 ?? "Novedades Atlas"
                
                let b1 = data["body"] as? String
                let b2 = data["content"] as? String
                let b3 = data["message"] as? String
                self.newsBody = b1 ?? b2 ?? b3 ?? "Información pendiente..."
                
                let m1 = data["mood"] as? String
                let m2 = data["theme"] as? String
                let m3 = data["ambientacion"] as? String
                self.remoteTheme = m1 ?? m2 ?? m3 ?? "normal"
                
                self.showWelcomeCard = data["isVisible"] as? Bool ?? true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation { self.isLoading = false }
            }
        }
        
        // 3. Eventos Calendario
        let startOfToday = Calendar.current.startOfDay(for: Date())
        db.collection("events")
            .whereField("date", isGreaterThanOrEqualTo: startOfToday)
            .order(by: "date", descending: false)
            .limit(to: 5)
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else { self.events = []; return }
                
                let fetchedEvents = documents.compactMap { doc -> HomeCalendarEvent? in
                    let data = doc.data()
                    let title = data["title"] as? String ?? "Evento Atlas"
                    let description = data["description"] as? String ?? "Sin detalles."
                    let location = data["location"] as? String ?? ""
                    
                    var eventDate = Date()
                    if let timestamp = data["date"] as? Timestamp {
                        eventDate = timestamp.dateValue()
                    } else if let dateString = data["date"] as? String {
                        let formatter = ISO8601DateFormatter()
                        eventDate = formatter.date(from: dateString) ?? Date()
                    }
                    
                    if eventDate < startOfToday { return nil }
                    let icon = data["icon"] as? String ?? "calendar"
                    
                    return HomeCalendarEvent(id: doc.documentID, title: title, date: eventDate, icon: icon, description: description, location: location)
                }
                self.events = fetchedEvents
            }
        
        // 4. Último Broadcast (Limit 1)
        db.collection("broadcasts")
            .order(by: "timestamp", descending: true)
            .limit(to: 1)
            .addSnapshotListener { snapshot, error in
                guard let doc = snapshot?.documents.first else {
                    self.latestBroadcast = nil
                    return
                }
                
                // Detectar si es nuevo para sonar
                let newId = doc.documentID
                
                if !self.isFirstLoad, let currentId = self.latestBroadcast?.id, currentId != newId {
                    self.reproducirSonidoPersonalizado()
                }
                
                let data = doc.data()
                let text = data["text"] as? String ?? "No content"
                let sender = data["senderName"] as? String ?? "Admin"
                let imgUrl = data["imageUrl"] as? String
                let fileUrl = data["fileUrl"] as? String
                let fileName = data["fileName"] as? String
                let fileType = data["fileType"] as? String
                
                // 🔥 NUEVO: DETECTAR SI ES DE WYMAN Y NO SE HA VISTO
                if sender.lowercased().contains("wyman") && imgUrl != nil {
                    let lastSeenId = UserDefaults.standard.string(forKey: "lastSeenWymanPostId")
                    if lastSeenId != newId {
                        DispatchQueue.main.async { self.hasUnreadSuccess = true }
                    }
                }
                
                var date = Date()
                if let ts = data["timestamp"] as? Timestamp { date = ts.dateValue() }
                
                self.latestBroadcast = HomeBroadcast(
                    id: newId,
                    text: text,
                    sender: sender,
                    date: date,
                    imageUrl: imgUrl,
                    fileUrl: fileUrl,
                    fileName: fileName,
                    fileType: fileType
                )
                
                self.isFirstLoad = false
            }
    }
    
    // 🔥 NUEVA FUNCIÓN: MARCAR COMO LEÍDO
    func markSuccessWallAsRead() {
        if let latestId = latestBroadcast?.id {
            UserDefaults.standard.set(latestId, forKey: "lastSeenWymanPostId")
            DispatchQueue.main.async { self.hasUnreadSuccess = false }
        }
    }
    
    // FUNCIÓN PARA TOCAR EL SONIDO
    func reproducirSonidoPersonalizado() {
        if let soundURL = Bundle.main.url(forResource: "atlertsAlert", withExtension: "mp3") {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
                audioPlayer?.prepareToPlay()
                audioPlayer?.play()
            } catch {
                print("Error al reproducir sonido: \(error)")
            }
        }
    }
}

// ---------------------------------------------------------
// 3. MOTOR DE EFECTOS
// ---------------------------------------------------------
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
        case "party": return ("balloon.2.fill", .yellow)
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

// ---------------------------------------------------------
// ICONO ANIMADO (BROADCAST)
// ---------------------------------------------------------
struct BroadcastAnimatedIcon: View {
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.orange.opacity(0.5), lineWidth: 2)
                .frame(width: 45, height: 45)
                .scaleEffect(isAnimating ? 1.4 : 1.0)
                .opacity(isAnimating ? 0 : 1)
            
            Circle()
                .fill(LinearGradient(gradient: Gradient(colors: [Color.orange, Color.red.opacity(0.8)]), startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 48, height: 48)
                .shadow(color: .orange.opacity(0.4), radius: 4, x: 0, y: 3)
            
            Image(systemName: "megaphone.fill")
                .foregroundColor(.white)
                .font(.system(size: 22))
                .rotationEffect(.degrees(isAnimating ? -10 : 0))
        }
        .onAppear {
            withAnimation(Animation.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}

// ---------------------------------------------------------
// 4. VISTA PRINCIPAL
// ---------------------------------------------------------
struct HomeView: View {
    @StateObject var viewModel = HomeViewModel()
    
    init() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = .clear
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Image("atlerts-app-home-background")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                
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
                                //.magicalSparkles()//activar en Navidad
                        }
                        .padding(.horizontal).padding(.top, 90)
                        
                        // NOVEDADES
                        if viewModel.showWelcomeCard {
                            if viewModel.isLoading {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.2))
                                    VStack(alignment: .leading, spacing: 15) {
                                        HStack {
                                            Circle().frame(width: 20, height: 20).opacity(0.3)
                                            RoundedRectangle(cornerRadius: 4).frame(width: 120, height: 20).opacity(0.3)
                                        }
                                        VStack(alignment: .leading, spacing: 8) {
                                            RoundedRectangle(cornerRadius: 4).frame(height: 12).opacity(0.3)
                                            RoundedRectangle(cornerRadius: 4).frame(width: 200, height: 12).opacity(0.3)
                                        }
                                    }.padding(20)
                                }
                                .frame(height: 150)
                                .padding(.horizontal)
                                .skeletonLoading()
                            } else {
                                ZStack {
                                    LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.9), Color.purple.opacity(0.9)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                                    
                                    if viewModel.currentTheme != "none" {
                                        ParticleEffectView(type: viewModel.currentTheme)
                                            .mask(RoundedRectangle(cornerRadius: 16))
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 10) {
                                        HStack {
                                            Image(systemName: "star.fill").foregroundColor(.yellow)
                                            Text(viewModel.newsTitle).font(.headline).foregroundColor(.white)
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
                                .transition(.opacity)
                            }
                        }
                        
                        // 🔥 BOTÓN ESPECIAL: WALL OF SUCCESS (WYMAN) CON GLOBO ROJO 🔥
                        NavigationLink(destination: SuccessWallView()
                            .onAppear {
                                // Al entrar, se marca como leído
                                viewModel.markSuccessWallAsRead()
                            }
                        ) {
                            ZStack(alignment: .topTrailing) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 0) {
                                        Text("WYMAN'S WALL OF")
                                            .font(.system(size: 11, weight: .heavy))
                                            .tracking(0.5)
                                            .foregroundColor(Color.black.opacity(0.5))
                                            .textCase(.uppercase)
                                            .lineLimit(1)
                                        
                                        Text("SUCCESS")
                                            .font(.system(size: 25, weight: .black, design: .serif))
                                            .foregroundColor(.black)
                                            .offset(y: -3)
                                    }
                                    
                                    Spacer()
                                    
                                    TrophyAnimatedIcon()
                                }
                                .padding(.vertical, 16)
                                .padding(.horizontal, 20)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color(red: 0.95, green: 0.85, blue: 0.50),
                                            Color(red: 0.85, green: 0.65, blue: 0.13)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .cornerRadius(16)
                                .shadow(color: Color(red: 0.85, green: 0.65, blue: 0.13).opacity(0.4), radius: 8, x: 0, y: 4)
                                
                                // 🔴 EL GLOBO ROJO
                                if viewModel.hasUnreadSuccess {
                                    ZStack {
                                        Circle()
                                            .fill(Color.red)
                                            .frame(width: 24, height: 24)
                                            .shadow(radius: 2)
                                        
                                        Text("1")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(.white)
                                    }
                                    .offset(x: 5, y: -8)
                                    .transition(.scale.combined(with: .opacity))
                                }
                            }
                            .padding(.horizontal)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.bottom, 10)
                        
                        // SHORTCUTS
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Apps & Shortcuts").font(.headline).padding(.horizontal).foregroundColor(Color.white)
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 15) {
                                ExternalLinkCard(title: "Payactive", icon: "payactive-logo", color: .green, url: "https://www.paychex.com/login")
                                ExternalLinkCard(title: "Paychex", icon: "paychex-logo", color: .orange, url: "https://login.reliaslearning.com")
                                ExternalLinkCard(title: "Relias", icon: "relias-logo", color: .blue, url: "https://atlasseniorliving.com")
                            }
                            .padding(.horizontal)
                        }
                        
                        // LATEST ANNOUNCEMENT
                        if let broadcast = viewModel.latestBroadcast {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Latest Announcement")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding(.horizontal)
                                
                                NavigationLink(destination: BroadcastDetailView(broadcast: broadcast)) {
                                    HStack(alignment: .top, spacing: 15) {
                                        BroadcastAnimatedIcon()
                                        
                                        VStack(alignment: .leading, spacing: 5) {
                                            Text(broadcast.text)
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                                .foregroundColor(.white)
                                                .lineLimit(3)
                                                .multilineTextAlignment(.leading)
                                            
                                            HStack {
                                                Text(broadcast.sender)
                                                    .font(.caption2)
                                                    .fontWeight(.bold)
                                                    .foregroundColor(.white.opacity(0.8))
                                                
                                                Text("• \(broadcast.timeAgo)")
                                                    .font(.caption2)
                                                    .foregroundColor(.gray)
                                            }
                                        }
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(.white.opacity(0.3))
                                            .padding(.top, 15)
                                    }
                                    .padding()
                                    .background(Color.white.opacity(0.15))
                                    .cornerRadius(16)
                                    .padding(.horizontal)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        
                        // CALENDARIO
                        if !viewModel.events.isEmpty {
                            CalendarSectionView(events: viewModel.events)
                        }
                        
                        Spacer()
                    }
                    .padding(.bottom, 30)
                }
                .background(Color.clear)
            }
            .navigationViewStyle(StackNavigationViewStyle())
            .accentColor(.white)
        }
        .onAppear { viewModel.fetchData() }
        .preferredColorScheme(.dark)
    }
}

// ---------------------------------------------------------
// 5. COMPONENTES EXTERNOS
// ---------------------------------------------------------
struct ExternalLinkCard: View {
    let title: String, icon: String, color: Color, url: String
    
    var body: some View {
        Link(destination: URL(string: url)!) {
            VStack(spacing: 12) {
                if UIImage(named: icon) != nil {
                    Image(icon)
                        .resizable().scaledToFill().frame(width: 60, height: 60)
                        .clipShape(Circle())
                        .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
                } else {
                    Image(systemName: icon)
                        .resizable().scaledToFit().frame(width: 40, height: 40)
                        .foregroundColor(color)
                }
                Text(title).font(.footnote).fontWeight(.bold).foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(Color.white.opacity(0.5))
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
        .simultaneousGesture(TapGesture().onEnded { haptic(.medium) })
    }
}

struct CalendarSectionView: View {
    var events: [HomeCalendarEvent]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Upcoming Events")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal)
            
            VStack(spacing: 0) {
                ForEach(events) { event in
                    NavigationLink(destination: HomeEventDetailView(event: event)) {
                        HStack {
                            VStack {
                                Text(event.dayString)
                                    .font(.caption2).fontWeight(.bold)
                                    .foregroundColor(.white.opacity(0.8))
                                Image(systemName: event.icon)
                                    .font(.system(size: 20)).foregroundColor(.white)
                            }
                            .frame(width: 50)
                            
                            VStack(alignment: .leading) {
                                Text(event.title)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.leading)
                                Text(event.timeString)
                                    .font(.caption).foregroundColor(.white.opacity(0.7))
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.white.opacity(0.5))
                        }
                        .padding()
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    if event.id != events.last?.id {
                        Divider().background(Color.white.opacity(0.3))
                    }
                }
            }
            .background(Color.white.opacity(0.15))
            .cornerRadius(16)
            .padding(.horizontal)
        }
    }
}

// ---------------------------------------------------------
// 6. VISTA DETALLE DE ANUNCIO
// ---------------------------------------------------------
struct BroadcastDetailView: View {
    let broadcast: HomeBroadcast
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            Color(UIColor.systemGroupedBackground).ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    VStack(spacing: 15) {
                        Circle()
                            .fill(Color.orange.opacity(0.15))
                            .frame(width: 80, height: 80)
                            .overlay(
                                Image(systemName: "megaphone.fill")
                                    .font(.system(size: 35))
                                    .foregroundColor(.orange)
                            )
                        
                        Text("Broadcast details")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        Text(broadcast.fullDateString)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 60)
                    
                    VStack(alignment: .leading, spacing: 20) {
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .font(.title2)
                                .foregroundColor(.blue)
                            VStack(alignment: .leading) {
                                Text("Sent by")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                Text(broadcast.sender)
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.black)
                            }
                        }
                        
                        Divider()
                        
                        Text(broadcast.text)
                            .font(.body)
                            .foregroundColor(.black)
                            .lineSpacing(6)
                        
                        HomeAttachmentView(
                            fileUrl: broadcast.fileUrl,
                            fileName: broadcast.fileName,
                            fileType: broadcast.fileType,
                            imageUrl: broadcast.imageUrl
                        )
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(16)
                    .padding()
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                    
                    Spacer()
                }
            }
            
            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                HStack(spacing: 5) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .bold))
                    Text("Atrás")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.vertical, 10)
                .padding(.horizontal, 15)
                .background(Color.blue.opacity(0.8))
                .clipShape(Capsule())
                .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
            }
            .padding(.top, 50)
            .padding(.leading, 20)
        }
        .navigationBarHidden(true)
        .preferredColorScheme(.dark)
    }
}

// ---------------------------------------------------------
// 7. VISTA DETALLE EVENTO
// ---------------------------------------------------------
struct HomeEventDetailView: View {
    let event: HomeCalendarEvent
    @Environment(\.presentationMode) var presentationMode
    
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var alertTitle = ""
    
    func openMap(address: String) {
        let cleanAddress = address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: "maps://?q=\(cleanAddress)") {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            }
        }
    }
    
    func addToCalendar() {
        let eventStore = EKEventStore()
        let saveEvent = {
            let ekEvent = EKEvent(eventStore: eventStore)
            ekEvent.title = event.title
            ekEvent.startDate = event.date
            ekEvent.endDate = event.date.addingTimeInterval(3600)
            ekEvent.notes = event.description
            ekEvent.location = event.location
            ekEvent.calendar = eventStore.defaultCalendarForNewEvents
            
            do {
                try eventStore.save(ekEvent, span: .thisEvent)
                DispatchQueue.main.async {
                    alertTitle = "¡Listo!"
                    alertMessage = "El evento se ha guardado en tu calendario."
                    showingAlert = true
                }
            } catch {
                DispatchQueue.main.async {
                    alertTitle = "Error"
                    alertMessage = "No se pudo guardar: \(error.localizedDescription)"
                    showingAlert = true
                }
            }
        }
        
        if #available(iOS 17.0, *) {
            eventStore.requestFullAccessToEvents { granted, error in
                if granted { saveEvent() } else { showPermissionAlert() }
            }
        } else {
            eventStore.requestAccess(to: .event) { granted, error in
                if granted { saveEvent() } else { showPermissionAlert() }
            }
        }
    }
    
    func showPermissionAlert() {
        DispatchQueue.main.async {
            alertTitle = "Sin permiso"
            alertMessage = "Habilita el acceso al calendario en Configuración."
            showingAlert = true
        }
    }
    
    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground).ignoresSafeArea()
            ScrollView {
                VStack(spacing: 20) {
                    VStack(spacing: 15) {
                        Circle().fill(Color.blue.opacity(0.1)).frame(width: 80, height: 80).overlay(Image(systemName: event.icon).font(.system(size: 35)).foregroundColor(.blue))
                        Text(event.title).font(.title2).fontWeight(.bold).multilineTextAlignment(.center).padding(.horizontal).foregroundColor(.primary)
                        Text(event.fullDateString).font(.subheadline).foregroundColor(.secondary)
                    }
                    .padding(.top, 40)
                    
                    VStack(alignment: .leading, spacing: 15) {
                        Label("Event details", systemImage: "text.alignleft").font(.headline).foregroundColor(.black)
                        Text(event.description).font(.body).foregroundColor(.gray).lineSpacing(4)
                        Divider()
                        HStack { Label(event.timeString, systemImage: "clock"); Spacer(); Label(event.dayString, systemImage: "calendar") }.font(.subheadline).foregroundColor(.gray)
                        if !event.location.isEmpty {
                            Divider()
                            Button(action: { openMap(address: event.location) }) {
                                HStack { Label(event.location, systemImage: "mappin.and.ellipse").foregroundColor(.blue).multilineTextAlignment(.leading); Spacer(); Image(systemName: "arrow.up.right.circle.fill").foregroundColor(.blue.opacity(0.6)) }
                            }
                        }
                        Divider()
                        Button(action: { addToCalendar() }) {
                            HStack { Spacer(); Label("Add to calendar", systemImage: "calendar.badge.plus").font(.headline).foregroundColor(.white); Spacer() }
                            .padding().background(Color.blue).cornerRadius(12).shadow(color: .blue.opacity(0.3), radius: 5, x: 0, y: 3)
                        }
                        .padding(.top, 10)
                    }
                    .padding().background(Color.white).cornerRadius(16).padding().shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                    Spacer()
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .alert(isPresented: $showingAlert) { Alert(title: Text(alertTitle), message: Text(alertMessage), dismissButton: .default(Text("OK"))) }
        .preferredColorScheme(.dark)
    }
}

// 🔥 COMPONENTE VISUAL PARA LOS ARCHIVOS (CON TRADUCCIÓN INCLUIDA) 🔥
struct HomeAttachmentView: View {
    let fileUrl: String?
    let fileName: String?
    let fileType: String?
    let imageUrl: String?

    var isImage: Bool {
        if let type = fileType, type.starts(with: "image/") { return true }
        if let url = imageUrl ?? fileUrl {
            return url.lowercased().contains(".jpg") || url.lowercased().contains(".png") || url.lowercased().contains(".jpeg")
        }
        return false
    }

    var body: some View {
        if let link = fileUrl ?? imageUrl, let url = URL(string: link) {
            if isImage {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty: HStack { Spacer(); ProgressView(); Spacer() }
                    case .success(let image): image.resizable().scaledToFit().cornerRadius(12).shadow(radius: 5)
                    case .failure: EmptyView()
                    @unknown default: EmptyView()
                    }
                }
                .frame(maxHeight: 300)
                .padding(.top, 10)
            } else {
                Link(destination: url) {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle().fill(Color.blue.opacity(0.1))
                                .frame(width: 40, height: 40)
                            Image(systemName: "doc.text.fill")
                                .foregroundColor(.blue)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(fileName ?? "Documento Adjunto")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.primary)
                                .lineLimit(1)
                            // 👇 TRADUCCIÓN AQUÍ:
                            Text("Tap to download")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                        Spacer()
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue.opacity(0.8))
                    }
                    .padding(12)
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                }
                .padding(.top, 10)
            }
        }
    }
}

// ---------------------------------------------------------
// 🔥 NUEVO COMPONENTE DE COPA ANIMADA (AGREGADO AL FINAL) 🔥
// ---------------------------------------------------------
struct TrophyAnimatedIcon: View {
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // 1. Anillo de Brillo (Expansión)
            Circle()
                .stroke(Color.white.opacity(0.6), lineWidth: 1.5)
                .frame(width: 35, height: 35)
                .scaleEffect(isAnimating ? 1.6 : 0.8) // Crece
                .opacity(isAnimating ? 0 : 1)       // Desaparece
            
            // 2. Fondo del icono
            Circle()
                .fill(Color.black.opacity(0.1))
                .frame(width: 40, height: 40)
            
            // 3. La Copa (Con balanceo)
            Image(systemName: "trophy.fill")
                .foregroundColor(.black)
                .font(.system(size: 18))
                .rotationEffect(.degrees(isAnimating ? 8 : -8)) // Se inclina de izquierda a derecha
                .shadow(color: .white.opacity(0.8), radius: isAnimating ? 5 : 0) // Destello blanco
        }
        .onAppear {
            // Animación lenta y elegante
            withAnimation(Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}
