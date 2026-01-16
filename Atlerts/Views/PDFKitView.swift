//
//  PDFKitView.swift
//  Atlerts
//
//  Created by Gabriel Rosales Montes on 12/01/26.
//

import SwiftUI
import PDFKit

// 1. EL PUENTE
struct PDFKitRepresentedView: UIViewRepresentable {
    let document: PDFDocument?

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.backgroundColor = .systemBackground
        return pdfView
    }

    func updateUIView(_ pdfView: PDFView, context: Context) {
        if let doc = document, pdfView.document !== doc {
            pdfView.document = doc
        }
    }
}

// 2. LA VISTA FINAL OPTIMIZADA
struct PDFViewerScreen: View {
    let url: URL
    let title: String
    
    @State private var pdfDocument: PDFDocument?
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    var body: some View {
        ZStack {
            // A. Visor PDF
            if let document = pdfDocument {
                PDFKitRepresentedView(document: document)
            }
            
            // B. Pantalla de Carga
            if isLoading {
                VStack(spacing: 15) {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("Loading...")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(UIColor.systemBackground))
            }
            
            // C. Error
            if let error = errorMessage {
                VStack(spacing: 15) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.largeTitle)
                        .foregroundColor(.orange)
                    Text(error)
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .padding()
                    Button("Try again") {
                        // Reintentamos lanzando la tarea nuevamente
                        Task { await loadPDF() }
                    }
                }
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if !isLoading && pdfDocument != nil {
                    ShareLink(item: url) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
        }
        // 🔥 CORRECCIÓN: Ahora loadPDF es async, así que 'await' tiene sentido aquí
        .task {
            await loadPDF()
        }
    }
    
    // 🔥 CORRECCIÓN: Marcamos la función como 'async' y quitamos la 'Task' interna
    func loadPDF() async {
        // Actualizamos estado en el Hilo Principal antes de empezar
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            // 1. Descarga (Esto suspende la ejecución sin bloquear la app)
            let (data, _) = try await URLSession.shared.data(from: url)
            
            // 2. Creación del documento
            if let document = PDFDocument(data: data) {
                // 3. Actualización de UI (Volvemos al hilo principal)
                await MainActor.run {
                    self.pdfDocument = document
                    self.isLoading = false
                }
            } else {
                throw URLError(.cannotDecodeContentData)
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Cannot load the file.\nVerify your connection and try again."
                self.isLoading = false
            }
        }
    }
}
