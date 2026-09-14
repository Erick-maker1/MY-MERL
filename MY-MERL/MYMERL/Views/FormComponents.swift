import SwiftUI

struct RequiredFieldStyle: ViewModifier {
    let invalid: Bool
    func body(content: Content) -> some View {
        content
            .padding(10)
            .background(invalid ? Color.red.opacity(0.13) : Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(invalid ? .red : .clear, lineWidth: 1))
    }
}

extension View {
    func requiredField(_ invalid: Bool) -> some View { modifier(RequiredFieldStyle(invalid: invalid)) }
}

struct DirectoryPickerRow<Content: View>: View {
    let title: String
    let content: Content
    let add: () -> Void

    init(title: String, @ViewBuilder content: () -> Content, add: @escaping () -> Void) {
        self.title = title
        self.content = content()
        self.add = add
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            HStack(spacing: 8) {
                content
                Button(action: add) { Image(systemName: "plus").frame(width: 36, height: 36) }
                    .buttonStyle(.bordered)
                    .accessibilityLabel("Aggiungi \(title)")
            }
        }
    }
}

struct ActivityLegendView: View {
    var body: some View {
        DisclosureGroup("Legenda tipologie attività") {
            ForEach(ActivityCode.allCases) { code in
                HStack(alignment: .top) {
                    Text("X-\(code.rawValue)").font(.caption.monospaced()).frame(width: 52, alignment: .leading)
                    Text(code.title).font(.caption)
                    Spacer()
                }.padding(.vertical, 2)
            }
        }
    }
}
