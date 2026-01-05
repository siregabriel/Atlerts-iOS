import SwiftUI

struct RepositoryView: View {
    @StateObject var viewModel = RepositoryViewModel()
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(uiColor: .systemGroupedBackground).ignoresSafeArea()
                
                if viewModel.files.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "folder.badge.questionmark")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("No tienes documentos asignados")
                            .foregroundColor(.gray)
                    }
                } else {
                    List(viewModel.files) { file in
                        // CADA FILA ES UN LINK AL ARCHIVO
                        Link(destination: URL(string: file.url)!) {
                            HStack(spacing: 15) {
                                // ICONO SEGÚN TIPO
                                ZStack {
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 50, height: 50)
                                        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 2)
                                    
                                    Image(systemName: getIconName(type: file.type))
                                        .foregroundColor(getIconColor(type: file.type))
                                        .font(.title2)
                                }
                                
                                // TEXTOS
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(file.name)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    
                                    HStack {
                                        Text(file.size)
                                            .font(.caption)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.gray.opacity(0.1))
                                            .cornerRadius(4)
                                        
                                        Text(file.createdAt, style: .date)
                                            .font(.caption)
                                    }
                                    .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "icloud.and.arrow.down")
                                    .foregroundColor(.blue)
                            }
                            .padding(.vertical, 8)
                        }
                    }
                    .listStyle(InsetGroupedListStyle())
                }
            }
            .navigationTitle("Mis Documentos")
        }
    }
    
    // --- AYUDANTES VISUALES ---
    func getIconName(type: String) -> String {
        switch type {
        case "pdf": return "doc.text.fill"
        case "xls": return "tablecells.fill"
        case "img": return "photo.fill"
        default: return "doc.fill"
        }
    }
    
    func getIconColor(type: String) -> Color {
        switch type {
        case "pdf": return .red
        case "xls": return .green
        case "img": return .purple
        default: return .blue
        }
    }
}
