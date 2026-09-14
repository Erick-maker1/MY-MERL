import Foundation

struct ActivityDraft {
    var date = Date()
    var siteID: UUID?
    var aircraftID: UUID?
    var registration = ""
    var manualType = "AMM"
    var maintenanceCode = ""
    var ata = ""
    var activityCode: ActivityCode = .DVI
    var description = ""
    var equivalenceGroup = ""
    var summaryRowID = ""
    var hoursText = ""
    var documentKind: DocumentKind = .qtbHTL
    var documentFirst = ""
    var documentYear = ""
    var supervisorID: UUID?
    var isEngineRunUp = false
    var isMERLEligible = true

    var normalizedHours: Double? {
        Double(hoursText.replacingOccurrences(of: ",", with: "."))
    }
    var documentNumber: String {
        documentKind == .workReport ? "\(documentFirst)/\(documentYear)" : documentFirst
    }
    var proposedATA: String {
        let digits = maintenanceCode.drop { !$0.isNumber }.prefix(2)
        return digits.count == 2 ? String(digits) : ""
    }

    func errors(sites: [MaintenanceSite], aircraft: [AircraftModel], supervisors: [Supervisor]) -> [String] {
        var result: [String] = []
        if siteID == nil || !sites.contains(where: { $0.id == siteID }) { result.append("Seleziona il luogo") }
        if aircraftID == nil || !aircraft.contains(where: { $0.id == aircraftID }) { result.append("Seleziona il tipo A/M") }
        if registration.trimmingCharacters(in: .whitespaces).isEmpty { result.append("Inserisci le marche A/M") }
        if maintenanceCode.trimmingCharacters(in: .whitespaces).isEmpty { result.append("Inserisci il codice manutentivo") }
        if ata.trimmingCharacters(in: .whitespaces).isEmpty { result.append("Inserisci il capitolo ATA") }
        if description.trimmingCharacters(in: .whitespaces).isEmpty { result.append("Inserisci la descrizione") }
        if summaryRowID.isEmpty { result.append("Seleziona la riga del riepilogo ENAC") }
        if normalizedHours == nil || normalizedHours! <= 0 || normalizedHours! > 24 { result.append("Inserisci ore valide, maggiori di 0 e non oltre 24") }
        if supervisorID == nil || !supervisors.contains(where: { $0.id == supervisorID }) { result.append("Seleziona il supervisore") }
        if documentFirst.trimmingCharacters(in: .whitespaces).isEmpty { result.append("Inserisci il numero documento") }
        if documentKind == .workReport && (!documentYear.allSatisfy(\.isNumber) || documentYear.count != 2) {
            result.append("L'anno del Work Report deve avere due cifre")
        }
        return result
    }
}
