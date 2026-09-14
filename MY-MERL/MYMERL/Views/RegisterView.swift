import SwiftUI
import SwiftData

struct RegisterView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \ActivityRecord.date, order: .reverse) private var records: [ActivityRecord]
    @State private var search = ""
    @State private var firstDelete: ActivityRecord?
    @State private var finalDelete: ActivityRecord?

    private var filtered: [ActivityRecord] {
        guard !search.isEmpty else { return records }
        return records.filter {
            [$0.siteName, $0.aircraftModelName, $0.registration, $0.maintenanceCode, $0.ata,
             $0.activityDescription, $0.supervisorFullName].joined(separator: " ")
                .localizedCaseInsensitiveContains(search)
        }
    }

    var body: some View {
        List {
            if records.isEmpty {
                ContentUnavailableView("Registro vuoto", systemImage: "wrench.and.screwdriver", description: Text("Le attività salvate appariranno qui."))
            } else {
                ForEach(filtered) { record in
                    NavigationLink { RecordDetailView(record: record) } label: {
                        VStack(alignment: .leading, spacing: 5) {
                            HStack {
                                Text(record.fullDescription).lineLimit(2).font(.subheadline.weight(.semibold))
                                Spacer()
                                Text(hours(record.workHours)).font(.subheadline.monospacedDigit())
                            }
                            Text("\(record.date.formatted(date: .numeric, time: .omitted)) · \(record.siteName) · \(record.aircraftModelName) · \(record.registration)")
                                .font(.caption).foregroundStyle(.secondary).lineLimit(2)
                            Text("ATA \(record.ata) · \(record.activityType) · \(record.documentNumber)")
                                .font(.caption2).foregroundStyle(.secondary)
                        }.padding(.vertical, 4)
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) { firstDelete = record } label: { Label("Elimina", systemImage: "trash") }
                    }
                }
            }
        }
        .navigationTitle("Registro")
        .searchable(text: $search, prompt: "Cerca attività, ATA o aeromobile")
        .alert("Prima conferma", isPresented: Binding(get: { firstDelete != nil }, set: { if !$0 { firstDelete = nil } })) {
            Button("Annulla", role: .cancel) { firstDelete = nil }
            Button("Continua", role: .destructive) { finalDelete = firstDelete; firstDelete = nil }
        } message: { Text("L'attività sarà esclusa dal registro e da tutti i calcoli futuri.") }
        .alert("Eliminare definitivamente?", isPresented: Binding(get: { finalDelete != nil }, set: { if !$0 { finalDelete = nil } })) {
            Button("Annulla", role: .cancel) { finalDelete = nil }
            Button("Elimina", role: .destructive) { deleteConfirmed() }
        } message: { Text("Questa è la seconda conferma. I PDF già esportati non verranno modificati.") }
    }

    private func deleteConfirmed() {
        guard let finalDelete else { return }
        context.delete(finalDelete); try? context.save(); self.finalDelete = nil
    }
    private func hours(_ value: Double) -> String { String(format: "%.1f h", value).replacingOccurrences(of: ".", with: ",") }
}

struct RecordDetailView: View {
    let record: ActivityRecord
    var body: some View {
        List {
            Section("Attività") {
                LabeledContent("Data", value: record.date.formatted(date: .long, time: .omitted))
                LabeledContent("Luogo", value: record.siteName)
                LabeledContent("Tipo", value: record.maintenanceModeRaw)
                LabeledContent("Aeromobile", value: "\(record.aircraftModelName) · \(record.registration)")
                LabeledContent("ATA", value: record.ata)
                LabeledContent("Attività", value: record.activityType)
                LabeledContent("Ore", value: String(record.workHours))
            }
            Section("Riferimento") {
                Text(record.fullDescription)
                if !record.equivalenceGroup.isEmpty { LabeledContent("Gruppo equivalente", value: record.equivalenceGroup) }
            }
            Section("Documento") {
                LabeledContent(record.documentKindRaw, value: record.documentNumber)
                LabeledContent("Supervisore", value: record.supervisorFullName)
                if !record.supervisorLicenceNumber.isEmpty {
                    LabeledContent("Licenza", value: "\(record.supervisorLicenceCategory) \(record.supervisorLicenceNumber)")
                }
            }
        }.navigationTitle("Dettaglio").navigationBarTitleDisplayMode(.inline)
    }
}
