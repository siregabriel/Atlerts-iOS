import SwiftUI
import WebKit
import FirebaseFirestore
import AVFoundation // Necesario para el audio
import Combine

// MARK: - 1. MODELOS DE DATOS (Sin Codable, Mapeo Manual)

struct TrainingVideo: Identifiable {
    let id: String
    let title: String
    let description: String
    let youtubeID: String
    let duration: String
    
    // Inicializador para convertir desde Diccionario de Firebase
    init(dict: [String: Any]) {
        self.id = dict["id"] as? String ?? UUID().uuidString
        self.title = dict["title"] as? String ?? ""
        self.description = dict["description"] as? String ?? ""
        self.youtubeID = dict["youtubeID"] as? String ?? ""
        self.duration = dict["duration"] as? String ?? ""
    }
}

struct TrainingTopic: Identifiable {
    let id: String
    let title: String
    let iconName: String
    let videos: [TrainingVideo]
}

// MARK: - 2. VIEWMODEL (Lectura Manual de Firestore)

class TrainingViewModel: ObservableObject {
    @Published var topics: [TrainingTopic] = []
    @Published var isLoading = true
    
    private var db = Firestore.firestore()
    
    init() {
        fetchTopics()
    }
    
    func fetchTopics() {
        // Escuchamos la colección "training_topics"
        db.collection("training_topics")
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { querySnapshot, error in
                guard let documents = querySnapshot?.documents else {
                    print("Error fetching documents: \(error?.localizedDescription ?? "Unknown error")")
                    self.isLoading = false
                    return
                }
                
                // MAPEO MANUAL (Evita usar FirebaseFirestoreSwift)
                self.topics = documents.compactMap { doc -> TrainingTopic? in
                    let data = doc.data()
                    
                    let title = data["title"] as? String ?? "No Title"
                    let iconName = data["iconName"] as? String ?? "graduationcap.fill"
                    
                    // Decodificar el array de videos (Array de Diccionarios)
                    let videosRaw = data["videos"] as? [[String: Any]] ?? []
                    let videos = videosRaw.map { TrainingVideo(dict: $0) }
                    
                    return TrainingTopic(
                        id: doc.documentID,
                        title: title,
                        iconName: iconName,
                        videos: videos
                    )
                }
                
                self.isLoading = false
            }
    }
}

// MARK: - 3. VISTA PRINCIPAL

struct TrainingView: View {
    @StateObject var viewModel = TrainingViewModel()

    var body: some View {
        NavigationView {
            ZStack {
                if viewModel.isLoading {
                    ProgressView("Loading videos...")
                } else if viewModel.topics.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "books.vertical.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("No hay cursos disponibles aún")
                            .foregroundColor(.gray)
                    }
                } else {
                    List(viewModel.topics) { topic in
                        NavigationLink(destination: TrainingPlaylistView(topic: topic)) {
                            HStack(spacing: 15) {
                                ZStack {
                                    Circle()
                                        .fill(Color.blue.opacity(0.1))
                                        .frame(width: 50, height: 50)
                                    Image(systemName: topic.iconName.isEmpty ? "graduationcap.fill" : topic.iconName)
                                        .font(.title2)
                                        .foregroundColor(.blue)
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(topic.title)
                                        .font(.headline)
                                    Text("\(topic.videos.count) Videos")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding(.vertical, 8)
                        }
                    }
                    .listStyle(InsetGroupedListStyle())
                }
            }
            .navigationTitle("Training Videos")
        }
    }
}

// MARK: - 4. VISTA DE PLAYLIST

struct TrainingPlaylistView: View {
    let topic: TrainingTopic
    @State private var currentVideo: TrainingVideo?
    
    var body: some View {
        VStack(spacing: 0) {
            if let video = currentVideo {
                // A) REPRODUCTOR
                VStack(alignment: .leading) {
                    YouTubePlayerView(videoID: video.youtubeID)
                        .frame(height: 220)
                        .background(Color.black)
                    
                    ScrollView {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(video.title)
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            Text(video.description)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                    }
                    .frame(maxHeight: 100)
                    
                    Divider()
                }
            } else {
                VStack {
                    Spacer()
                    Text("Select a video")
                        .foregroundColor(.gray)
                    Spacer()
                }
                .frame(height: 220)
            }
            
            // B) LISTA DE VIDEOS
            List(topic.videos) { video in
                Button(action: {
                    withAnimation {
                        self.currentVideo = video
                    }
                }) {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: 80, height: 50)
                            
                            Image(systemName: (currentVideo?.id == video.id) ? "pause.circle.fill" : "play.circle.fill")
                                .foregroundColor((currentVideo?.id == video.id) ? .blue : .gray)
                                .font(.title2)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(video.title)
                                .font(.subheadline)
                                .fontWeight((currentVideo?.id == video.id) ? .bold : .regular)
                                .foregroundColor((currentVideo?.id == video.id) ? .blue : .primary)
                                .lineLimit(2)
                            
                            Text(video.duration)
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        if currentVideo?.id == video.id {
                            Image(systemName: "chart.bar.fill")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .listStyle(PlainListStyle())
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(topic.title)
        .onAppear {
            if currentVideo == nil, let first = topic.videos.first {
                currentVideo = first
            }
        }
    }
}

// MARK: - 5. REPRODUCTOR YOUTUBE (MODO NAVEGADOR SEGURO)

struct YouTubePlayerView: UIViewRepresentable {
    let videoID: String
    
    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.scrollView.backgroundColor = .black
        webView.backgroundColor = .black
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        // CAMBIO CLAVE: Usamos la URL estándar "watch", no "embed".
        // Esto carga la versión móvil de YouTube, que nunca falla por permisos de inserción.
        if let url = URL(string: "https://m.youtube.com/watch?v=\(videoID)") {
            let request = URLRequest(url: url)
            uiView.load(request)
        }
    }
}
