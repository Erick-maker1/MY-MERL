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
            guard !first.trimmed.isEmpty else { return }
            context.insert(MaintenanceSite(name: first.trimmed, mode: mode, company: "", notes: third.trimmed))
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
    @Environment(\.modelContext) private var context
    @Query(sort: \MaintenanceSite.name) private var sites: [MaintenanceSite]
    @Query(sort: \AircraftModel.modelName) private var aircraft: [AircraftModel]
    @Query(sort: \AircraftRegistration.registration) private var registrations: [AircraftRegistration]
    @Query(sort: \Supervisor.surname) private var supervisors: [Supervisor]
    @Query private var references: [MaintenanceReference]
    @State private var sheet: NewActivityView.DirectorySheet?
    @State private var pendingDelete: DirectoryDelete?
    @State private var showFinalDeleteConfirmation = false

    var body: some View {
        List {
            Section("Sedi") {
                ForEach(sites) { item in
                    directoryRow {
                        Label("\(item.name) · \(item.mode.rawValue)", systemImage: "mappin.and.ellipse")
                    } target: { .init(kind: .site, itemID: item.id, name: item.name) }
                }.onDelete { offsets in requestDelete(offsets, from: sites, kind: .site, name: \.name) }
                addButton(.site, "Aggiungi sede")
            }
            Section("Tipi A/M") {
                ForEach(aircraft) { item in
                    directoryRow {
                        VStack(alignment: .leading) { Text(item.modelName); Text([item.manufacturer, item.engineType].filter { !$0.isEmpty }.joined(separator: " · ")).font(.caption).foregroundStyle(.secondary) }
                    } target: { .init(kind: .aircraft, itemID: item.id, name: item.modelName) }
                }.onDelete { offsets in requestDelete(offsets, from: aircraft, kind: .aircraft, name: \.modelName) }
                addButton(.aircraft, "Aggiungi tipo A/M")
            }
            Section("Marche") {
                ForEach(registrations) { item in
                    directoryRow { Text(item.registration) } target: {
                        .init(kind: .registration, itemID: item.id, name: item.registration)
                    }
                }.onDelete { offsets in requestDelete(offsets, from: registrations, kind: .registration, name: \.registration) }
                addButton(.registration, "Aggiungi marche")
            }
            Section("Supervisori") {
                ForEach(supervisors) { item in
                    directoryRow {
                        VStack(alignment: .leading) { Text(item.fullName); Text([item.licenceCategory, item.licenceNumber].filter { !$0.isEmpty }.joined(separator: " · ")).font(.caption).foregroundStyle(.secondary) }
                    } target: { .init(kind: .supervisor, itemID: item.id, name: item.fullName) }
                }.onDelete { offsets in requestDelete(offsets, from: supervisors, kind: .supervisor, name: \.fullName) }
                addButton(.supervisor, "Aggiungi supervisore")
            }
        }
        .navigationTitle("Rubriche")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) { Text("MY MERL 1.0").font(.caption.bold()).foregroundStyle(.secondary) }
            ToolbarItem(placement: .topBarTrailing) { EditButton() }
        }
        .sheet(item: $sheet) { DirectoryEditorSheet(kind: $0, selectedAircraftID: nil) }
        .confirmationDialog("Prima conferma", isPresented: Binding(get: { pendingDelete != nil && !showFinalDeleteConfirmation }, set: { if !$0 && !showFinalDeleteConfirmation { pendingDelete = nil } }), titleVisibility: .visible) {
            Button("Annulla", role: .cancel) { pendingDelete = nil }
            Button("Continua con l'eliminazione", role: .destructive) { showFinalDeleteConfirmation = true }
        } message: {
            Text("\(pendingDelete?.name ?? "") non sarà più selezionabile. Le attività già registrate conserveranno i dati storici.")
        }
        .alert("Conferma definitiva", isPresented: $showFinalDeleteConfirmation) {
            Button("Annulla", role: .cancel) { pendingDelete = nil }
            Button("Elimina definitivamente", role: .destructive, action: deleteConfirmed)
        } message: { Text("Vuoi davvero eliminare \(pendingDelete?.name ?? "questo elemento") dalla rubrica?") }
    }

    private func addButton(_ kind: NewActivityView.DirectorySheet, _ title: String) -> some View {
        Button { sheet = kind } label: { Label(title, systemImage: "plus.circle") }
    }

    private func directoryRow<Content: View>(@ViewBuilder content: () -> Content,
                                             target: @escaping () -> DirectoryDelete) -> some View {
        HStack(spacing: 12) {
            content().frame(maxWidth: .infinity, alignment: .leading)
            Button(role: .destructive) { pendingDelete = target() } label: {
                Image(systemName: "trash").font(.body.bold()).padding(8)
            }.buttonStyle(.borderless).accessibilityLabel("Elimina")
        }
    }

    private func requestDelete<T: Identifiable>(_ offsets: IndexSet, from values: [T], kind: DirectoryDelete.Kind,
                                                 name: KeyPath<T, String>) where T.ID == UUID {
        guard let index = offsets.first, values.indices.contains(index) else { return }
        let item = values[index]
        pendingDelete = DirectoryDelete(kind: kind, itemID: item.id, name: item[keyPath: name])
    }

    private func deleteConfirmed() {
        guard let target = pendingDelete else { return }
        switch target.kind {
        case .site:
            if let item = sites.first(where: { $0.id == target.itemID }) { context.delete(item) }
        case .aircraft:
            registrations.filter { $0.aircraftModelID == target.itemID }.forEach { context.delete($0) }
            references.filter { $0.aircraftModelID == target.itemID }.forEach { context.delete($0) }
            if let item = aircraft.first(where: { $0.id == target.itemID }) { context.delete(item) }
        case .registration:
            if let item = registrations.first(where: { $0.id == target.itemID }) { context.delete(item) }
        case .supervisor:
            if let item = supervisors.first(where: { $0.id == target.itemID }) { context.delete(item) }
        }
        try? context.save(); pendingDelete = nil; showFinalDeleteConfirmation = false
    }
}

private struct DirectoryDelete: Identifiable {
    enum Kind { case site, aircraft, registration, supervisor }
    let id = UUID()
    let kind: Kind
    let itemID: UUID
    let name: String
}

private extension String {
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
}
