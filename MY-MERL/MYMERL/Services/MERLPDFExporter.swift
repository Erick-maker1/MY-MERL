import Foundation
import PDFKit
import UIKit

enum PDFExportError: LocalizedError {
    case templateMissing, templatePageMissing, noRecords, invalidPage
    var errorDescription: String? {
        switch self {
        case .templateMissing: "Modello ENAC non trovato nell'app."
        case .templatePageMissing: "Pagina MERL non trovata nel modello ENAC."
        case .noRecords: "Non ci sono attività valide da esportare."
        case .invalidPage: "La pagina MERL richiesta non contiene otto attività."
        }
    }
}

enum MERLPDFExporter {
    static func exportPage(_ allRecords: [ActivityRecord], pageNumber: Int) throws -> URL {
        let records = allRecords.filter { $0.isMERLEligible }.sorted { $0.date < $1.date }
        let start = (pageNumber - 1) * 8
        guard pageNumber > 0, start >= 0, records.count >= start + 8 else { throw PDFExportError.invalidPage }
        guard let sourceURL = Bundle.main.url(forResource: "Part66_MERL_EdLuglio_2006", withExtension: "pdf"),
              let document = PDFDocument(url: sourceURL) else { throw PDFExportError.templateMissing }
        guard let template = document.page(at: 2) else { throw PDFExportError.templatePageMissing }
        let pageRecords = Array(records[start..<(start + 8)])
        guard let page = renderedPage(from: template, drawing: { draw(records: pageRecords, in: $0) }) else {
            throw PDFExportError.templateMissing
        }
        let result = PDFDocument(); result.insert(page, at: 0)
        let url = BackupService.temporaryURL(prefix: String(format: "MY_MERL_Pagina_%03d", pageNumber), extension: "pdf")
        guard result.write(to: url) else { throw PDFExportError.templateMissing }
        return url
    }

    static func export(_ allRecords: [ActivityRecord]) throws -> URL {
        let records = allRecords.filter { $0.isMERLEligible }.sorted { $0.date < $1.date }
        guard !records.isEmpty else { throw PDFExportError.noRecords }
        guard let sourceURL = Bundle.main.url(forResource: "Part66_MERL_EdLuglio_2006", withExtension: "pdf"),
              let document = PDFDocument(url: sourceURL) else { throw PDFExportError.templateMissing }
        guard let template = document.page(at: 2) else { throw PDFExportError.templatePageMissing }
        let url = BackupService.temporaryURL(prefix: "MY_MERL_Completo", extension: "pdf")
        let result = PDFDocument()
        var outputIndex = 0
        // L'impresa è intenzionalmente ignorata: il relativo campo del modulo
        // ufficiale ENAC deve rimanere sempre vuoto e sarà compilato a mano.
        for chunk in records.chunked(size: 8) {
            guard let page = renderedPage(from: template, drawing: { draw(records: chunk, in: $0) }) else { continue }
            result.insert(page, at: outputIndex); outputIndex += 1
        }
        let summaries = SummaryCalculator.byATA(records)
        for sourceIndex in 4...8 {
            guard let sourcePage = document.page(at: sourceIndex),
                  let page = renderedPage(from: sourcePage, drawing: { bounds in
                      drawSummaryPage(sourceIndex: sourceIndex, summaries: summaries, records: records, bounds: bounds)
                  }) else { continue }
            result.insert(page, at: outputIndex); outputIndex += 1
        }
        guard result.write(to: url) else { throw PDFExportError.templateMissing }
        return url
    }

    private static func renderedPage(from template: PDFPage, drawing: @escaping (CGRect) -> Void) -> PDFPage? {
        let bounds = template.bounds(for: .mediaBox)
        let data = UIGraphicsPDFRenderer(bounds: bounds).pdfData { output in
            output.beginPage(); drawTemplate(template, into: output.cgContext, bounds: bounds); drawing(bounds)
        }
        return PDFDocument(data: data)?.page(at: 0)
    }

    private static func drawTemplate(_ page: PDFPage, into context: CGContext, bounds: CGRect) {
        context.saveGState()
        context.translateBy(x: 0, y: bounds.height)
        context.scaleBy(x: 1, y: -1)
        page.draw(with: .mediaBox, to: context)
        context.restoreGState()
    }

    private static func draw(records: [ActivityRecord], in bounds: CGRect) {
        let dark = UIColor(red: 0.05, green: 0.08, blue: 0.10, alpha: 1)
        // Il campo impresa resta vuoto sul modulo ufficiale e sarà compilato manualmente.
        let centers: [CGFloat] = [43, 85, 131, 180, 230, 280, 403, 533, 609, 693]
        let widths: [CGFloat] = [34, 40, 40, 44, 32, 42, 176, 55, 67, 78]
        let baselines: [CGFloat] = [361, 332, 303, 274, 245, 216, 187, 158]
        let date = DateFormatter(); date.dateFormat = "dd/MM/yy"
        for (record, baseline) in zip(records, baselines) {
            let values = [date.string(from: record.date), record.siteName, record.aircraftModelName,
                          record.registration, record.ata, record.activityType, record.fullDescription,
                          hours(record.workHours), record.documentNumber, record.supervisorMERLName]
            for index in values.indices {
                if index == 1 {
                    drawWrapped(values[index], rect: CGRect(x: centers[index] - widths[index] / 2,
                        y: bounds.height - baseline - 13, width: widths[index], height: 27),
                        fontSize: 9.2, alignment: .center, color: dark)
                } else if index == 6 {
                    drawWrapped(values[index], rect: CGRect(x: 313, y: bounds.height - baseline - 15,
                        width: 181, height: 28), fontSize: 9.2, alignment: .left, color: dark)
                } else {
                    drawFit(values[index], centerX: centers[index], baseline: baseline,
                            maxWidth: widths[index], maxSize: 9.8, bounds: bounds, color: dark)
                }
            }
        }
    }

    private static func drawSummaryPage(sourceIndex: Int, summaries: [ATASummary], records: [ActivityRecord], bounds: CGRect) {
        switch sourceIndex {
        case 4:
            drawSection(1, rowIDs: ["S1-05","S1-06","S1-08","S1-09","S1-10","S1-11","S1-12"],
                        headerTop: 219.7, tableBottomTop: 315.7, totalBaseline: 511, summaries: summaries, bounds: bounds)
        case 5:
            drawSection(2, rowIDs: ENACSummaryRow.all.filter { $0.section == 2 }.map(\.id),
                        headerTop: 226.6, tableBottomTop: 597.3, totalBaseline: 232, summaries: summaries, bounds: bounds)
        case 6:
            drawSection(3, rowIDs: ENACSummaryRow.all.filter { $0.section == 3 }.map(\.id),
                        headerTop: 231.2, tableBottomTop: 368.5, totalBaseline: 458, summaries: summaries, bounds: bounds,
                        xPositions: [370, 436, 501])
            drawSection(4, rowIDs: ENACSummaryRow.all.filter { $0.section == 4 }.map(\.id),
                        headerTop: 583.4, tableBottomTop: 679.37, totalBaseline: 147, summaries: summaries, bounds: bounds,
                        xPositions: [370, 436, 501])
        case 7:
            drawSection(5, rowIDs: ENACSummaryRow.all.filter { $0.section == 5 }.map(\.id),
                        headerTop: 242.7, tableBottomTop: 476.1, totalBaseline: 350, summaries: summaries, bounds: bounds)
        case 8:
            let total = SummaryCalculator.overall(records)
            let values = [SummaryCalculator.displayedDays(total.totalDays), "\(total.activityCount)", "\(total.technicalTypeCount)",
                          "\(total.aircraftTypeCount)", SummaryCalculator.displayedDays(total.lineDays),
                          SummaryCalculator.displayedDays(total.baseDays), "\(total.troubleshootingTypeCount)",
                          "\(total.functionalTestTypeCount)", "\(total.engineRunUpCount)"]
            let baselines: [CGFloat] = [673.5, 659.5, 646.5, 622.5, 594.5, 580.5, 555.5, 541.5, 515.5]
            for (value, baseline) in zip(values, baselines) {
                clear(centerX: 522, baseline: baseline, width: 52, height: 11, bounds: bounds)
                drawFit(value, centerX: 522, baseline: baseline, maxWidth: 48, maxSize: 10.5, bounds: bounds, color: .black)
            }
        default: break
        }
    }

    private static func drawSection(_ section: Int, rowIDs: [String], headerTop: CGFloat, tableBottomTop: CGFloat,
                                    totalBaseline: CGFloat, summaries: [ATASummary], bounds: CGRect,
                                    xPositions: [CGFloat] = [363, 429, 503]) {
        let byID = Dictionary(uniqueKeysWithValues: summaries.map { ($0.id, $0) })
        let rowHeight = (tableBottomTop - headerTop) / CGFloat(rowIDs.count)
        let sectionRows = rowIDs.compactMap { byID[$0] }
        for (index, rowID) in rowIDs.enumerated() {
            guard let row = byID[rowID], row.activityCount > 0 else { continue }
            let baseline = bounds.height - (headerTop + rowHeight * (CGFloat(index) + 0.5)) - 3.5
            let values = ["\(SummaryCalculator.displayedDays(row.lineDays)) / \(SummaryCalculator.displayedDays(row.baseDays))",
                          "\(row.activityCount)", "\(row.technicalTypeCount)"]
            for i in 0..<3 {
                clear(centerX: xPositions[i], baseline: baseline, width: [82, 66, 74][i], height: 10, bounds: bounds)
                drawFit(values[i], centerX: xPositions[i], baseline: baseline, maxWidth: [62, 45, 52][i],
                        maxSize: 10.0, bounds: bounds, color: .black)
            }
        }
        let lineDays = sectionRows.reduce(0) { $0 + $1.lineDays }
        let baseDays = sectionRows.reduce(0) { $0 + $1.baseDays }
        let totals = ["\(SummaryCalculator.displayedDays(lineDays)) / \(SummaryCalculator.displayedDays(baseDays))",
                      "\(sectionRows.reduce(0) { $0 + $1.activityCount })",
                      "\(sectionRows.reduce(0) { $0 + $1.technicalTypeCount })"]
        for i in 0..<3 {
            clear(centerX: xPositions[i], baseline: totalBaseline, width: [82, 66, 74][i], height: 11, bounds: bounds)
            drawFit(totals[i], centerX: xPositions[i], baseline: totalBaseline, maxWidth: [62, 45, 52][i],
                    maxSize: 10.2, bounds: bounds, color: .black)
        }
    }

    private static func clear(centerX: CGFloat, baseline: CGFloat, width: CGFloat, height: CGFloat, bounds: CGRect) {
        UIColor.white.setFill()
        UIRectFill(CGRect(x: centerX - width / 2, y: bounds.height - baseline - height + 2, width: width, height: height))
    }

    private static func drawFit(_ text: String, centerX: CGFloat, baseline: CGFloat, maxWidth: CGFloat,
                                maxSize: CGFloat, bounds: CGRect, color: UIColor) {
        var size = maxSize
        var font = UIFont.systemFont(ofSize: size, weight: .semibold)
        while size > 6.5 && (text as NSString).size(withAttributes: [.font: font]).width > maxWidth {
            size -= 0.2; font = UIFont.systemFont(ofSize: size, weight: .semibold)
        }
        let attributes: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
        let measured = (text as NSString).size(withAttributes: attributes)
        (text as NSString).draw(at: CGPoint(x: centerX - measured.width / 2,
            y: bounds.height - baseline - font.ascender), withAttributes: attributes)
    }

    private static func drawWrapped(_ text: String, rect: CGRect, fontSize: CGFloat,
                                    alignment: NSTextAlignment, color: UIColor) {
        let paragraph = NSMutableParagraphStyle(); paragraph.alignment = alignment
        paragraph.lineBreakMode = .byWordWrapping; paragraph.minimumLineHeight = 7.2; paragraph.maximumLineHeight = 7.2
        let font = UIFont.systemFont(ofSize: fontSize, weight: .semibold)
        let attributes: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color, .paragraphStyle: paragraph]
        let measured = (text as NSString).boundingRect(with: CGSize(width: rect.width, height: rect.height),
            options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: attributes, context: nil)
        let centered = CGRect(x: rect.minX, y: rect.midY - min(measured.height, rect.height) / 2,
                              width: rect.width, height: rect.height)
        (text as NSString).draw(with: centered, options: [.usesLineFragmentOrigin, .truncatesLastVisibleLine], attributes: attributes, context: nil)
    }

    private static func hours(_ value: Double) -> String {
        let rounded = value.rounded()
        if abs(value - rounded) < 0.001 { return String(Int(rounded)) }
        return String(format: "%.1f", value).replacingOccurrences(of: ".", with: ",")
    }
}

private extension Array {
    func chunked(size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map { Array(self[$0..<Swift.min($0 + size, count)]) }
    }
}
