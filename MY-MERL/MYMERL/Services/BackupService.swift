import Foundation
import SwiftData

enum BackupError: LocalizedError {
    case unsupportedVersion(Int)
    var errorDescription: String? {
        switch self { case .unsupportedVersion(let value): "Versione backup non supportata: \(value)" }
    }
}

enum BackupService {
    @MainActor static func export(from context: ModelContext) throws -> URL {
        let envelope = BackupEnvelope(
            sites: try context.fetch(FetchDescriptor<MaintenanceSite>()).map(SiteDTO.init),
            aircraft: try context.fetch(FetchDescriptor<AircraftModel>()).map(AircraftDTO.init),
            registrations: try context.fetch(FetchDescriptor<AircraftRegistration>()).map(RegistrationDTO.init),
            supervisors: try context.fetch(FetchDescriptor<Supervisor>()).map(SupervisorDTO.init),
            references: try context.fetch(FetchDescriptor<MaintenanceReference>()).map(ReferenceDTO.init),
            activities: try context.fetch(FetchDescriptor<ActivityRecord>()).map(ActivityDTO.init)
        )
        let encoder = JSONEncoder(); encoder.outputFormatting = [.prettyPrinted, .sortedKeys]; encoder.dateEncodingStrategy = .iso8601
        let url = temporaryURL(extension: "mymerlbackup")
        try encoder.encode(envelope).write(to: url, options: [.atomic, .completeFileProtection])
        return url
    }

    @MainActor static func restore(from url: URL, into context: ModelContext) throws {
        let access = url.startAccessingSecurityScopedResource(); defer { if access { url.stopAccessingSecurityScopedResource() } }
        let decoder = JSONDecoder(); decoder.dateDecodingStrategy = .iso8601
        let envelope = try decoder.decode(BackupEnvelope.self, from: Data(contentsOf: url))
        guard envelope.version == BackupEnvelope.schemaVersion else { throw BackupError.unsupportedVersion(envelope.version) }

        try context.fetch(FetchDescriptor<ActivityRecord>()).forEach { context.delete($0) }
        try context.fetch(FetchDescriptor<MaintenanceReference>()).forEach { context.delete($0) }
        try context.fetch(FetchDescriptor<AircraftRegistration>()).forEach { context.delete($0) }
        try context.fetch(FetchDescriptor<Supervisor>()).forEach { context.delete($0) }
        try context.fetch(FetchDescriptor<AircraftModel>()).forEach { context.delete($0) }
        try context.fetch(FetchDescriptor<MaintenanceSite>()).forEach { context.delete($0) }

        envelope.sites.forEach { let x = MaintenanceSite(id: $0.id, name: $0.name, mode: MaintenanceMode(rawValue: $0.modeRaw) ?? .base, company: $0.company, notes: $0.notes); x.createdAt = $0.createdAt; context.insert(x) }
        envelope.aircraft.forEach { let x = AircraftModel(id: $0.id, manufacturer: $0.manufacturer, modelName: $0.modelName, engineType: $0.engineType); x.createdAt = $0.createdAt; context.insert(x) }
        envelope.registrations.forEach { let x = AircraftRegistration(id: $0.id, registration: $0.registration, aircraftModelID: $0.aircraftModelID); x.createdAt = $0.createdAt; context.insert(x) }
        envelope.supervisors.forEach { let x = Supervisor(id: $0.id, surname: $0.surname, givenName: $0.givenName, licenceCategory: $0.licenceCategory, licenceNumber: $0.licenceNumber); x.createdAt = $0.createdAt; context.insert(x) }
        envelope.references.forEach { let x = MaintenanceReference(id: $0.id, aircraftModelID: $0.aircraftModelID, manualType: $0.manualType, code: $0.code, ata: $0.ata, activityDescription: $0.activityDescription, equivalenceGroup: $0.equivalenceGroup, summaryRowID: $0.summaryRowID); x.createdAt = $0.createdAt; context.insert(x) }
        envelope.activities.forEach { context.insert(ActivityRecord(dto: $0)) }
        try context.save()
    }

    static func temporaryURL(extension ext: String) -> URL {
        let formatter = DateFormatter(); formatter.dateFormat = "yyyy-MM-dd_HHmm"
        return FileManager.default.temporaryDirectory
            .appendingPathComponent("MY_MERL_\(formatter.string(from: .now)).\(ext)")
    }
}
