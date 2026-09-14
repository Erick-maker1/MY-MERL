import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            NavigationStack { NewActivityView() }
                .tabItem { Label("Nuova", systemImage: "plus.circle.fill") }
            NavigationStack { RegisterView() }
                .tabItem { Label("Registro", systemImage: "list.bullet.rectangle") }
            NavigationStack { SummaryView() }
                .tabItem { Label("Riepilogo", systemImage: "sum") }
            NavigationStack { ExportView() }
                .tabItem { Label("Esporta", systemImage: "square.and.arrow.up") }
            NavigationStack { DirectoriesView() }
                .tabItem { Label("Rubriche", systemImage: "books.vertical") }
        }
        .tint(Color(red: 0.02, green: 0.50, blue: 0.69))
    }
}
