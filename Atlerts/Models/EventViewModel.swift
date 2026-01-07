//
//  EventViewModel.swift
//  Atlerts
//
//  Created by Gabriel Rosales Montes  on 05/01/26.
//
import Foundation
import FirebaseFirestore
import Combine

class EventViewModel: ObservableObject {
    @Published var upcomingEvents: [Event] = []
    private var db = Firestore.firestore()
    private var listener: ListenerRegistration?

    func fetchUpcomingEvents() {
        // 1. Limpiamos por si acaso
        listener?.remove()
        
        // 2. Consultamos la colección "events"
        // Filtramos: Solo eventos cuya fecha sea hoy o en el futuro
        listener = db.collection("events")
            .whereField("date", isGreaterThanOrEqualTo: Timestamp(date: Date()))
            .order(by: "date", descending: false)
            .limit(to: 3) // Solo los 3 más cercanos para no saturar la Home
            .addSnapshotListener { querySnapshot, error in
                if let error = error {
                    print("Error al traer eventos: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = querySnapshot?.documents else { return }
                
                DispatchQueue.main.async {
                    self.upcomingEvents = documents.compactMap { doc -> Event? in
                        try? doc.data(as: Event.self)
                    }
                }
            }
    }
    
    deinit {
        listener?.remove()
    }
}
