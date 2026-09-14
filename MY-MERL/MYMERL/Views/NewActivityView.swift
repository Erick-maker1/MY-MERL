import SwiftUI
import SwiftData

struct NewActivityView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \MaintenanceSite.name) private var sites: [MaintenanceSite]
    @Query(sort: \AircraftModel.modelName) private var aircraft: [AircraftModel]
    @Query(sort: \AircraftRegistration.registration) private var registrations: [AircraftRegistration]
    @Query(sort: \Supervisor.surname) private var supervisors: [Supervisor]
    @Query private var references: [MaintenanceReference]

    @State private var draft = ActivityDraft()
    @State private var showErrors = false
    @State private var savedMessage = false
    @State private var sheet: DirectorySheet?

    enum DirectorySheet: String, Identifiable { case site, aircraft, registration, supervisor; var id: String { rawValue } }

    private var selectedSite: MaintenanceSite? { sites.first { $0.id == draft.siteID } }
    private var selectedAircraft: AircraftModel? { aircraft.first { $0.id == draft.aircraftID } }
    private var selectedSupervisor: Supervisor? { supervisors.first { $0.id == draft.supervisorID } }
    private var filteredRegistrations: [AircraftRegistration] { registrations.filter { $0.aircraftModelID == draft.aircraftID } }
    private var formErrors: [String] { draft.errors(sites: sites, aircraft: aircraft, supervisors: supervisors) }
    private var summaryCandidates: [ENACSummaryRow] { ENACSummaryRow.candidates(for: draft.ata) }

    var body: some View {
        Form {
            Section {
                DatePicker("Data", selection: $draft.date, displayedComponents: .date)
                HStack {
                    Text("Ore")
                    TextField("", text: $draft.hoursText).keyboardType(.decimalPad).multilineTextAlignment(.trailing)
                }.requiredField(showErrors && draft.normalizedHours == nil)
            }

            Section("Aeromobile e sede") {
                DirectoryPickerRow(title: "Luogo") {
                    Picker("Luogo", selection: $draft.siteID) {
                        Text("Seleziona").tag(UUID?.none)
                        ForEach(sites) { Text("\($0.name) · \($0.mode.rawValue)").tag(Optional($0.id)) }
                    }.labelsHidden().frame(maxWidth: .infinity, alignment: .leading)
                } add: { sheet = .site }

                DirectoryPickerRow(title: "Tipo A/M") {
                    Picker("Tipo A/M", selection: $draft.aircraftID) {
                        Text("Seleziona").tag(UUID?.none)
                        ForEach(aircraft) { Text($0.modelName).tag(Optional($0.id)) }
                    }.labelsHidden().frame(maxWidth: .infinity, alignment: .leading)
                } add: { sheet = .aircraft }
                .onChange(of: draft.aircraftID) { _, _ in draft.registration = ""; findReference() }

                DirectoryPickerRow(title: "Marche A/M") {
                    Picker("Marche A/M", selection: $draft.registration) {
                        Text("Seleziona").tag("")
                        ForEach(filteredRegistrations) { Text($0.registration).tag($0.registration) }
                    }.labelsHidden().frame(maxWidth: .infinity, alignment: .leading)
                } add: { sheet = .registration }
            }

            Section("Attività") {
                Picker("Manuale", selection: $draft.manualType) {
                    ForEach(["AMM", "EMM", "Altro"], id: \.self) { Text($0) }
                }.pickerStyle(.segmented)
                TextField("Codice (es. 21-53-02,6-1)", text: $draft.maintenanceCode)
                    .textInputAutocapitalization(.characters)
                    .requiredField(showErrors && draft.maintenanceCode.isEmpty)
                    .onChange(of: draft.maintenanceCode) { _, _ in
                        if draft.ata.isEmpty { draft.ata = draft.proposedATA }
                        findReference()
                    }
                HStack {
                    TextField("Cap. ATA", text: $draft.ata).keyboardType(.numberPad)
                        .onChange(of: draft.ata) { _, _ in proposeSummaryRow() }
                    Picker("Tipo", selection: $draft.activityCode) {
                        ForEach(ActivityCode.allCases) { Text("\(selectedSite?.mode.prefix ?? "X")-\($0.rawValue)").tag($0) }
                    }
                }
                TextField("Descrizione dell'attività", text: $draft.description, axis: .vertical)
                    .lineLimit(2...5).requiredField(showErrors && draft.description.isEmpty)
                TextField("Gruppo tecnico equivalente", text: $draft.equivalenceGroup)
                Picker("Riga riepilogo ENAC", selection: $draft.summaryRowID) {
                    Text("Seleziona").tag("")
                    ForEach(summaryCandidates) { Text("Sez. \($0.section) · ATA \($0.ata) · \($0.title)").tag($0.id) }
                }
                .requiredField(showErrors && draft.summaryRowID.isEmpty)
                Toggle("Engine Run-up realmente eseguito", isOn: $draft.isEngineRunUp)
                    .disabled(draft.activityCode != .RUP)
                ActivityLegendView()
            }

            Section("Documento e supervisore") {
                Picker("Documento", selection: $draft.documentKind) {
                    ForEach(DocumentKind.allCases) { Text($0.rawValue).tag($0) }
                }.pickerStyle(.segmented)
                if draft.documentKind == .workReport {
                    HStack(spacing: 8) {
                        TextField("Numero", text: $draft.documentFirst).keyboardType(.numberPad)
                        Text("/").font(.title3.bold())
                        TextField("AA", text: $draft.documentYear).keyboardType(.numberPad).frame(width: 52)
                            .onChange(of: draft.documentYear) { _, value in draft.documentYear = String(value.filter(\.isNumber).prefix(2)) }
                    }.requiredField(showErrors && (draft.documentFirst.isEmpty || draft.documentYear.count != 2))
                } else {
                    TextField("Numero QTB o HTL", text: $draft.documentFirst).keyboardType(.numberPad)
                        .requiredField(showErrors && draft.documentFirst.isEmpty)
                }
                DirectoryPickerRow(title: "Istruttore / Supervisore") {
                    Picker("Supervisore", selection: $draft.supervisorID) {
                        Text("Seleziona").tag(UUID?.none)
                        ForEach(supervisors) { Text($0.fullName).tag(Optional($0.id)) }
                    }.labelsHidden().frame(maxWidth: .infinity, alignment: .leading)
                } add: { sheet = .supervisor }
                if let selectedSupervisor { Text("Nel PDF: \(selectedSupervisor.merlName)").font(.caption).foregroundStyle(.secondary) }
                Toggle("Attività valida per il MERL", isOn: $draft.isMERLEligible)
            }

            if showErrors && !formErrors.isEmpty {
                Section { ForEach(formErrors, id: \.self) { Label($0, systemImage: "exclamationmark.circle.fill").foregroundStyle(.red) } }
            }
            Section { Button("Salva e aggiungi un'altra", action: save).frame(maxWidth: .infinity).fontWeight(.semibold) }
        }
        .navigationTitle("Nuova attività")
        .sheet(item: $sheet) { value in DirectoryEditorSheet(kind: value, selectedAircraftID: draft.aircraftID) }
        .alert("Attività salvata", isPresented: $savedMessage) { Button("OK") {} }
    }

    private func findReference() {
        guard let aircraftID = draft.aircraftID else { return }
        if let match = references.first(where: {
            $0.aircraftModelID == aircraftID && $0.manualType.caseInsensitiveCompare(draft.manualType) == .orderedSame &&
            $0.code.caseInsensitiveCompare(draft.maintenanceCode.trimmingCharacters(in: .whitespaces)) == .orderedSame
        }) {
            draft.ata = match.ata; draft.description = match.activityDescription; draft.equivalenceGroup = match.equivalenceGroup
            draft.summaryRowID = match.summaryRowID
        }
    }

    private func proposeSummaryRow() {
        let candidates = ENACSummaryRow.candidates(for: draft.ata)
        if candidates.count == 1 { draft.summaryRowID = candidates[0].id }
        else if !candidates.contains(where: { $0.id == draft.summaryRowID }) { draft.summaryRowID = "" }
    }

    private func save() {
        showErrors = true
        guard formErrors.isEmpty, let site = selectedSite, let aircraft = selectedAircraft,
              let supervisor = selectedSupervisor, let hours = draft.normalizedHours else { return }
        let normalizedCode = draft.maintenanceCode.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedDescription = draft.description.trimmingCharacters(in: .whitespacesAndNewlines)
        if !references.contains(where: { $0.aircraftModelID == aircraft.id && $0.manualType == draft.manualType && $0.code == normalizedCode }) {
            context.insert(MaintenanceReference(aircraftModelID: aircraft.id, manualType: draft.manualType,
                code: normalizedCode, ata: draft.ata, activityDescription: normalizedDescription,
                equivalenceGroup: draft.equivalenceGroup, summaryRowID: draft.summaryRowID))
        }
        context.insert(ActivityRecord(date: draft.date, site: site, aircraft: aircraft,
            registration: draft.registration, manualType: draft.manualType, maintenanceCode: normalizedCode,
            ata: draft.ata, activityCode: draft.activityCode, activityDescription: normalizedDescription,
            equivalenceGroup: draft.equivalenceGroup, summaryRowID: draft.summaryRowID, workHours: hours, documentKind: draft.documentKind,
            documentNumber: draft.documentNumber, supervisor: supervisor,
            isEngineRunUp: draft.activityCode == .RUP && draft.isEngineRunUp, isMERLEligible: draft.isMERLEligible))
        try? context.save()
        let keepDate = draft.date
        draft = ActivityDraft(); draft.date = keepDate; draft.siteID = site.id; draft.aircraftID = aircraft.id; draft.supervisorID = supervisor.id
        showErrors = false; savedMessage = true
    }
}
