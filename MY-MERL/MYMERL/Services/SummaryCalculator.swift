import Foundation

struct ATASummary: Identifiable, Equatable {
    let id: String
    let section: Int
    let ata: String
    let title: String
    let lineHours: Double
    let baseHours: Double
    let activityCount: Int
    let technicalTypeCount: Int
    var lineDays: Double { lineHours / 6.0 }
    var baseDays: Double { baseHours / 6.0 }
}

struct OverallSummary {
    let lineDays: Double
    let baseDays: Double
    let activityCount: Int
    let technicalTypeCount: Int
    let aircraftTypeCount: Int
    let troubleshootingTypeCount: Int
    let functionalTestTypeCount: Int
    let engineRunUpCount: Int
    var totalDays: Double { lineDays + baseDays }
}

enum SummaryCalculator {
    static func byATA(_ records: [ActivityRecord]) -> [ATASummary] {
        let eligible = records.filter { $0.isMERLEligible }
        var expanded: [(String, ActivityRecord)] = []
        for record in eligible {
            let rowIDs = summaryRowIDs(record)
            if rowIDs.isEmpty { expanded.append(("ATA-\(record.ata)", record)) }
            else { rowIDs.forEach { expanded.append(($0, record)) } }
        }
        return Dictionary(grouping: expanded, by: { $0.0 })
            .map { rowID, pairs in
                let rows = pairs.map(\.1)
                let line = rows.filter { $0.mode == .line }.reduce(0) { $0 + $1.workHours }
                let base = rows.filter { $0.mode == .base }.reduce(0) { $0 + $1.workHours }
                let definition = ENACSummaryRow.all.first { $0.id == rowID }
                return ATASummary(
                    id: rowID, section: definition?.section ?? 0, ata: definition?.ata ?? rows[0].ata,
                    title: definition?.title ?? "Non classificato", lineHours: line, baseHours: base, activityCount: rows.count,
                    technicalTypeCount: Set(rows.map { technicalIdentity($0) }).count
                )
            }
            .sorted { ($0.section, numericATA($0.ata), $0.id) < ($1.section, numericATA($1.ata), $1.id) }
    }

    static func overall(_ records: [ActivityRecord]) -> OverallSummary {
        let eligible = records.filter { $0.isMERLEligible }
        let rows = byATA(eligible)
        return OverallSummary(
            lineDays: rows.reduce(0) { $0 + $1.lineDays },
            baseDays: rows.reduce(0) { $0 + $1.baseDays },
            activityCount: rows.reduce(0) { $0 + $1.activityCount },
            technicalTypeCount: rows.reduce(0) { $0 + $1.technicalTypeCount },
            aircraftTypeCount: Set(eligible.map(\.aircraftModelID)).count,
            troubleshootingTypeCount: Set(eligible.filter { $0.isTroubleshooting }.map { technicalIdentity($0) }).count,
            functionalTestTypeCount: Set(eligible.filter { $0.isFunctionalTest }.map { technicalIdentity($0) }).count,
            engineRunUpCount: eligible.filter { $0.isEngineRunUp }.count
        )
    }

    static func displayedDays(_ value: Double) -> String {
        let truncated = floor(value * 10) / 10
        return String(format: "%.1f", truncated).replacingOccurrences(of: ".", with: ",")
    }

    private static func technicalIdentity(_ row: ActivityRecord) -> String {
        let group = row.equivalenceGroup.trimmingCharacters(in: .whitespacesAndNewlines)
        if !group.isEmpty { return group.uppercased() }
        return [row.aircraftModelID.uuidString, row.manualType, row.maintenanceCode]
            .joined(separator: "|").uppercased()
    }

    private static func summaryRowIDs(_ row: ActivityRecord) -> [String] {
        row.summaryRowID.split(separator: ",").map(String.init).filter { !$0.isEmpty }
    }

    private static func numericATA(_ value: String) -> Int {
        Int(value.filter(\.isNumber)) ?? Int.max
    }
}
