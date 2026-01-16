//
//  DocumentsView.swift
//  Atlerts
//
//  Created by Gabriel Rosales Montes on 04/01/26.
//

import SwiftUI
import FirebaseFirestore
import Combine

// 1. MODELO DE DATOS
struct AtlasDocumentItem: Identifiable, Hashable {
    let id: String
    let title: String
    let url: String
    let category: String
    let timestamp: Timestamp?
    
    var dateValue: Date {
        timestamp?.dateValue() ?? Date()
    }
}

// 2. VIEW MODEL
class DocumentsManager: ObservableObject {
    @Published var documents: [AtlasDocumentItem] = []
    @Published var categories: [String] = []
    @Published var isLoading = true
    
    private var db = Firestore.firestore()
    
    init() {
        fetchDocuments()
    }
    
    func fetchDocuments() {
        db.collection("documents").order(by: "timestamp", descending: true).addSnapshotListener { snapshot, error in
            guard let documents = snapshot?.documents else { return }
            
            let docs = documents.compactMap { doc -> AtlasDocumentItem? in
                let data = doc.data()
                let title = data["title"] as? String ?? "Untitled"
                let url = data["url"] as? String ?? ""
                let category = data["category"] as? String ?? "General"
                let timestamp = data["timestamp"] as? Timestamp
                
                return AtlasDocumentItem(id: doc.documentID, title: title, url: url, category: category, timestamp: timestamp)
            }
            
            DispatchQueue.main.async {
                self.documents = docs
                let uniqueCategories = Set(docs.map { $0.category })
                self.categories = Array(uniqueCategories).sorted()
                self.isLoading = false
            }
        }
    }
}

// 3. VISTA PRINCIPAL
struct DocumentsView: View {
    @StateObject var viewModel = DocumentsManager()
    
    let columns = [
        GridItem(.flexible(), spacing: 20),
        GridItem(.flexible(), spacing: 20)
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.systemGroupedBackground).ignoresSafeArea()
                
                if viewModel.isLoading {
                    ProgressView()
                } else if viewModel.documents.isEmpty {
                    VStack(spacing: 15) {
                        Image(systemName: "folder.badge.questionmark")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("No documents available")
                            .font(.headline)
                            .foregroundColor(.gray)
                        Text("The files you upload to the Admin will appear here.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            Text("LIBRARY")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.gray)
                                .padding(.leading, 16)
                                .padding(.top, 10)
                            
                            LazyVGrid(columns: columns, spacing: 20) {
                                ForEach(viewModel.categories, id: \.self) { category in
                                    NavigationLink(destination: FolderItemsView(categoryName: category, allDocuments: viewModel.documents)) {
                                        FolderCell(categoryName: category, count: viewModel.documents.filter { $0.category == category }.count)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .refreshable {
                        viewModel.fetchDocuments()
                    }
                }
            }
            .navigationTitle("Documents")
            .onAppear {
                viewModel.fetchDocuments()
            }
        }
    }
}

// 4. COMPONENTE: CELDA DE CARPETA
struct FolderCell: View {
    let categoryName: String
    let count: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: "folder.fill")
                .font(.system(size: 28))
                .foregroundColor(Color(red: 0.85, green: 0.65, blue: 0.13))
            
            Text(categoryName)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .minimumScaleFactor(0.85)
            
            Spacer()
            
            Text("\(count) items")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        .frame(height: 155)
    }
}

// 5. VISTA DETALLE: LISTA DE ARCHIVOS (Con Visor PDF Integrado)
struct FolderItemsView: View {
    let categoryName: String
    let allDocuments: [AtlasDocumentItem]
    
    var filteredDocs: [AtlasDocumentItem] {
        allDocuments.filter { $0.category == categoryName }
    }
    
    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground).ignoresSafeArea()
            
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(filteredDocs) { doc in
                        // 🔥 MEJORA DE SEGURIDAD: Unwrap seguro de URL para evitar crashes
                        if let url = URL(string: doc.url) {
                            
                            // 🔥 CAMBIO PRINCIPAL: Usamos NavigationLink hacia PDFViewerScreen
                            NavigationLink(destination: PDFViewerScreen(url: url, title: doc.title)) {
                                HStack(spacing: 16) {
                                    // Icono
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.red.opacity(0.1))
                                            .frame(width: 50, height: 50)
                                        Image(systemName: "doc.text.fill")
                                            .font(.title2)
                                            .foregroundColor(.red)
                                    }
                                    
                                    // Textos
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(doc.title)
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                            .lineLimit(1)
                                        
                                        HStack {
                                            if let date = doc.timestamp?.dateValue() {
                                                Text(date.formatted(date: .abbreviated, time: .omitted))
                                            } else {
                                                Text("Recent")
                                            }
                                            Text("• PDF")
                                        }
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    }
                                    
                                    Spacer()
                                    
                                    // Cambié el icono a "eye" para indicar ver, en lugar de descargar
                                    Image(systemName: "eye.fill")
                                        .font(.title3)
                                        .foregroundColor(.blue.opacity(0.6))
                                }
                                .padding()
                                .background(Color(UIColor.secondarySystemGroupedBackground))
                                .cornerRadius(16)
                                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                            }
                            .buttonStyle(PlainButtonStyle()) // 🔥 MEJORA VISUAL: Evita que todo el texto se ponga azul
                        }
                    }
                }
                .padding()
            }
        }
        .navigationTitle(categoryName)
        .navigationBarTitleDisplayMode(.inline)
    }
}
