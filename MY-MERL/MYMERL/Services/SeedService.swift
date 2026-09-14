import Foundation
import SwiftData

enum SeedService {
    @MainActor static func seedIfNeeded(_ context: ModelContext) {
        let descriptor = FetchDescriptor<MaintenanceSite>()
        guard (try? context.fetchCount(descriptor)) == 0 else { return }

        let company = "Impresa di esempio"
        let ronchi = MaintenanceSite(name: "Ronchi dei Legionari", mode: .base, company: company)
        let tolmezzo = MaintenanceSite(name: "Tolmezzo", mode: .line, company: company)
        let h145 = AircraftModel(manufacturer: "Airbus", modelName: "H145", engineType: "Arriel 2D")
        let as350 = AircraftModel(manufacturer: "Airbus", modelName: "AS350 B3", engineType: "")
        let supervisor = Supervisor(surname: "Acerboni", givenName: "Lorenzo")
        [ronchi, tolmezzo].forEach(context.insert)
        [h145, as350].forEach(context.insert)
        context.insert(AircraftRegistration(registration: "I-ABCD", aircraftModelID: h145.id))
        context.insert(AircraftRegistration(registration: "I-EFGH", aircraftModelID: as350.id))
        context.insert(supervisor)
        context.insert(MaintenanceReference(
            aircraftModelID: h145.id, manualType: "AMM", code: "21-53-02,6-1", ata: "21",
            activityDescription: "Inspection of the condenser fan and condenser assembly",
            equivalenceGroup: "H145-ATA21-CONDENSER-INSPECTION", summaryRowID: "S2-21"
        ))
        try? context.save()
    }
}
