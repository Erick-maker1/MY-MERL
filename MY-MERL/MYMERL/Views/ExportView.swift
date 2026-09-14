import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct ExportView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \ActivityRecord.date) private var records: [ActivityRecord]
    @State private var exportURL: URL?
    @State private var showingImporter = false
    @State private var pendingImport: URL?
    @State private var confirmImport = false
    @State private var message: String?

    var body: some View {
        List {
            Section("Documenti") {
                exportButton("PDF MERL ufficiale", icon: "doc.richtext") { try MERLPDFExporter.export(records) }
                exportButton("Registro per Excel (CSV)", icon: "tablecells") { try CSVExporter.export(records) }
            }
            Section("Trasferimento database") {
                exportButton("Esporta backup completo", icon: "externaldrive.badge.plus") { try BackupService.export(from: context) }
                Button { showingImporter = true } label: { Label("Importa backup", systemImage: "externaldrive.badge.checkmark") }
            }
            Section {
                Text("Il backup contiene registro e rubriche. L'importazione sostituisce il database corrente solo dopo doppia conferma.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            if let exportURL {
                Section("File pronto") {
                    ShareLink(item: exportURL) { Label("Salva o condividi \(exportURL.lastPathComponent)", systemImage: "square.and.arrow.up") }
                }
            }
        }
        .navigationTitle("Esporta")
        .fileImporter(isPresented: $showingImporter, allowedContentTypes: [.data]) { result in
            switch result {
            case .success(let url): pendingImport = url; confirmImport = true
            case .failure(let error): message = error.localizedDescription
            }
        }
        .alert("Sostituire il database?", isPresented: $confirmImport) {
            Button("Annulla", role: .cancel) { pendingImport = nil }
            Button("Continua", role: .destructive) { secondImportConfirmation = true }
        } message: { Text("Prima conferma: tutte le attività e le rubriche attuali saranno sostituite dal backup.") }
        .alert("Conferma definitiva", isPresented: $secondImportConfirmation) {
            Button("Annulla", role: .cancel) { pendingImport = nil }
            Button("Importa", role: .destructive, action: restore)
        } message: { Text("Seconda conferma. Prima di continuare è consigliato esportare il database attuale.") }
        .alert("MY MERL", isPresented: Binding(get: { message != nil }, set: { if !$0 { message = nil } })) {
            Button("OK") { message = nil }
        } message: { Text(message ?? "") }
    }

    @State private var secondImportConfirmation = false
    private func exportButton(_ title: String, icon: String, action: @escaping () throws -> URL) -> some View {
        Button {
            do { exportURL = try action(); message = "File creato correttamente." }
            catch { message = error.localizedDescription }
        } label: { Label(title, systemImage: icon) }
    }
    private func restore() {
        guard let pendingImport else { return }
        do { try BackupService.restore(from: pendingImport, into: context); message = "Backup importato correttamente." }
        catch { message = error.localizedDescription }
        self.pendingImport = nil
    }
}
