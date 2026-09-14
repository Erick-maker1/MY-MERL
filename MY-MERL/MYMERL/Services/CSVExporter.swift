import Foundation

enum CSVExporter {
    static func export(_ records: [ActivityRecord]) throws -> URL {
        let header = ["Data", "Luogo", "Linea/Base", "Impresa", "Tipo A/M", "Marche A/M", "Manuale", "Codice",
                      "ATA", "Tipo attività", "Descrizione", "Ore", "Documento", "Numero documento",
                      "Supervisore", "Categoria licenza", "Numero licenza", "Gruppo tecnico equivalente", "Riga riepilogo ENAC"]
        let formatter = DateFormatter(); formatter.dateFormat = "dd/MM/yyyy"
        let rows = records.sorted { $0.date < $1.date }.map { row in
            [formatter.string(from: row.date), row.siteName, row.maintenanceModeRaw, row.company,
             row.aircraftModelName, row.registration, row.manualType, row.maintenanceCode, row.ata,
             row.activityType, row.activityDescription, decimal(row.workHours), row.documentKindRaw,
             row.documentNumber, row.supervisorFullName, row.supervisorLicenceCategory,
             row.supervisorLicenceNumber, row.equivalenceGroup, row.summaryRowID]
        }
        let content = ([header] + rows).map { $0.map(escape).joined(separator: ";") }.joined(separator: "\r\n")
        let url = BackupService.temporaryURL(extension: "csv")
        try ("\u{FEFF}" + content).write(to: url, atomically: true, encoding: .utf8)
        return url
    }
    private static func escape(_ value: String) -> String { "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\"" }
    private static func decimal(_ value: Double) -> String { String(format: "%.2f", value).replacingOccurrences(of: ".", with: ",") }
}
