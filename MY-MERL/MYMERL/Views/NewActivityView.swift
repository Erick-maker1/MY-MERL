import SwiftUI
import SwiftData
import UIKit

struct NewActivityView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \MaintenanceSite.name) private var sites: [MaintenanceSite]
    @Query(sort: \AircraftModel.modelName) private var aircraft: [AircraftModel]
    @Query(sort: \AircraftRegistration.registration) private var registrations: [AircraftRegistration]
    @Query(sort: \Supervisor.surname) private var supervisors: [Supervisor]
    @Query private var references: [MaintenanceReference]
    @Query(sort: \ActivityRecord.date) private var records: [ActivityRecord]

    @State private var draft = ActivityDraft()
    @State private var showErrors = false
    @State private var savedMessage = false
    @State private var sheet: DirectorySheet?
    @State private var step = 0
    @State private var useExistingTechnicalGroup = false
    @State private var equivalentReferenceID: UUID?
    @State private var equivalentSearch = ""
    @State private var ambiguousSummaryRowID = ""
    @State private var completedPageNumber: Int?
    @State private var completedPageURL: URL?
    @State private var pageExportError: String?
    @State private var stepErrors: [String] = []

    enum DirectorySheet: String, Identifiable { case site, aircraft, registration, supervisor; var id: String { rawValue } }

    private var selectedSite: MaintenanceSite? { sites.first { $0.id == draft.siteID } }
    private var selectedAircraft: AircraftModel? { aircraft.first { $0.id == draft.aircraftID } }
    private var selectedSupervisor: Supervisor? { supervisors.first { $0.id == draft.supervisorID } }
    private var filteredRegistrations: [AircraftRegistration] { registrations.filter { $0.aircraftModelID == draft.aircraftID } }
    private var formErrors: [String] { draft.errors(sites: sites, aircraft: aircraft, supervisors: supervisors) }
    private var visibleErrors: [String] { step == 2 ? formErrors : stepErrors }
    private var summaryCandidates: [ENACSummaryRow] { ENACSummaryRow.candidates(for: draft.ata) }
    private var automaticSummaryRows: [ENACSummaryRow] {
        Dictionary(grouping: summaryCandidates, by: \.section).values.filter { $0.count == 1 }.compactMap(\.first).sorted { $0.section < $1.section }
    }
    private var ambiguousSummaryRows: [ENACSummaryRow] {
        Dictionary(grouping: summaryCandidates, by: \.section).values.filter { $0.count > 1 }.flatMap { $0 }.sorted { $0.id < $1.id }
    }
    private var exactReference: MaintenanceReference? {
        guard let aircraftID = draft.aircraftID, draft.codeComplete else { return nil }
        return references.first {
            $0.aircraftModelID == aircraftID && $0.manualType.caseInsensitiveCompare(draft.manualType) == .orderedSame &&
            $0.code.caseInsensitiveCompare(draft.maintenanceCode) == .orderedSame
        }
    }
    private var equivalentCandidates: [MaintenanceReference] {
        guard let aircraftID = draft.aircraftID else { return [] }
        let candidates = references.filter { reference in
            guard reference.aircraftModelID == aircraftID && reference.code != draft.maintenanceCode else { return false }
            guard !equivalentSearch.isEmpty else { return true }
            return "\(reference.manualType) \(reference.code) \(reference.activityDescription)"
                .localizedCaseInsensitiveContains(equivalentSearch)
        }
        return candidates.sorted { candidateScore($0) > candidateScore($1) }.prefix(8).map { $0 }
    }

    var body: some View {
        alertedForm
    }

    private var activityForm: some View {
        ScrollViewReader { proxy in
            Form {
                stepHeader.id("activityFormTop")
                if step == 0 { mainDataSection }
                if step == 1 { activitySection }
                if step == 2 { documentSection }
                if showErrors && !visibleErrors.isEmpty {
                    Section("Da completare") {
                        ForEach(visibleErrors, id: \.self) {
                            Label($0, systemImage: "exclamationmark.circle.fill").foregroundStyle(.red)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                navigationButtons
            }
            .onChange(of: step) { _, _ in
                DispatchQueue.main.async { proxy.scrollTo("activityFormTop", anchor: .top) }
            }
        }
    }

    private var presentedForm: some View {
        activityForm
        .navigationTitle("Nuova attività")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) { Text("v1.0.1 · 110").font(.caption.bold()).foregroundStyle(.secondary) }
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Fine") { dismissKeyboard() }.fontWeight(.semibold)
            }
        }
        .sheet(item: $sheet) { value in DirectoryEditorSheet(kind: value, selectedAircraftID: draft.aircraftID) }
        .sheet(isPresented: Binding(get: { completedPageURL != nil }, set: { if !$0 { completedPageURL = nil } })) {
            if let completedPageURL { CompletedPageShareView(url: completedPageURL) }
        }
    }

    private var alertedForm: some View {
        presentedForm
        .alert("Attività salvata", isPresented: $savedMessage) { Button("OK") {} }
        .alert("Pagina MERL completata", isPresented: Binding(get: { completedPageNumber != nil }, set: { if !$0 { completedPageNumber = nil } })) {
            Button("Più tardi", role: .cancel) { completedPageNumber = nil }
            Button("Genera PDF della pagina", action: generateCompletedPage)
        } message: {
            Text("Hai completato la pagina \(completedPageNumber ?? 0) con otto attività. Puoi salvarla ora oppure rigenerarla in qualsiasi momento da Esporta.")
        }
        .alert("Impossibile esportare", isPresented: Binding(get: { pageExportError != nil }, set: { if !$0 { pageExportError = nil } })) {
            Button("OK") { pageExportError = nil }
        } message: { Text(pageExportError ?? "") }
    }

    private var stepHeader: some View {
        Section {
            HStack {
                ForEach(0..<3) { index in
                    Label("\(index + 1)", systemImage: index <= step ? "circle.fill" : "circle")
                        .foregroundStyle(index <= step ? Color.accentColor : Color.secondary)
                    if index < 2 { Spacer(); Rectangle().frame(height: 1).foregroundStyle(.tertiary); Spacer() }
                }
            }.font(.caption)
            Text(["1 · Aeromobile e sede", "2 · Lavoro eseguito", "3 · Ore, documento e conferma"][step])
                .font(.subheadline.weight(.semibold)).fixedSize(horizontal: false, vertical: true)
        }
    }

    private var navigationButtons: some View {
        Section {
            HStack {
                if step > 0 { Button("Indietro") { showErrors = false; step -= 1 } }
                Spacer()
                if step < 2 { Button("Continua") { continueToNextStep() }.fontWeight(.semibold) }
                else { Button("Salva attività", action: save).fontWeight(.semibold) }
            }
        }
    }

    @ViewBuilder private var mainDataSection: some View {
        Section {
            DatePicker("Data", selection: $draft.date, displayedComponents: .date)
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
            .onChange(of: draft.aircraftID) { _, _ in draft.registration = ""; codeChanged() }
            DirectoryPickerRow(title: "Marche A/M") {
                Picker("Marche A/M", selection: $draft.registration) {
                    Text("Seleziona").tag("")
                    ForEach(filteredRegistrations) { Text($0.registration).tag($0.registration) }
                }.labelsHidden().frame(maxWidth: .infinity, alignment: .leading)
            } add: { sheet = .registration }
        }
    }

    @ViewBuilder private var activitySection: some View {
        Section("Riferimento manutentivo") {
            Picker("Manuale", selection: $draft.manualType) { ForEach(["AMM", "EMM", "Altro"], id: \.self) { Text($0) } }
                .pickerStyle(.segmented).onChange(of: draft.manualType) { _, _ in codeChanged() }
            if draft.manualType == "Altro" {
                TextField("Codice completo", text: $draft.otherCode).textInputAutocapitalization(.characters)
                    .requiredField(showErrors && !draft.codeComplete).onChange(of: draft.otherCode) { _, _ in codeChanged() }
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Compila soltanto le caselle bianche").font(.caption).foregroundStyle(.secondary)
                    HStack(spacing: 4) {
                        Text(draft.manualType).font(.subheadline.bold()).fixedSize()
                        codeField("", $draft.codePart1, max: 2, numeric: false, width: 35); fixed("-")
                        codeField("", $draft.codePart2, max: 2, numeric: false, width: 35); fixed("-")
                        codeField("", $draft.codePart3, max: 3, numeric: false, width: 40); fixed(",")
                        codeField("", $draft.codePart4, max: 2, numeric: false, width: 32); fixed("-")
                        codeField("", $draft.codePart5, max: 8, numeric: false, width: 48)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }.requiredField(showErrors && !draft.codeComplete)
            }
            TextField("Capitolo ATA", text: $draft.ata).keyboardType(.numberPad).onChange(of: draft.ata) { _, _ in refreshSummaryRows() }
            VStack(alignment: .leading, spacing: 5) {
                Text("Tipo attività").font(.caption).foregroundStyle(.secondary)
                Picker("Tipo attività", selection: $draft.activityCode) {
                    ForEach(ActivityCode.allCases) { Text("\(selectedSite?.mode.prefix ?? "X")-\($0.rawValue) · \($0.title)").tag($0) }
                }
                .labelsHidden().frame(maxWidth: .infinity, alignment: .leading)
                Text("\(selectedSite?.mode.prefix ?? "X")-\(draft.activityCode.rawValue) · \(draft.activityCode.title)")
                    .font(.caption).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            TextField("Descrizione dell'attività", text: $draft.description, axis: .vertical)
                .lineLimit(2...5).requiredField(showErrors && draft.description.isEmpty)
            VStack(alignment: .leading, spacing: 8) {
                Text("Tabelle ENAC compilate automaticamente").font(.headline)
                let automaticSections = automaticSummaryRows.map { "Sez. \($0.section)" }.joined(separator: " · ")
                if !automaticSections.isEmpty {
                    Label(automaticSections, systemImage: "checkmark.circle.fill").foregroundStyle(.green)
                    Text("ATA \(draft.ata) sarà riportato con gli stessi valori in tutte queste sezioni.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                if automaticSummaryRows.isEmpty && ambiguousSummaryRows.isEmpty {
                    Label("Capitolo non presente nelle tabelle ENAC", systemImage: "exclamationmark.triangle.fill").foregroundStyle(.red)
                }
                if !ambiguousSummaryRows.isEmpty {
                    Text("In una stessa sezione esistono più righe con questo ATA. Seleziona il dettaglio corretto:")
                        .font(.caption).foregroundStyle(.secondary)
                    Picker("Dettaglio tecnico", selection: $ambiguousSummaryRowID) {
                        Text("Seleziona").tag("")
                        ForEach(ambiguousSummaryRows) { Text("Sez. \($0.section) · \($0.title)").tag($0.id) }
                    }.onChange(of: ambiguousSummaryRowID) { _, _ in refreshSummaryRows(preserveAmbiguous: true) }
                }
            }.requiredField(showErrors && draft.summaryRowIDs.isEmpty)
            Toggle("Engine Run-up realmente eseguito", isOn: $draft.isEngineRunUp).disabled(draft.activityCode != .RUP)
            ActivityLegendView()
        }
    }

    @ViewBuilder private var equivalenceSection: some View {
        Section("Tipologia tecnica") {
            if let exactReference {
                Label("Codice già presente nel database", systemImage: "checkmark.circle.fill").foregroundStyle(.green)
                Text("L'app userà automaticamente lo stesso gruppo di:\n\(exactReference.manualType) \(exactReference.code) · \(exactReference.activityDescription)")
                    .font(.caption).fixedSize(horizontal: false, vertical: true)
            } else {
                Picker("Questo lavoro è", selection: $useExistingTechnicalGroup) {
                    Text("Nuova tipologia").tag(false)
                    Text("Equivalente").tag(true)
                }.pickerStyle(.segmented)
                Text(useExistingTechnicalGroup
                     ? "Cerca o scegli un lavoro precedente tecnicamente uguale. I primi risultati sono quelli più vicini per ATA e descrizione."
                     : "Verrà conteggiato come una nuova tipologia tecnica.")
                    .font(.caption).foregroundStyle(.secondary)
                if useExistingTechnicalGroup {
                    TextField("Cerca codice o descrizione", text: $equivalentSearch)
                    Picker("Possibili equivalenti", selection: $equivalentReferenceID) {
                        Text("Nessuno selezionato").tag(UUID?.none)
                        ForEach(equivalentCandidates) { Text("\($0.manualType) \($0.code) · \($0.activityDescription)").tag(Optional($0.id)) }
                    }
                    if equivalentCandidates.isEmpty {
                        Text("Nessun lavoro compatibile trovato nello stesso aeromobile.").font(.caption).foregroundStyle(.secondary)
                    } else if let chosen = equivalentCandidates.first(where: { $0.id == equivalentReferenceID }) {
                        Text("\(chosen.manualType) \(chosen.code)\n\(chosen.activityDescription)")
                            .font(.subheadline).fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }

    @ViewBuilder private var documentSection: some View {
        Section("Tempo di lavoro") {
            HStack { Text("Ore"); TextField("Inserisci", text: $draft.hoursText).keyboardType(.decimalPad).multilineTextAlignment(.trailing) }
                .requiredField(showErrors && draft.normalizedHours == nil)
        }
        equivalenceSection
        Section("Documento e supervisore") {
            Picker("Documento", selection: $draft.documentKind) { ForEach(DocumentKind.allCases) { Text($0.rawValue).tag($0) } }.pickerStyle(.segmented)
            if draft.documentKind == .workReport {
                HStack(spacing: 8) {
                    TextField("Numero", text: $draft.documentFirst).keyboardType(.numberPad); fixed("/")
                    TextField("AA", text: $draft.documentYear).keyboardType(.numberPad).frame(width: 52)
                        .onChange(of: draft.documentYear) { _, value in draft.documentYear = String(value.filter(\.isNumber).prefix(2)) }
                }.requiredField(showErrors && (draft.documentFirst.isEmpty || draft.documentYear.count != 2))
            } else {
                TextField("Numero QTB o HTL", text: $draft.documentFirst).keyboardType(.numberPad)
                    .requiredField(showErrors && draft.documentFirst.isEmpty)
            }
            DirectoryPickerRow(title: "Istruttore / Supervisore") {
                Picker("Supervisore", selection: $draft.supervisorID) {
                    Text("Seleziona").tag(UUID?.none); ForEach(supervisors) { Text($0.fullName).tag(Optional($0.id)) }
                }.labelsHidden().frame(maxWidth: .infinity, alignment: .leading)
            } add: { sheet = .supervisor }
            if let selectedSupervisor { Text("Nel PDF: \(selectedSupervisor.merlName)").font(.caption).foregroundStyle(.secondary) }
            Toggle("Attività valida per il MERL", isOn: $draft.isMERLEligible)
        }
    }

    private func fixed(_ value: String) -> some View { Text(value).font(.title3.bold()).fixedSize() }
    private func codeField(_ placeholder: String, _ value: Binding<String>, max: Int, numeric: Bool = true,
                           width: CGFloat) -> some View {
        TextField(placeholder, text: value)
            .keyboardType(numeric ? .numberPad : .asciiCapable)
            .textInputAutocapitalization(.characters).multilineTextAlignment(.center)
            .frame(width: width)
            .frame(minHeight: 36)
            .background(.background, in: RoundedRectangle(cornerRadius: 7))
            .overlay { RoundedRectangle(cornerRadius: 7).stroke(.secondary.opacity(0.55), lineWidth: 1) }
            .onChange(of: value.wrappedValue) { _, newValue in
                let allowed = numeric ? newValue.filter(\.isNumber) : newValue.filter { $0.isLetter || $0.isNumber }
                value.wrappedValue = String(allowed.prefix(max)).uppercased(); codeChanged()
            }
    }

    private func codeChanged() {
        // Ogni modifica del codice invalida tutti i valori ricavati dal codice
        // precedente. Saranno ripopolati solo quando il nuovo codice è completo.
        draft.ata = ""
        draft.description = ""
        draft.equivalenceGroup = ""
        draft.summaryRowIDs = []
        ambiguousSummaryRowID = ""
        useExistingTechnicalGroup = false
        equivalentReferenceID = nil
        equivalentSearch = ""
        guard draft.codeComplete else { return }
        draft.ata = draft.proposedATA
        refreshSummaryRows()
        findReference()
    }

    private func candidateScore(_ reference: MaintenanceReference) -> Int {
        var score = 0
        if reference.ata == draft.ata { score += 100 }
        if reference.manualType == draft.manualType { score += 20 }
        let draftWords = Set(draft.description.lowercased().split { !$0.isLetter && !$0.isNumber }.map(String.init).filter { $0.count > 2 })
        let referenceWords = Set(reference.activityDescription.lowercased().split { !$0.isLetter && !$0.isNumber }.map(String.init).filter { $0.count > 2 })
        score += draftWords.intersection(referenceWords).count * 10
        return score
    }

    private func continueToNextStep() {
        showErrors = true
        dismissKeyboard()
        if step == 0 {
            stepErrors = []
            if draft.siteID == nil { stepErrors.append("Seleziona il luogo") }
            if draft.aircraftID == nil { stepErrors.append("Seleziona il tipo A/M") }
            if draft.registration.isEmpty { stepErrors.append("Seleziona le marche A/M") }
        } else {
            stepErrors = []
            if !draft.codeComplete { stepErrors.append("Completa tutte le caselle del codice manutentivo") }
            if draft.ata.isEmpty { stepErrors.append("Inserisci il capitolo ATA") }
            if draft.description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { stepErrors.append("Inserisci la descrizione dell'attività") }
            if draft.summaryRowIDs.isEmpty { stepErrors.append("Il capitolo ATA non è associato a una tabella ENAC") }
            if !ambiguousSummaryRows.isEmpty && ambiguousSummaryRowID.isEmpty { stepErrors.append("Seleziona il dettaglio tecnico ENAC") }
        }
        if stepErrors.isEmpty { showErrors = false; step += 1 }
    }

    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    private func findReference() {
        guard let aircraftID = draft.aircraftID else { return }
        if let match = references.first(where: {
            $0.aircraftModelID == aircraftID && $0.manualType.caseInsensitiveCompare(draft.manualType) == .orderedSame &&
            $0.code.caseInsensitiveCompare(draft.maintenanceCode.trimmingCharacters(in: .whitespaces)) == .orderedSame
        }) {
            draft.ata = match.ata; draft.description = match.activityDescription; draft.equivalenceGroup = match.equivalenceGroup
            // Mantiene l'eventuale scelta specifica storica e aggiunge sempre
            // tutte le righe non ambigue presenti nelle diverse sezioni ENAC.
            draft.summaryRowIDs = Set(match.summaryRowID.split(separator: ",").map(String.init))
                .union(automaticSummaryRows.map(\.id))
            ambiguousSummaryRowID = draft.summaryRowIDs.first(where: { id in ambiguousSummaryRows.contains { $0.id == id } }) ?? ""
        }
    }

    private func refreshSummaryRows(preserveAmbiguous: Bool = false) {
        if !preserveAmbiguous { ambiguousSummaryRowID = "" }
        var ids = Set(automaticSummaryRows.map(\.id))
        if !ambiguousSummaryRowID.isEmpty { ids.insert(ambiguousSummaryRowID) }
        draft.summaryRowIDs = ids
    }

    private func save() {
        showErrors = true
        guard formErrors.isEmpty, let site = selectedSite, let aircraft = selectedAircraft,
              let supervisor = selectedSupervisor, let hours = draft.normalizedHours else { return }
        let normalizedCode = draft.maintenanceCode.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedDescription = draft.description.trimmingCharacters(in: .whitespacesAndNewlines)
        let encodedSummaryRows = draft.summaryRowIDs.sorted().joined(separator: ",")
        if exactReference != nil {
            // findReference() ha già recuperato il gruppo storico del codice noto.
        } else if useExistingTechnicalGroup,
           let reference = equivalentCandidates.first(where: { $0.id == equivalentReferenceID }) {
            draft.equivalenceGroup = reference.equivalenceGroup.isEmpty
                ? "\(reference.aircraftModelID.uuidString)|\(reference.manualType)|\(reference.code)"
                : reference.equivalenceGroup
        } else if draft.equivalenceGroup.isEmpty {
            draft.equivalenceGroup = "\(aircraft.id.uuidString)|\(draft.manualType)|\(normalizedCode)"
        }
        if !references.contains(where: { $0.aircraftModelID == aircraft.id && $0.manualType == draft.manualType && $0.code == normalizedCode }) {
            context.insert(MaintenanceReference(aircraftModelID: aircraft.id, manualType: draft.manualType,
                code: normalizedCode, ata: draft.ata, activityDescription: normalizedDescription,
                equivalenceGroup: draft.equivalenceGroup, summaryRowID: encodedSummaryRows))
        }
        let completesPage = draft.isMERLEligible && (records.filter(\.isMERLEligible).count + 1).isMultiple(of: 8)
        let newPageNumber = (records.filter(\.isMERLEligible).count + 1) / 8
        context.insert(ActivityRecord(date: draft.date, site: site, aircraft: aircraft,
            registration: draft.registration, manualType: draft.manualType, maintenanceCode: normalizedCode,
            ata: draft.ata, activityCode: draft.activityCode, activityDescription: normalizedDescription,
            equivalenceGroup: draft.equivalenceGroup, summaryRowID: encodedSummaryRows, workHours: hours, documentKind: draft.documentKind,
            documentNumber: draft.documentNumber, supervisor: supervisor,
            isEngineRunUp: draft.activityCode == .RUP && draft.isEngineRunUp, isMERLEligible: draft.isMERLEligible))
        try? context.save()
        draft = ActivityDraft(); step = 0; showErrors = false; useExistingTechnicalGroup = false
        equivalentReferenceID = nil; equivalentSearch = ""; ambiguousSummaryRowID = ""
        if completesPage { completedPageNumber = newPageNumber } else { savedMessage = true }
    }

    private func generateCompletedPage() {
        guard let page = completedPageNumber else { return }
        do {
            let currentRecords = try context.fetch(FetchDescriptor<ActivityRecord>())
            completedPageURL = try MERLPDFExporter.exportPage(currentRecords, pageNumber: page)
            PageCheckpointStore.markExported(page)
        } catch { pageExportError = error.localizedDescription }
        completedPageNumber = nil
    }
}

private struct CompletedPageShareView: View {
    let url: URL
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            VStack(spacing: 22) {
                Image(systemName: "checkmark.circle.fill").font(.system(size: 54)).foregroundStyle(.green)
                Text("Pagina MERL pronta").font(.title2.bold())
                Text(url.lastPathComponent).font(.subheadline).multilineTextAlignment(.center)
                ShareLink(item: url) { Label("Salva nell'app File", systemImage: "folder") }
                    .buttonStyle(.borderedProminent).controlSize(.large)
                Text("Il PDF contiene soltanto la tabella ufficiale ENAC con otto attività.")
                    .font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.center)
            }.padding()
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Chiudi") { dismiss() } } }
        }
    }
}
