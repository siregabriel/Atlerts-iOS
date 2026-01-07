import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import Combine

// 1. MODELO ACTUALIZADO (Con Lugar y Descripción)
struct CorporateEvent: Identifiable {
    let id: String
    let title: String
    let location: String
    let description: String
    let date: Date
}

// 2. VIEW MODEL
class CalendarViewModel: ObservableObject {
    @Published var events: [CorporateEvent] = []
    @Published var currentMonth: Date = Date()
    @Published var selectedDate: Date = Date()
    
    private var db = Firestore.firestore()
    
    init() {
        fetchEvents()
    }
    
    func fetchEvents() {
        db.collection("events").addSnapshotListener { snap, _ in
            guard let docs = snap?.documents else { return }
            
            self.events = docs.compactMap { doc -> CorporateEvent? in
                let data = doc.data()
                let title = data["title"] as? String ?? "Evento"
                let location = data["location"] as? String ?? "General"
                let desc = data["description"] as? String ?? ""
                guard let timestamp = data["date"] as? Timestamp else { return nil } // Firebase Timestamp
                // OJO: Si en web usas fecha nativa, Firebase guarda Timestamp, así que esto está bien.
                
                return CorporateEvent(
                    id: doc.documentID,
                    title: title,
                    location: location,
                    description: desc,
                    date: timestamp.dateValue()
                )
            }
        }
    }
    
    func eventsForSelectedDate() -> [CorporateEvent] {
        return events.filter { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }
    }
    
    func hasEvent(on date: Date) -> Bool {
        return events.contains { Calendar.current.isDate($0.date, inSameDayAs: date) }
    }
    
    func changeMonth(by value: Int) {
        if let newDate = Calendar.current.date(byAdding: .month, value: value, to: currentMonth) {
            currentMonth = newDate
        }
    }
}

// 3. VISTA PRINCIPAL
struct CalendarView: View {
    @StateObject var viewModel = CalendarViewModel()
    @State private var selectedEvent: CorporateEvent? // Para controlar qué evento mostrar en detalle
    
    let days = ["Lun", "Mar", "Mié", "Jue", "Vie", "Sáb", "Dom"]
    let columns = Array(repeating: GridItem(.flexible()), count: 7)
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // CABECERA
                HStack {
                    Button(action: { viewModel.changeMonth(by: -1) }) {
                        Image(systemName: "chevron.left").padding().foregroundColor(.blue)
                    }
                    Spacer()
                    Text(extractMonthYear(from: viewModel.currentMonth))
                        .font(.title2).bold()
                    Spacer()
                    Button(action: { viewModel.changeMonth(by: 1) }) {
                        Image(systemName: "chevron.right").padding().foregroundColor(.blue)
                    }
                }
                .padding(.horizontal)
                
                // DÍAS SEMANA
                HStack {
                    ForEach(days, id: \.self) { day in
                        Text(day).font(.caption).bold().foregroundColor(.gray).frame(maxWidth: .infinity)
                    }
                }
                
                // GRILLA
                LazyVGrid(columns: columns, spacing: 15) {
                    ForEach(extractDays(), id: \.self) { dateValue in
                        if let date = dateValue.date {
                            Button(action: { viewModel.selectedDate = date }) {
                                VStack(spacing: 4) {
                                    Text("\(dateValue.day)")
                                        .font(.system(size: 16))
                                        .fontWeight(isSameDay(date1: date, date2: viewModel.selectedDate) ? .bold : .regular)
                                        .foregroundColor(isSameDay(date1: date, date2: viewModel.selectedDate) ? .white : .primary)
                                    
                                    if viewModel.hasEvent(on: date) {
                                        Circle().fill(isSameDay(date1: date, date2: viewModel.selectedDate) ? Color.white : Color.green).frame(width: 5, height: 5)
                                    } else {
                                        Circle().fill(Color.clear).frame(width: 5, height: 5)
                                    }
                                }
                                .frame(width: 40, height: 45)
                                .background(
                                    ZStack {
                                        if isSameDay(date1: date, date2: viewModel.selectedDate) { Capsule().fill(Color.blue) }
                                        else if Calendar.current.isDateInToday(date) { Capsule().stroke(Color.blue, lineWidth: 1) }
                                    }
                                )
                            }
                        } else {
                            Text("").frame(width: 40, height: 45)
                        }
                    }
                }
                .padding(.horizontal)
                
                Divider()
                
                // LISTA DE EVENTOS DEL DÍA
                VStack(alignment: .leading, spacing: 10) {
                    Text("Events for \(viewModel.selectedDate, style: .date)")
                        .font(.headline).foregroundColor(.gray).padding(.horizontal)
                    
                    let dayEvents = viewModel.eventsForSelectedDate()
                    
                    if dayEvents.isEmpty {
                        Spacer()
                        VStack(spacing: 10) {
                            Image(systemName: "calendar.badge.exclamationmark").font(.largeTitle).foregroundColor(.gray.opacity(0.3))
                            Text("No events scheduled for this day").foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity)
                        Spacer()
                    } else {
                        List(dayEvents) { event in
                            Button(action: {
                                // Al tocar, guardamos el evento seleccionado para abrir la hoja
                                selectedEvent = event
                            }) {
                                HStack(alignment: .top) {
                                    VStack(alignment: .center) {
                                        Text(event.date, style: .time)
                                            .font(.caption).bold().foregroundColor(.blue)
                                    }
                                    .frame(width: 60)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(event.title).font(.body).bold().foregroundColor(.primary)
                                        Text(event.location).font(.caption).foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: "info.circle").foregroundColor(.blue)
                                }
                            }
                        }
                        .listStyle(PlainListStyle())
                    }
                }
            }
            .navigationTitle("Events")
            .navigationBarTitleDisplayMode(.inline)
            // ESTA ES LA HOJA DE DETALLE QUE SE ABRE AL TOCAR
            .sheet(item: $selectedEvent) { event in
                EventDetailView(event: event)
            }
        }
    }
    
    // HELPERS
    func isSameDay(date1: Date, date2: Date) -> Bool { Calendar.current.isDate(date1, inSameDayAs: date2) }
    
    func extractMonthYear(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM YYYY"
        return formatter.string(from: date).capitalized
    }
    
    func extractDays() -> [DateValue] {
        let calendar = Calendar.current
        let currentMonth = viewModel.currentMonth
        var days: [DateValue] = []
        guard let firstDayOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth)) else { return [] }
        let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth)
        let offsetDay = (firstWeekday + 5) % 7
        for _ in 0..<offsetDay { days.append(DateValue(day: -1, date: nil)) }
        guard let range = calendar.range(of: .day, in: .month, for: currentMonth) else { return [] }
        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstDayOfMonth) {
                days.append(DateValue(day: day, date: date))
            }
        }
        return days
    }
}

// 4. VISTA DE DETALLE (Diseño bonito tipo tarjeta)
struct EventDetailView: View {
    let event: CorporateEvent
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground).ignoresSafeArea()
            
            VStack(spacing: 0) {
                // HEADER CON FECHA GRANDE
                VStack(spacing: 5) {
                    Capsule().fill(Color.gray.opacity(0.3)).frame(width: 40, height: 5).padding(.top, 10)
                    
                    Text(event.date, style: .date)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.gray)
                        .padding(.top, 20)
                    
                    Text(event.date, style: .time)
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.blue)
                }
                .padding(.bottom, 30)
                
                // TARJETA DE INFO
                VStack(alignment: .leading, spacing: 20) {
                    // TÍTULO
                    HStack(alignment: .top, spacing: 15) {
                        Image(systemName: "calendar")
                            .font(.title2)
                            .foregroundColor(.blue)
                            .frame(width: 30)
                        VStack(alignment: .leading) {
                            Text("Evento")
                                .font(.caption).foregroundColor(.gray).textCase(.uppercase) // <--- CORREGIDO
                            Text(event.title)
                                .font(.title3).bold()
                        }
                    }
                    
                    Divider()
                    
                    // LUGAR
                    HStack(alignment: .top, spacing: 15) {
                        Image(systemName: "mappin.and.ellipse")
                            .font(.title2)
                            .foregroundColor(.red)
                            .frame(width: 30)
                        VStack(alignment: .leading) {
                            Text("Ubicación")
                                .font(.caption).foregroundColor(.gray).textCase(.uppercase) // <--- CORREGIDO
                            Text(event.location)
                                .font(.body)
                        }
                    }
                    
                    Divider()
                    
                    // DESCRIPCIÓN
                    HStack(alignment: .top, spacing: 15) {
                        Image(systemName: "text.alignleft")
                            .font(.title2)
                            .foregroundColor(.orange)
                            .frame(width: 30)
                        VStack(alignment: .leading) {
                            Text("Detalles")
                                .font(.caption).foregroundColor(.gray).textCase(.uppercase) // <--- CORREGIDO
                            Text(event.description.isEmpty ? "Sin detalles adicionales." : event.description)
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(25)
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .cornerRadius(20)
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                .padding(.horizontal)
                
                Spacer()
                
                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                    Text("Cerrar")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(15)
                }
                .padding()
            }
        }
    }
}

struct DateValue: Identifiable, Hashable {
    var id = UUID().uuidString
    var day: Int
    var date: Date?
}
