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
    @State private var generatedFiles: [URL] = []
    @State private var pendingFileDelete: URL?
    @State private var confirmFileDelete = false
    private var completePageCount: Int { records.filter(\.isMERLEligible).count / 8 }

    var body: some View {
        List {
            Section("Documenti") {
                exportButton("PDF MERL ufficiale", icon: "doc.richtext") { try MERLPDFExporter.export(records) }
                exportButton("Registro per Excel (CSV)", icon: "tablecells") { try CSVExporter.export(records) }
            }
            if completePageCount > 0 {
                Section("Singole pagine complete") {
                    ForEach(Array(1...completePageCount), id: \.self) { page in
                        exportButton(String(format: "Pagina MERL %03d · 8 attività%@", page,
                                            PageCheckpointStore.isExported(page) ? " · già esportata" : ""),
                                     icon: PageCheckpointStore.isExported(page) ? "checkmark.circle" : "doc") {
                            let url = try MERLPDFExporter.exportPage(records, pageNumber: page)
                            PageCheckpointStore.markExported(page)
                            return url
                        }
                    }
                    Text("Ogni file contiene soltanto la tabella ufficiale ENAC con le otto attività della pagina.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            Section("Trasferimento database") {
                exportButton("Esporta backup completo", icon: "externaldrive.badge.plus") { try BackupService.export(from: context) }
                Button { showingImporter = true } label: { Label("Importa backup", systemImage: "externaldrive.badge.checkmark") }
            }
            Section {
                Text("Il backup contiene registro e rubriche. L'importazione sostituisce il database corrente solo dopo doppia conferma.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            if !generatedFiles.isEmpty {
                Section("File pronti") {
                    ForEach(generatedFiles, id: \.self) { url in
                        HStack(spacing: 10) {
                            ShareLink(item: url) {
                                Label(url.lastPathComponent, systemImage: fileIcon(url))
                                    .lineLimit(2).frame(maxWidth: .infinity, alignment: .leading)
                            }
                            Button(role: .destructive) { pendingFileDelete = url } label: {
                                Image(systemName: "trash").font(.body.bold()).padding(8)
                            }.buttonStyle(.borderless).accessibilityLabel("Elimina file")
                        }
                    }
                }
            }
        }
        .navigationTitle("Esporta")
        .onAppear(perform: loadGeneratedFiles)
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
        .confirmationDialog("Eliminare il file?", isPresented: Binding(get: { pendingFileDelete != nil && !confirmFileDelete }, set: { if !$0 && !confirmFileDelete { pendingFileDelete = nil } }), titleVisibility: .visible) {
            Button("Annulla", role: .cancel) { pendingFileDelete = nil }
            Button("Continua", role: .destructive) { confirmFileDelete = true }
        } message: { Text("Prima conferma: sarà eliminato solo il file generato. Il registro non verrà modificato.") }
        .alert("Conferma definitiva", isPresented: $confirmFileDelete) {
            Button("Annulla", role: .cancel) { pendingFileDelete = nil }
            Button("Elimina file", role: .destructive, action: deleteGeneratedFile)
        } message: { Text("Vuoi davvero cancellare \(pendingFileDelete?.lastPathComponent ?? "questo file")?") }
    }

    @State private var secondImportConfirmation = false
    private func exportButton(_ title: String, icon: String, action: @escaping () throws -> URL) -> some View {
        Button {
            do {
                let url = try action(); exportURL = url
                generatedFiles.removeAll { $0 == url }; generatedFiles.insert(url, at: 0)
                message = "File creato correttamente."
            }
            catch { message = error.localizedDescription }
        } label: { Label(title, systemImage: icon) }
    }
    private func loadGeneratedFiles() {
        let folder = FileManager.default.temporaryDirectory
        let files = (try? FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: [.contentModificationDateKey])) ?? []
        generatedFiles = files.filter { $0.lastPathComponent.hasPrefix("MY_MERL_") }
            .sorted { left, right in
                let a = (try? left.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
                let b = (try? right.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
                return a > b
            }
    }
    private func fileIcon(_ url: URL) -> String {
        switch url.pathExtension.lowercased() {
        case "pdf": return "doc.richtext"
        case "csv": return "tablecells"
        default: return "externaldrive"
        }
    }
    private func deleteGeneratedFile() {
        guard let url = pendingFileDelete else { return }
        do {
            try FileManager.default.removeItem(at: url)
            generatedFiles.removeAll { $0 == url }
            if exportURL == url { exportURL = nil }
            message = "File eliminato. Il registro non è stato modificato."
        } catch { message = error.localizedDescription }
        pendingFileDelete = nil; confirmFileDelete = false
    }
    private func restore() {
        guard let pendingImport else { return }
        do { try BackupService.restore(from: pendingImport, into: context); message = "Backup importato correttamente." }
        catch { message = error.localizedDescription }
        self.pendingImport = nil
    }
}
