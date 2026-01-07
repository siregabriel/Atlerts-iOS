//
//  FormsView.swift
//  Atlerts
//
//  Created by Gabriel Rosales Montes  on 06/01/26.
//
import SwiftUI
import FirebaseFirestore
import SafariServices

// 1. Modelo
struct CorporateForm: Identifiable {
    let id: String
    let title: String
    let url: String
}

// 2. Vista Principal
struct FormsView: View {
    @State private var forms: [CorporateForm] = []
    @State private var isLoading = true
    @State private var selectedUrl: IdentifiableURL? // Para abrir el navegador
    
    private var db = Firestore.firestore()
    
    var body: some View {
        NavigationView {
            ZStack {
                // Fondo oscuro consistente
                Color(UIColor.systemGroupedBackground).ignoresSafeArea()
                
                if isLoading {
                    ProgressView()
                } else if forms.isEmpty {
                    VStack(spacing: 15) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("No hay formularios disponibles")
                            .foregroundColor(.secondary)
                    }
                } else {
                    List {
                        ForEach(forms) { form in
                            Button(action: {
                                if let url = URL(string: form.url) {
                                    self.selectedUrl = IdentifiableURL(url: url)
                                }
                            }) {
                                HStack(spacing: 15) {
                                    Circle()
                                        .fill(Color.purple.opacity(0.1))
                                        .frame(width: 40, height: 40)
                                        .overlay(
                                            Image(systemName: "list.clipboard.fill")
                                                .foregroundColor(.purple)
                                        )
                                    
                                    Text(form.title)
                                        .font(.body)
                                        .fontWeight(.medium)
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "arrow.up.right")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                .padding(.vertical, 8)
                            }
                        }
                    }
                    .listStyle(InsetGroupedListStyle())
                }
            }
            .navigationTitle("Forms")
            .sheet(item: $selectedUrl) { item in
                SafariView(url: item.url)
            }
        }
        .onAppear { loadForms() }
        .preferredColorScheme(.dark)
    }
    
    func loadForms() {
        db.collection("forms").order(by: "createdAt", descending: true).addSnapshotListener { snap, _ in
            guard let docs = snap?.documents else { return }
            self.forms = docs.compactMap { doc -> CorporateForm? in
                let data = doc.data()
                let title = data["title"] as? String ?? "Formulario"
                let url = data["url"] as? String ?? ""
                return url.isEmpty ? nil : CorporateForm(id: doc.documentID, title: title, url: url)
            }
            self.isLoading = false
        }
    }
}

// 3. Helpers para abrir navegador interno
struct IdentifiableURL: Identifiable {
    let id = UUID()
    let url: URL
}

struct SafariView: UIViewControllerRepresentable {
    let url: URL
    func makeUIViewController(context: Context) -> SFSafariViewController {
        let config = SFSafariViewController.Configuration()
        config.entersReaderIfAvailable = false
        return SFSafariViewController(url: url, configuration: config)
    }
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}
