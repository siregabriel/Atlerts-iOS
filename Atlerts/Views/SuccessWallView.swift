//
//  SuccessWallView.swift
//  Atlerts
//
//  Created by Gabriel Rosales Montes on 06/01/26.
//
import SwiftUI
import FirebaseFirestore
import Combine

// 1. VIEW MODEL (Sin cambios)
class SuccessWallViewModel: ObservableObject {
    @Published var successPosts: [HomeBroadcast] = []
    @Published var isLoading = true
    private var db = Firestore.firestore()
    
    init() { fetchWymanPosts() }
    
    func fetchWymanPosts() {
        db.collection("broadcasts")
            .order(by: "timestamp", descending: true)
            .limit(to: 50)
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else { return }
                
                let posts = documents.compactMap { doc -> HomeBroadcast? in
                    let data = doc.data()
                    let sender = data["senderName"] as? String ?? ""
                    let imageUrl = data["imageUrl"] as? String
                    
                    // Filtro: Solo Wyman + Con Imagen
                    if sender.lowercased().contains("wyman") && imageUrl != nil {
                        let text = data["text"] as? String ?? ""
                        let fileUrl = data["fileUrl"] as? String
                        let fileName = data["fileName"] as? String
                        let fileType = data["fileType"] as? String
                        var date = Date()
                        if let ts = data["timestamp"] as? Timestamp { date = ts.dateValue() }
                        
                        return HomeBroadcast(
                            id: doc.documentID, text: text, sender: sender, date: date,
                            imageUrl: imageUrl, fileUrl: fileUrl, fileName: fileName, fileType: fileType
                        )
                    }
                    return nil
                }
                
                DispatchQueue.main.async {
                    self.successPosts = posts
                    self.isLoading = false
                }
            }
    }
}

// FONDO DE MADERA REALISTA
struct RichWoodBackground: View {
    var body: some View {
        ZStack {
            Image("old-money-background")//Gabriel PSD photshop
                .resizable()
                .scaledToFit()
                .ignoresSafeArea()
            
            Color.black.opacity(0.40).ignoresSafeArea()
            
            RadialGradient(
                gradient: Gradient(colors: [Color.clear, Color.black.opacity(0.7)]),
                center: .center,
                startRadius: 100,
                endRadius: 800
            ).ignoresSafeArea()
        }
    }
}

// FOOTER DECORATIVO
struct SuccessWallFooter: View {
    let goldColor = Color(red: 0.85, green: 0.65, blue: 0.13)
    
    var body: some View {
        HStack(spacing: 20) {
            // Aquí puedes activar los iconos si los necesitas en el futuro
        }
        .padding(.bottom, 30)
    }
    
    func FramedIcon(icon: String, label: String, isCenter: Bool = false) -> some View {
        VStack(spacing: 5) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.black.opacity(0.5))
                    .frame(width: isCenter ? 70 : 60, height: isCenter ? 70 : 60)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(goldColor.opacity(0.7), lineWidth: 1.5)
                    )
                
                Image(systemName: icon)
                    .font(.system(size: isCenter ? 30 : 24))
                    .foregroundColor(goldColor)
            }
            
            Text(label)
                .font(.system(size: 9, weight: .bold))
                .tracking(1)
                .foregroundColor(goldColor.opacity(0.8))
        }
    }
}

// VISTA DE ZOOM
struct ZoomableDetailView: View {
    let imageUrlString: String
    @Binding var isPresented: Bool
    
    @State private var currentScale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.95).ignoresSafeArea()
                .onTapGesture {
                    withAnimation { isPresented = false }
                }
            
            if let url = URL(string: imageUrlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                            .scaleEffect(currentScale)
                            .offset(offset)
                            .gesture(
                                MagnificationGesture()
                                    .onChanged { value in
                                        let delta = value / lastScale
                                        lastScale = value
                                        let newScale = self.currentScale * delta
                                        self.currentScale = min(max(newScale, 1.0), 5.0)
                                    }
                                    .onEnded { _ in
                                        lastScale = 1.0
                                        if currentScale < 1.0 { withAnimation { currentScale = 1.0 } }
                                        if currentScale == 1.0 { withAnimation { offset = .zero } }
                                    }
                                    .simultaneously(with: DragGesture()
                                        .onChanged { value in
                                            guard currentScale > 1.0 else { return }
                                            offset = CGSize(width: lastOffset.width + value.translation.width,
                                                            height: lastOffset.height + value.translation.height)
                                        }
                                        .onEnded { _ in lastOffset = offset }
                                    )
                            )
                            .onTapGesture(count: 2) {
                                withAnimation {
                                    currentScale = 1.0
                                    offset = .zero
                                }
                            }
                    case .empty, .failure:
                        ProgressView().tint(.white)
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            
            VStack {
                HStack {
                    Spacer()
                    Button(action: { withAnimation { isPresented = false } }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.largeTitle)
                            .foregroundColor(.white.opacity(0.8))
                            .padding()
                            .padding(.top, 40)
                    }
                }
                Spacer()
            }
        }
        .statusBar(hidden: true)
    }
}

// 2. VISTA PRINCIPAL (Con Splash de Laureles 🏆🌿)
struct SuccessWallView: View {
    @StateObject var viewModel = SuccessWallViewModel()
    @Environment(\.presentationMode) var presentationMode
    
    @State private var selectedImageForZoom: String? = nil
    @State private var showZoomView = false
    
    // VARIABLES PARA EL SPLASH
    @State private var showSplash = true
    @State private var trophyScale: CGFloat = 0.6
    @State private var trophyOpacity: Double = 0.0
    
    // Degradado dorado
    let goldGradient = LinearGradient(
        gradient: Gradient(colors: [
            Color(red: 0.75, green: 0.55, blue: 0.05),
            Color(red: 1.0, green: 0.84, blue: 0.2),
            Color(red: 0.75, green: 0.55, blue: 0.05)
        ]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    var body: some View {
        ZStack {
            // A. Fondo de Madera
            RichWoodBackground()
            
            VStack(spacing: 0) {
                // B. HEADER
                HStack {
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        Image(systemName: "arrow.left")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Circle().fill(Color.white.opacity(0.1)))
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 4) {
                        Text("WYMAN'S WALL OF")
                            .font(.caption)
                            .fontWeight(.bold)
                            .tracking(2)
                            .foregroundColor(.white.opacity(0.7))
                        
                        Text("SUCCESS")
                            .font(.system(.title, design: .serif))
                            .fontWeight(.black)
                            .foregroundColor(Color(red: 0.85, green: 0.65, blue: 0.13))
                            .shadow(color: .black.opacity(0.8), radius: 5, x: 0, y: 2)
                    }
                    
                    Spacer()
                    Color.clear.frame(width: 44, height: 44)
                }
                .padding(.horizontal)
                .padding(.bottom, 10)
                
                // C. CONTENIDO PRINCIPAL
                if viewModel.isLoading {
                    Spacer()
                    if !showSplash {
                        ProgressView().tint(Color(red: 0.85, green: 0.65, blue: 0.13))
                    }
                    Spacer()
                } else if viewModel.successPosts.isEmpty {
                    Spacer()
                    VStack(spacing: 15) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("No success stories yet.")
                            .foregroundColor(.gray)
                    }
                    Spacer()
                } else {
                    // CARRUSEL 3D
                    GeometryReader { geometry in
                        let sideSpacing: CGFloat = 40
                        let cardWidth = geometry.size.width - (sideSpacing * 2)
                        
                        TabView {
                            ForEach(viewModel.successPosts) { post in
                                GeometryReader { cardGeo in
                                    let minX = cardGeo.frame(in: .global).minX
                                    
                                    SuccessCarouselCard(
                                        post: post,
                                        onImageTapped: {
                                            if let url = post.imageUrl {
                                                selectedImageForZoom = url
                                                withAnimation { showZoomView = true }
                                            }
                                        }
                                    )
                                    .frame(width: cardWidth)
                                    .rotation3DEffect(
                                        .degrees(Double((minX - sideSpacing) / -20)),
                                        axis: (x: 0, y: 1, z: 0)
                                    )
                                }
                                .frame(width: cardWidth)
                                .padding(.horizontal, 10)
                            }
                        }
                        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
                        .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
                    }
                    .frame(height: 480)
                    .padding(.vertical, 20)
                    
                    Spacer()
                    
                    // D. FOOTER
                    SuccessWallFooter()
                }
            }
            //MARK: SPLASH VIEW
            // 🔥 CAPA SUPERIOR: SPLASH CON LAURELES 🌿🏆🌿 🔥
            if showSplash {
                ZStack {
                    // 🌟 FONDO PREMIUM: DEGRADADO + RAYOS DE LUZ 🌟
                    RotatingRaysBackground()
                    
                    VStack(spacing: 25) {
                        // EMBLEMA DE VICTORIA
                        HStack(alignment: .bottom, spacing: -5) {
                            // Laurel Izquierdo
                            Image(systemName: "laurel.leading")
                                .font(.system(size: 60, weight: .light))
                                .offset(y: -10)
                            
                            // Copa Central
                            Image(systemName: "trophy.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 80)
                            
                            // Laurel Derecho
                            Image(systemName: "laurel.trailing")
                                .font(.system(size: 60, weight: .light))
                                .offset(y: -10)
                        }
                        .foregroundColor(.white)
                        .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 10)
                        .scaleEffect(trophyScale)
                        .opacity(trophyOpacity)
                        
                        // Texto de Impacto
                        Text("")
                            .font(.system(size: 20, weight: .bold, design: .serif))
                            .tracking(8)
                            .foregroundColor(.white)
                            .opacity(trophyOpacity)
                    }
                }
                .zIndex(2)
                .transition(.opacity.animation(.easeOut(duration: 0.8)))
            }
        }
        // OVERLAY DE ZOOM
        .overlay(
            Group {
                if showZoomView, let imgUrl = selectedImageForZoom {
                    ZoomableDetailView(imageUrlString: imgUrl, isPresented: $showZoomView)
                        .transition(.opacity)
                }
            }
        )
        .navigationBarHidden(true)
        .onAppear {
            // ANIMACIÓN
            withAnimation(.easeOut(duration: 0.8)) {
                trophyScale = 1.0
                trophyOpacity = 1.0
            }
            // Tiempo de espera antes de revelar el muro
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
                withAnimation(.easeOut(duration: 0.8)) {
                    showSplash = false
                }
            }
        }
    }
}

// 3. TARJETA INDIVIDUAL (Sin cambios)
struct SuccessCarouselCard: View {
    let post: HomeBroadcast
    var onImageTapped: () -> Void
    
    var body: some View {
        ZStack(alignment: .bottom) {
            if let imgUrl = post.imageUrl, let url = URL(string: imgUrl) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .clipped()
                    case .failure:
                        Color.gray.opacity(0.3)
                    case .empty:
                        ZStack {
                            Color.gray.opacity(0.1)
                            ProgressView().tint(.white)
                        }
                    @unknown default:
                        EmptyView()
                    }
                }
            } else {
                Color.black
            }
            
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture { onImageTapped() }
            
            LinearGradient(gradient: Gradient(colors: [.clear, .black.opacity(0.7), .black.opacity(0.95)]), startPoint: .center, endPoint: .bottom)
                .allowsHitTesting(false)
            
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: "quote.opening")
                    .font(.title)
                    .foregroundColor(Color(red: 0.85, green: 0.65, blue: 0.13))
                    .opacity(0.8)
                
                Text(post.text)
                    .font(.system(size: 22, weight: .bold, design: .serif))
                    .foregroundColor(.white)
                    .lineLimit(4)
                    .multilineTextAlignment(.leading)
                    .shadow(color: .black, radius: 2, x: 0, y: 1)
                
                HStack {
                    Text(post.fullDateString.uppercased())
                        .font(.caption)
                        .fontWeight(.bold)
                        .tracking(1)
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    Text("- Wyman")
                        .font(.custom("Zapfino", size: 14))
                        .foregroundColor(Color(red: 0.85, green: 0.65, blue: 0.13))
                }
                .padding(.top, 10)
            }
            .padding(30)
            .allowsHitTesting(false)
        }
        .background(Color.black)
        .cornerRadius(25)
        .overlay(
            RoundedRectangle(cornerRadius: 25)
                .stroke(
                    LinearGradient(gradient: Gradient(colors: [Color(red: 0.85, green: 0.65, blue: 0.13).opacity(0.5), Color.clear]), startPoint: .topLeading, endPoint: .bottomTrailing),
                    lineWidth: 1.5
                )
        )
        .shadow(color: Color.black.opacity(0.7), radius: 25, x: 0, y: 15)
    }
}
