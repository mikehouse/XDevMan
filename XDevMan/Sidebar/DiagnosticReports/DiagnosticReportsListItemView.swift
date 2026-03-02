import SwiftUI

struct DiagnosticReportsListItemView: View {
    
    let item: DiagnosticReport
    
    var body: some View {
        HStack {
            Image(systemName: "doc.text")
            Text(item.name)
                .lineLimit(1)
                .truncationMode(.middle)
        }
    }
}

#Preview {
    DiagnosticReportsListItemView(
        item: .init(
            name: "com.apple.SwiftUICore.SomeVeryLongDiagnosticReportName_2026-02-20-235959.crash",
            path: URL(fileURLWithPath: "/Users/demo/Library/Logs/DiagnosticReports/a.crash"),
            createdAt: .now,
            source: .reports
        )
    )
    .padding()
    .frame(width: 420, height: 120)
}
