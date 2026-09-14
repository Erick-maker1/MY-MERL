import SwiftUI
import SwiftData

@main
struct MYMERLApp: App {
    private let container: ModelContainer = {
        let schema = Schema([
            MaintenanceSite.self, AircraftModel.self, AircraftRegistration.self,
            Supervisor.self, MaintenanceReference.self, ActivityRecord.self
        ])
        let configuration = ModelConfiguration("MY_MERL", schema: schema, isStoredInMemoryOnly: false, cloudKitDatabase: .none)
        do { return try ModelContainer(for: schema, configurations: [configuration]) }
        catch { fatalError("Impossibile aprire il database locale: \(error)") }
    }()

    var body: some Scene {
        WindowGroup { RootView().task { SeedService.seedIfNeeded(container.mainContext) } }
            .modelContainer(container)
    }
}
