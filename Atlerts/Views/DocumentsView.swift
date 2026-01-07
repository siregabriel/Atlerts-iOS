//
//  DocumentsView.swift
//  Atlerts
//
//  Created by Gabriel Rosales Montes  on 04/01/26.
//
import SwiftUI
import FirebaseFirestore

struct DocumentsView: View {
    @StateObject var viewModel = DocumentsViewModel()
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.systemGroupedBackground).ignoresSafeArea()
                
                if viewModel.isLoading {
                    ProgressView()
                } else if viewModel.documents.isEmpty {
                    // Estado Vacío
                    VStack(spacing: 15) {
                        Image(systemName: "folder.badge.questionmark")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("No documents available")
                            .font(.headline)
                            .foregroundColor(.gray)
                        Text("The files you upload to the Admin will appear here for everyone.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                } else {
                    // Lista Real
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.documents) { doc in
                                Link(destination: URL(string: doc.url)!) {
                                    HStack(spacing: 16) {
                                        // Icono de PDF
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
                                                    Text("Recient")
                                                }
                                                Text("• PDF")
                                            }
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                        }
                                        
                                        Spacer()
                                        
                                        // Icono descarga
                                        Image(systemName: "icloud.and.arrow.down")
                                            .font(.title3)
                                            .foregroundColor(.blue)
                                    }
                                    .padding()
                                    .background(Color(UIColor.secondarySystemGroupedBackground))
                                    .cornerRadius(16)
                                    .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                                }
                                .buttonStyle(PlainButtonStyle()) // Para que el click se sienta nativo
                            }
                        }
                        .padding()
                    }
                    .refreshable {
                        viewModel.fetchDocuments()
                    }
                }
            }
            .navigationTitle("Documents") // Título en español
            .onAppear {
                viewModel.fetchDocuments()
            }
        }
    }
}
