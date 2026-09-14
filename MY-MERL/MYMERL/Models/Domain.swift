import Foundation
import SwiftData

enum MaintenanceMode: String, Codable, CaseIterable, Identifiable {
    case base = "Base"
    case line = "Linea"
    var id: String { rawValue }
    var prefix: String { self == .base ? "B" : "L" }
}

enum DocumentKind: String, Codable, CaseIterable, Identifiable {
    case qtbHTL = "QTB / HTL"
    case workReport = "Work Report"
    var id: String { rawValue }
}

enum ActivityCode: String, Codable, CaseIterable, Identifiable {
    case ADJ, CTS, DOC, DVI, FOT, LOC, MEL, OPC, RIA, RUP, SGH, SPE, TSE, TVC, SIM
    var id: String { rawValue }
    var title: String {
        switch self {
        case .ADJ: "Adjustment"
        case .CTS: "Complex Troubleshooting"
        case .DOC: "Use of Documents"
        case .DVI: "Detailed Visual Inspection"
        case .FOT: "Functional Operational Test"
        case .LOC: "Location Identification of System Components"
        case .MEL: "Minimum Equipment List item requiring a maintenance procedure"
        case .OPC: "Operational Check"
        case .RIA: "Removal Installation Activation"
        case .RUP: "Troubleshooting requiring APU or Engine run up"
        case .SGH: "Servicing Ground Handling"
        case .SPE: "Special Check"
        case .TSE: "Troubleshooting Exercise"
        case .TVC: "Carry out through Visual Check / Explanation"
        case .SIM: "Simulation of maintenance activity"
        }
    }
}

struct ENACSummaryRow: Identifiable, Hashable {
    let id: String
    let section: Int
    let ata: String
    let title: String

    static let all: [ENACSummaryRow] = [
        .init(id:"S1-05",section:1,ata:"05",title:"Time limits / Maintenance Checks"), .init(id:"S1-06",section:1,ata:"06",title:"Dimensions/Areas"),
        .init(id:"S1-08",section:1,ata:"08",title:"Leveling/Weighting"), .init(id:"S1-09",section:1,ata:"09",title:"Towing and Taxing"),
        .init(id:"S1-10",section:1,ata:"10",title:"Parking and Mooring"), .init(id:"S1-11",section:1,ata:"11",title:"Placards and Markings"), .init(id:"S1-12",section:1,ata:"12",title:"Servicing"),
        .init(id:"S2-21",section:2,ata:"21",title:"Air Conditioning"), .init(id:"S2-22",section:2,ata:"22",title:"Auto Flight (lev 1)"),
        .init(id:"S2-23",section:2,ata:"23",title:"Communications (lev 1)"), .init(id:"S2-24",section:2,ata:"24",title:"Electrical Power (lev 3)"),
        .init(id:"S2-25",section:2,ata:"25",title:"Equipment/Furnishings"), .init(id:"S2-26",section:2,ata:"26",title:"Fire Protection (lev 3)"),
        .init(id:"S2-27",section:2,ata:"27",title:"Flight Controls (lev 3)"), .init(id:"S2-28",section:2,ata:"28",title:"Fuel (lev 3)"),
        .init(id:"S2-29",section:2,ata:"29",title:"Hydraulics (lev 3)"), .init(id:"S2-30",section:2,ata:"30",title:"Ice and Rain Protection (lev 3)"),
        .init(id:"S2-31",section:2,ata:"31",title:"Indicating/Recording Systems"), .init(id:"S2-32",section:2,ata:"32",title:"Landing Gear (lev 3)"),
        .init(id:"S2-33",section:2,ata:"33",title:"Lights (lev 3)"), .init(id:"S2-34",section:2,ata:"34",title:"Navigation (lev 1)"),
        .init(id:"S2-35",section:2,ata:"35",title:"Oxygen (lev 3)"), .init(id:"S2-36",section:2,ata:"36",title:"Pneumatic Systems (lev 3)"),
        .init(id:"S2-37",section:2,ata:"37",title:"Vacuum Systems"), .init(id:"S2-38",section:2,ata:"38",title:"Water/Waste (lev 3)"),
        .init(id:"S2-45",section:2,ata:"45",title:"Central Maintenance System"), .init(id:"S2-51",section:2,ata:"51",title:"Structures"),
        .init(id:"S2-52",section:2,ata:"52",title:"Doors"), .init(id:"S2-53",section:2,ata:"53",title:"Fuselage"), .init(id:"S2-54",section:2,ata:"54",title:"Nacelle-Pilons"),
        .init(id:"S2-55",section:2,ata:"55",title:"Stabilisers"), .init(id:"S2-56",section:2,ata:"56",title:"Windows"), .init(id:"S2-57",section:2,ata:"57",title:"Wings"), .init(id:"S2-61",section:2,ata:"61",title:"Propeller"),
        .init(id:"S3-22",section:3,ata:"22",title:"Auto Flight (lev 3)"), .init(id:"S3-23",section:3,ata:"23",title:"Communications (lev 3)"),
        .init(id:"S3-24",section:3,ata:"24",title:"Electrical Power (lev 3)"), .init(id:"S3-25",section:3,ata:"25",title:"Equipment/Furnishings (lev 3)"),
        .init(id:"S3-27A",section:3,ata:"27",title:"Flight Controls (lev 1)"), .init(id:"S3-27B",section:3,ata:"27",title:"Fly by wire (lev 2)"),
        .init(id:"S3-31",section:3,ata:"31",title:"Indicating/Recording Systems (lev 2)"), .init(id:"S3-33",section:3,ata:"33",title:"Lights (lev 3)"),
        .init(id:"S3-34",section:3,ata:"34",title:"Navigation"), .init(id:"S3-45",section:3,ata:"45",title:"Central Maintenance System"),
        .init(id:"S4-18",section:4,ata:"18",title:"Vibration/Noise Analysis"), .init(id:"S4-62",section:4,ata:"62",title:"Main Rotors"),
        .init(id:"S4-63",section:4,ata:"63",title:"Rotor Drive"), .init(id:"S4-64",section:4,ata:"64",title:"Tail Rotors"),
        .init(id:"S4-65",section:4,ata:"65",title:"Tail Rotor Drive"), .init(id:"S4-67",section:4,ata:"67",title:"Rotorcraft Flight Controls"), .init(id:"S4-71",section:4,ata:"71",title:"Power Plant"),
        .init(id:"S5-49",section:5,ata:"49",title:"Airborne Auxiliary Power"), .init(id:"S5-71",section:5,ata:"71",title:"Power Plant"),
        .init(id:"S5-72P",section:5,ata:"72",title:"Piston Engines"), .init(id:"S5-72T",section:5,ata:"72",title:"Turbine Engines"),
        .init(id:"S5-73P",section:5,ata:"73",title:"Fuel and Control, Piston"), .init(id:"S5-73T",section:5,ata:"73",title:"Fuel and Control, Turbine"),
        .init(id:"S5-74P",section:5,ata:"74",title:"Ignition Systems, Piston"), .init(id:"S5-74T",section:5,ata:"74",title:"Ignition Systems, Turbine"),
        .init(id:"S5-76",section:5,ata:"76",title:"Engine Controls"), .init(id:"S5-77",section:5,ata:"77",title:"Engine Indicating"),
        .init(id:"S5-78P",section:5,ata:"78",title:"Exhaust, Piston"), .init(id:"S5-78T",section:5,ata:"78",title:"Exhaust, Turbine"),
        .init(id:"S5-79",section:5,ata:"79",title:"Oil"), .init(id:"S5-80",section:5,ata:"80",title:"Starting"),
        .init(id:"S5-81",section:5,ata:"81",title:"Turbines, Piston Engines"), .init(id:"S5-82",section:5,ata:"82",title:"Engine Water Injection"), .init(id:"S5-83",section:5,ata:"83",title:"Accessory Gear Boxes")
    ]
    static func candidates(for ata: String) -> [ENACSummaryRow] { all.filter { $0.ata == ata.leftPaddedATA } }
}

private extension String {
    var leftPaddedATA: String { count == 1 ? "0" + self : self }
}

@Model final class MaintenanceSite {
    @Attribute(.unique) var id: UUID
    var name: String
    var modeRaw: String
    var company: String
    var notes: String
    var createdAt: Date

    init(id: UUID = UUID(), name: String, mode: MaintenanceMode, company: String, notes: String = "") {
        self.id = id; self.name = name; self.modeRaw = mode.rawValue
        self.company = company; self.notes = notes; self.createdAt = .now
    }
    var mode: MaintenanceMode { MaintenanceMode(rawValue: modeRaw) ?? .base }
}

@Model final class AircraftModel {
    @Attribute(.unique) var id: UUID
    var manufacturer: String
    var modelName: String
    var engineType: String
    var createdAt: Date

    init(id: UUID = UUID(), manufacturer: String, modelName: String, engineType: String = "") {
        self.id = id; self.manufacturer = manufacturer; self.modelName = modelName
        self.engineType = engineType; self.createdAt = .now
    }
}

@Model final class AircraftRegistration {
    @Attribute(.unique) var id: UUID
    var registration: String
    var aircraftModelID: UUID
    var createdAt: Date

    init(id: UUID = UUID(), registration: String, aircraftModelID: UUID) {
        self.id = id; self.registration = registration.uppercased()
        self.aircraftModelID = aircraftModelID; self.createdAt = .now
    }
}

@Model final class Supervisor {
    @Attribute(.unique) var id: UUID
    var surname: String
    var givenName: String
    var licenceCategory: String
    var licenceNumber: String
    var createdAt: Date

    init(id: UUID = UUID(), surname: String, givenName: String, licenceCategory: String = "", licenceNumber: String = "") {
        self.id = id; self.surname = surname; self.givenName = givenName
        self.licenceCategory = licenceCategory; self.licenceNumber = licenceNumber; self.createdAt = .now
    }
    var fullName: String { "\(surname) \(givenName)".trimmingCharacters(in: .whitespaces) }
    var merlName: String {
        guard let first = givenName.trimmingCharacters(in: .whitespaces).first else { return surname }
        return "\(surname) \(first)."
    }
}

@Model final class MaintenanceReference {
    @Attribute(.unique) var id: UUID
    var aircraftModelID: UUID
    var manualType: String
    var code: String
    var ata: String
    var activityDescription: String
    var equivalenceGroup: String
    var summaryRowID: String
    var createdAt: Date

    init(id: UUID = UUID(), aircraftModelID: UUID, manualType: String, code: String, ata: String,
         activityDescription: String, equivalenceGroup: String = "", summaryRowID: String = "") {
        self.id = id; self.aircraftModelID = aircraftModelID; self.manualType = manualType
        self.code = code; self.ata = ata; self.activityDescription = activityDescription
        self.equivalenceGroup = equivalenceGroup; self.summaryRowID = summaryRowID; self.createdAt = .now
    }
}

@Model final class ActivityRecord {
    @Attribute(.unique) var id: UUID
    var date: Date
    var siteID: UUID
    var siteName: String
    var maintenanceModeRaw: String
    var company: String
    var aircraftModelID: UUID
    var aircraftModelName: String
    var registration: String
    var manualType: String
    var maintenanceCode: String
    var ata: String
    var activityCodeRaw: String
    var activityDescription: String
    var equivalenceGroup: String
    var summaryRowID: String
    var workHours: Double
    var documentKindRaw: String
    var documentNumber: String
    var supervisorFullName: String
    var supervisorMERLName: String
    var supervisorLicenceCategory: String
    var supervisorLicenceNumber: String
    var isTroubleshooting: Bool
    var isFunctionalTest: Bool
    var isEngineRunUp: Bool
    var isMERLEligible: Bool
    var createdAt: Date

    init(id: UUID = UUID(), date: Date, site: MaintenanceSite, aircraft: AircraftModel,
         registration: String, manualType: String, maintenanceCode: String, ata: String,
         activityCode: ActivityCode, activityDescription: String, equivalenceGroup: String, summaryRowID: String,
         workHours: Double, documentKind: DocumentKind, documentNumber: String,
         supervisor: Supervisor, isEngineRunUp: Bool, isMERLEligible: Bool = true) {
        self.id = id; self.date = date; self.siteID = site.id; self.siteName = site.name
        self.maintenanceModeRaw = site.modeRaw; self.company = site.company
        self.aircraftModelID = aircraft.id; self.aircraftModelName = aircraft.modelName
        self.registration = registration; self.manualType = manualType; self.maintenanceCode = maintenanceCode
        self.ata = ata; self.activityCodeRaw = activityCode.rawValue; self.activityDescription = activityDescription
        self.equivalenceGroup = equivalenceGroup; self.summaryRowID = summaryRowID; self.workHours = workHours
        self.documentKindRaw = documentKind.rawValue; self.documentNumber = documentNumber
        self.supervisorFullName = supervisor.fullName; self.supervisorMERLName = supervisor.merlName
        self.supervisorLicenceCategory = supervisor.licenceCategory; self.supervisorLicenceNumber = supervisor.licenceNumber
        self.isTroubleshooting = [.CTS, .TSE].contains(activityCode)
        self.isFunctionalTest = [.FOT, .OPC].contains(activityCode)
        self.isEngineRunUp = isEngineRunUp; self.isMERLEligible = isMERLEligible; self.createdAt = .now
    }

    init(dto: ActivityDTO) {
        id = dto.id; date = dto.date; siteID = dto.siteID; siteName = dto.siteName
        maintenanceModeRaw = dto.maintenanceModeRaw; company = dto.company
        aircraftModelID = dto.aircraftModelID; aircraftModelName = dto.aircraftModelName
        registration = dto.registration; manualType = dto.manualType; maintenanceCode = dto.maintenanceCode
        ata = dto.ata; activityCodeRaw = dto.activityCodeRaw; activityDescription = dto.activityDescription
        equivalenceGroup = dto.equivalenceGroup; summaryRowID = dto.summaryRowID; workHours = dto.workHours
        documentKindRaw = dto.documentKindRaw; documentNumber = dto.documentNumber
        supervisorFullName = dto.supervisorFullName; supervisorMERLName = dto.supervisorMERLName
        supervisorLicenceCategory = dto.supervisorLicenceCategory; supervisorLicenceNumber = dto.supervisorLicenceNumber
        isTroubleshooting = dto.isTroubleshooting; isFunctionalTest = dto.isFunctionalTest
        isEngineRunUp = dto.isEngineRunUp; isMERLEligible = dto.isMERLEligible; createdAt = dto.createdAt
    }

    var mode: MaintenanceMode { MaintenanceMode(rawValue: maintenanceModeRaw) ?? .base }
    var activityCode: ActivityCode { ActivityCode(rawValue: activityCodeRaw) ?? .DVI }
    var activityType: String { "\(mode.prefix)-\(activityCode.rawValue)" }
    var fullDescription: String { "\(manualType) \(maintenanceCode) - \(activityDescription)" }
}

struct BackupEnvelope: Codable {
    static let schemaVersion = 2
    var version: Int = schemaVersion
    var exportedAt: Date = .now
    var sites: [SiteDTO]
    var aircraft: [AircraftDTO]
    var registrations: [RegistrationDTO]
    var supervisors: [SupervisorDTO]
    var references: [ReferenceDTO]
    var activities: [ActivityDTO]
}

struct SiteDTO: Codable { var id: UUID; var name, modeRaw, company, notes: String; var createdAt: Date }
struct AircraftDTO: Codable { var id: UUID; var manufacturer, modelName, engineType: String; var createdAt: Date }
struct RegistrationDTO: Codable { var id: UUID; var registration: String; var aircraftModelID: UUID; var createdAt: Date }
struct SupervisorDTO: Codable { var id: UUID; var surname, givenName, licenceCategory, licenceNumber: String; var createdAt: Date }
struct ReferenceDTO: Codable { var id, aircraftModelID: UUID; var manualType, code, ata, activityDescription, equivalenceGroup, summaryRowID: String; var createdAt: Date }
struct ActivityDTO: Codable {
    var id: UUID; var date: Date; var siteID: UUID; var siteName, maintenanceModeRaw, company: String
    var aircraftModelID: UUID; var aircraftModelName, registration, manualType, maintenanceCode, ata: String
    var activityCodeRaw, activityDescription, equivalenceGroup, summaryRowID: String; var workHours: Double
    var documentKindRaw, documentNumber, supervisorFullName, supervisorMERLName: String
    var supervisorLicenceCategory, supervisorLicenceNumber: String
    var isTroubleshooting, isFunctionalTest, isEngineRunUp, isMERLEligible: Bool; var createdAt: Date
}

extension SiteDTO { init(_ x: MaintenanceSite) { self.init(id: x.id, name: x.name, modeRaw: x.modeRaw, company: x.company, notes: x.notes, createdAt: x.createdAt) } }
extension AircraftDTO { init(_ x: AircraftModel) { self.init(id: x.id, manufacturer: x.manufacturer, modelName: x.modelName, engineType: x.engineType, createdAt: x.createdAt) } }
extension RegistrationDTO { init(_ x: AircraftRegistration) { self.init(id: x.id, registration: x.registration, aircraftModelID: x.aircraftModelID, createdAt: x.createdAt) } }
extension SupervisorDTO { init(_ x: Supervisor) { self.init(id: x.id, surname: x.surname, givenName: x.givenName, licenceCategory: x.licenceCategory, licenceNumber: x.licenceNumber, createdAt: x.createdAt) } }
extension ReferenceDTO { init(_ x: MaintenanceReference) { self.init(id: x.id, aircraftModelID: x.aircraftModelID, manualType: x.manualType, code: x.code, ata: x.ata, activityDescription: x.activityDescription, equivalenceGroup: x.equivalenceGroup, summaryRowID: x.summaryRowID, createdAt: x.createdAt) } }
extension ActivityDTO {
    init(_ x: ActivityRecord) {
        self.init(id: x.id, date: x.date, siteID: x.siteID, siteName: x.siteName,
            maintenanceModeRaw: x.maintenanceModeRaw, company: x.company, aircraftModelID: x.aircraftModelID,
            aircraftModelName: x.aircraftModelName, registration: x.registration, manualType: x.manualType,
            maintenanceCode: x.maintenanceCode, ata: x.ata, activityCodeRaw: x.activityCodeRaw,
            activityDescription: x.activityDescription, equivalenceGroup: x.equivalenceGroup, summaryRowID: x.summaryRowID, workHours: x.workHours,
            documentKindRaw: x.documentKindRaw, documentNumber: x.documentNumber,
            supervisorFullName: x.supervisorFullName, supervisorMERLName: x.supervisorMERLName,
            supervisorLicenceCategory: x.supervisorLicenceCategory, supervisorLicenceNumber: x.supervisorLicenceNumber,
            isTroubleshooting: x.isTroubleshooting, isFunctionalTest: x.isFunctionalTest,
            isEngineRunUp: x.isEngineRunUp, isMERLEligible: x.isMERLEligible, createdAt: x.createdAt)
    }
}
