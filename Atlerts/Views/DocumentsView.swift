//
//  DocumentsView.swift
//  Atlerts
//
//  Created by Gabriel Rosales Montes on 04/01/26.
//

import SwiftUI
import FirebaseFirestore
import Combine

// 1. MODELO DE DATOS (Renombrado para evitar conflictos con otros archivos)
struct AtlasDocumentItem: Identifiable, Hashable {
    let id: String
    let title: String
    let url: String
    let category: String // Campo nuevo para las carpetas
    let timestamp: Timestamp?
    
    // Helper para obtener fecha segura
    var dateValue: Date {
        timestamp?.dateValue() ?? Date()
    }
}

// 2. VIEW MODEL (Renombrado para evitar conflictos)
class DocumentsManager: ObservableObject {
    @Published var documents: [AtlasDocumentItem] = []
    @Published var categories: [String] = [] // Lista de carpetas encontradas
    @Published var isLoading = true
    
    private var db = Firestore.firestore()
    
    init() {
        fetchDocuments()
    }
    
    func fetchDocuments() {
        // Escuchamos la base de datos en tiempo real
        db.collection("documents").order(by: "timestamp", descending: true).addSnapshotListener { snapshot, error in
            guard let documents = snapshot?.documents else { return }
            
            let docs = documents.compactMap { doc -> AtlasDocumentItem? in
                let data = doc.data()
                let title = data["title"] as? String ?? "Untitled"
                let url = data["url"] as? String ?? ""
                // Si el documento no tiene categoría, lo mandamos a "General"
                let category = data["category"] as? String ?? "General"
                let timestamp = data["timestamp"] as? Timestamp
                
                return AtlasDocumentItem(id: doc.documentID, title: title, url: url, category: category, timestamp: timestamp)
            }
            
            DispatchQueue.main.async {
                self.documents = docs
                // Filtramos las categorías únicas para armar el menú de carpetas
                let uniqueCategories = Set(docs.map { $0.category })
                self.categories = Array(uniqueCategories).sorted()
                self.isLoading = false
            }
        }
    }
}

// 3. VISTA PRINCIPAL (Ahora con navegación por Carpetas)
struct DocumentsView: View {
    // Usamos el Manager renombrado
    @StateObject var viewModel = DocumentsManager()
    
    // Configuración de la cuadrícula (2 columnas)
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
                    // Estado Vacío (Tu diseño original)
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
                    // VISTA DE CARPETAS (La nueva funcionalidad)
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            // Título pequeño
                            Text("LIBRARY")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.gray)
                                .padding(.leading, 16)
                                .padding(.top, 10)
                            
                            // Cuadrícula de Carpetas
                            LazyVGrid(columns: columns, spacing: 20) {
                                ForEach(viewModel.categories, id: \.self) { category in
                                    // Al tocar una carpeta, vamos al detalle
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

// 4. COMPONENTE: CELDA DE CARPETA (Diseño Visual)
struct FolderCell: View {
    let categoryName: String
    let count: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Icono de Carpeta
            Image(systemName: "folder.fill")
                .font(.system(size: 28))
                .foregroundColor(Color(red: 0.85, green: 0.65, blue: 0.13)) // Dorado Atlas
            
            // Nombre de Categoría
            Text(categoryName)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .lineLimit(2) // Permite 2 líneas si el nombre es largo
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true) // 2. Obliga al texto a expandirse verticalmente si lo necesita
                .minimumScaleFactor(0.85) // 3. Si la palabra es MUY larga, reduce un poquito la letra para que quepa
            
            Spacer() // Empuja el contador hacia abajo
            
            // Contador de Items
            Text("\(count) items")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16) // (Padding interno de la tarjeta)
        .background(Color(UIColor.secondarySystemGroupedBackground)) // Color de fondo de la tarjeta
        .cornerRadius(16) // Bordes redondeados
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1) // Sombra sutil
        // Asegura que todas las celdas tengan la misma altura mínima
        .frame(height: 155)
    }
}

// 5. VISTA DETALLE: LISTA DE ARCHIVOS (Aquí reutilizamos tu diseño de lista original)
struct FolderItemsView: View {
    let categoryName: String
    let allDocuments: [AtlasDocumentItem]
    
    // Filtramos solo los archivos de esta carpeta
    var filteredDocs: [AtlasDocumentItem] {
        allDocuments.filter { $0.category == categoryName }
    }
    
    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground).ignoresSafeArea()
            
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(filteredDocs) { doc in
                        // Tu diseño de fila original intacto
                        Link(destination: URL(string: doc.url)!) {
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
                                
                                // Botón descarga
                                Image(systemName: "icloud.and.arrow.down")
                                    .font(.title3)
                                    .foregroundColor(.blue)
                            }
                            .padding()
                            .background(Color(UIColor.secondarySystemGroupedBackground))
                            .cornerRadius(16)
                            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding()
            }
        }
        .navigationTitle(categoryName)
        .navigationBarTitleDisplayMode(.inline)
    }
}
