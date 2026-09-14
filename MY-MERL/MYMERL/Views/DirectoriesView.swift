import SwiftUI
import SwiftData

struct DirectoryEditorSheet: View {
    let kind: NewActivityView.DirectorySheet
    let selectedAircraftID: UUID?
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \AircraftModel.modelName) private var aircraft: [AircraftModel]
    @State private var first = ""
    @State private var second = ""
    @State private var third = ""
    @State private var mode: MaintenanceMode = .base
    @State private var aircraftID: UUID?
    @State private var attempted = false

    var body: some View {
        NavigationStack {
            Form {
                switch kind {
                case .site:
                    TextField("Nome sede", text: $first).requiredField(attempted && first.isEmpty)
                    Picker("Tipologia", selection: $mode) { ForEach(MaintenanceMode.allCases) { Text($0.rawValue).tag($0) } }.pickerStyle(.segmented)
                    TextField("Impresa associata", text: $second).requiredField(attempted && second.isEmpty)
                    TextField("Note facoltative", text: $third, axis: .vertical)
                case .aircraft:
                    TextField("Costruttore", text: $first).requiredField(attempted && first.isEmpty)
                    TextField("Modello", text: $second).requiredField(attempted && second.isEmpty)
                    TextField("Tipo motore (solo archivio interno)", text: $third)
                case .registration:
                    Picker("Tipo A/M", selection: $aircraftID) {
                        Text("Seleziona").tag(UUID?.none)
                        ForEach(aircraft) { Text($0.modelName).tag(Optional($0.id)) }
                    }
                    TextField("Marche A/M", text: $first).textInputAutocapitalization(.characters)
                        .requiredField(attempted && first.isEmpty)
                case .supervisor:
                    TextField("Cognome", text: $first).requiredField(attempted && first.isEmpty)
                    TextField("Nome", text: $second).requiredField(attempted && second.isEmpty)
                    TextField("Categoria licenza", text: $third)
                    TextField("Numero licenza", text: $licenceNumber)
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Annulla") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Salva", action: save).fontWeight(.semibold) }
            }
            .onAppear { aircraftID = selectedAircraftID }
        }
    }

    @State private var licenceNumber = ""
    private var title: String {
        switch kind { case .site: "Nuova sede"; case .aircraft: "Nuovo tipo A/M"; case .registration: "Nuove marche"; case .supervisor: "Nuovo supervisore" }
    }
    private func save() {
        attempted = true
        switch kind {
        case .site:
            guard !first.trimmed.isEmpty, !second.trimmed.isEmpty else { return }
            context.insert(MaintenanceSite(name: first.trimmed, mode: mode, company: second.trimmed, notes: third.trimmed))
        case .aircraft:
            guard !first.trimmed.isEmpty, !second.trimmed.isEmpty else { return }
            context.insert(AircraftModel(manufacturer: first.trimmed, modelName: second.trimmed, engineType: third.trimmed))
        case .registration:
            guard !first.trimmed.isEmpty, let aircraftID else { return }
            context.insert(AircraftRegistration(registration: first.trimmed, aircraftModelID: aircraftID))
        case .supervisor:
            guard !first.trimmed.isEmpty, !second.trimmed.isEmpty else { return }
            context.insert(Supervisor(surname: first.trimmed, givenName: second.trimmed, licenceCategory: third.trimmed, licenceNumber: licenceNumber.trimmed))
        }
        try? context.save(); dismiss()
    }
}

struct DirectoriesView: View {
    @Query(sort: \MaintenanceSite.name) private var sites: [MaintenanceSite]
    @Query(sort: \AircraftModel.modelName) private var aircraft: [AircraftModel]
    @Query(sort: \AircraftRegistration.registration) private var registrations: [AircraftRegistration]
    @Query(sort: \Supervisor.surname) private var supervisors: [Supervisor]
    @State private var sheet: NewActivityView.DirectorySheet?

    var body: some View {
        List {
            Section("Sedi") {
                ForEach(sites) { Label("\($0.name) · \($0.mode.rawValue)", systemImage: "mappin.and.ellipse") }
                addButton(.site, "Aggiungi sede")
            }
            Section("Tipi A/M") {
                ForEach(aircraft) { item in
                    VStack(alignment: .leading) { Text(item.modelName); Text([item.manufacturer, item.engineType].filter { !$0.isEmpty }.joined(separator: " · ")).font(.caption).foregroundStyle(.secondary) }
                }
                addButton(.aircraft, "Aggiungi tipo A/M")
            }
            Section("Marche") {
                ForEach(registrations) { Text($0.registration) }
                addButton(.registration, "Aggiungi marche")
            }
            Section("Supervisori") {
                ForEach(supervisors) { item in
                    VStack(alignment: .leading) { Text(item.fullName); Text([item.licenceCategory, item.licenceNumber].filter { !$0.isEmpty }.joined(separator: " · ")).font(.caption).foregroundStyle(.secondary) }
                }
                addButton(.supervisor, "Aggiungi supervisore")
            }
        }
        .navigationTitle("Rubriche")
        .sheet(item: $sheet) { DirectoryEditorSheet(kind: $0, selectedAircraftID: nil) }
    }

    private func addButton(_ kind: NewActivityView.DirectorySheet, _ title: String) -> some View {
        Button { sheet = kind } label: { Label(title, systemImage: "plus.circle") }
    }
}

private extension String {
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
}
