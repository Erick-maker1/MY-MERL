import SwiftUI
import SwiftData

struct SummaryView: View {
    @Query(sort: \ActivityRecord.date) private var records: [ActivityRecord]
    private var rows: [ATASummary] { SummaryCalculator.byATA(records) }
    private var total: OverallSummary { SummaryCalculator.overall(records) }

    var body: some View {
        List {
            Section("Informazioni riassuntive") {
                value("Giornate totali", SummaryCalculator.displayedDays(total.totalDays))
                value("Giornate Line Maintenance", SummaryCalculator.displayedDays(total.lineDays))
                value("Giornate Base Maintenance", SummaryCalculator.displayedDays(total.baseDays))
                value("Attività eseguite", "\(total.activityCount)")
                value("Tipologie tecniche diverse", "\(total.technicalTypeCount)")
                value("Tipi di aeromobile", "\(total.aircraftTypeCount)")
                value("Tipologie troubleshooting", "\(total.troubleshootingTypeCount)")
                value("Tipologie prove funzionali", "\(total.functionalTestTypeCount)")
                value("Engine Run-up", "\(total.engineRunUpCount)")
            }
            Section("Per capitolo ATA") {
                ForEach(rows) { row in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack { Text("Sez. \(row.section) · ATA \(row.ata)").fontWeight(.semibold); Spacer(); Text("\(row.activityCount) attività") }
                        Text(row.title).font(.caption).foregroundStyle(.secondary)
                        HStack {
                            Text("Linea / Base")
                            Spacer()
                            Text("\(SummaryCalculator.displayedDays(row.lineDays)) / \(SummaryCalculator.displayedDays(row.baseDays))")
                                .monospacedDigit()
                        }.font(.subheadline)
                        Text("\(row.technicalTypeCount) tipologie di contenuto tecnico diverso")
                            .font(.caption).foregroundStyle(.secondary)
                    }.padding(.vertical, 3)
                }
            }
            Section { Text("Una giornata equivalente è calcolata su 6 ore. I valori completi restano nel database; la visualizzazione è troncata a un decimale.").font(.caption).foregroundStyle(.secondary) }
        }.navigationTitle("Riepilogo")
    }

    private func value(_ title: String, _ result: String) -> some View {
        LabeledContent(title) { Text(result).fontWeight(.semibold).monospacedDigit() }
    }
}
