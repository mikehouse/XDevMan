import SwiftUI

struct DiagnosticReportsListView: View {
    
    @Binding var selectedItem: DiagnosticReport?
    @Binding var refreshToken: UUID
    @Environment(\.diagnosticReportsService) private var diagnosticReportsService
    @State private var reports: [DiagnosticReport]?
    @State private var retiredReports: [DiagnosticReport]?
    
    var body: some View {
        Group {
            if let reports, let retiredReports {
                if reports.isEmpty && retiredReports.isEmpty {
                    NothingView(text: "No diagnostic reports found.")
                } else {
                    List(selection: $selectedItem) {
                        if !reports.isEmpty {
                            Section("Reports") {
                                ForEach(reports) { item in
                                    DiagnosticReportsListItemView(item: item)
                                        .modifier(ListItemViewPaddingModifier())
                                        .tag(item)
                                }
                            }
                        }
                        if !retiredReports.isEmpty {
                            Section("Retired") {
                                ForEach(retiredReports) { item in
                                    DiagnosticReportsListItemView(item: item)
                                        .modifier(ListItemViewPaddingModifier())
                                        .tag(item)
                                }
                            }
                        }
                    }
                }
            } else {
                ProgressView()
            }
        }
        .navigationTitle("Diagnostic Reports")
        .toolbar {
            ToolbarItem(id: "diagnostic-reports-open", placement: .navigation) {
                BashOpenView(
                    path: .custom({ try await diagnosticReportsService.open() }),
                    type: .toolbarFolder
                )
            }
            ToolbarItem(id: "diagnostic-reports-refresh", placement: .navigation) {
                Button {
                    refreshToken = UUID()
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
            }
        }
        .task(id: refreshToken) {
            await reload()
        }
        .onDisappear {
            selectedItem = nil
        }
    }
    
    private func reload() async {
        reports = nil
        retiredReports = nil
        let (reportsTask, retiredTask) = await (
            diagnosticReportsService.reports(),
            diagnosticReportsService.retiredReports()
        )
        reports = reportsTask
        retiredReports = retiredTask
    }
}

#Preview {
    DiagnosticReportsListView(
        selectedItem: .constant(nil),
        refreshToken: .constant(UUID())
    )
    .frame(width: 420, height: 380)
    .withDiagnosticReportsService(DiagnosticReportsServiceMockImpl())
    .withAppMocks()
}

private final class DiagnosticReportsServiceMockImpl: DiagnosticReportsServiceMock {
    
    override func reports() async -> [DiagnosticReport] {
        [
            .init(
                name: "com.apple.dt.Xcode.crash",
                path: URL(fileURLWithPath: "/Users/demo/Library/Logs/DiagnosticReports/com.apple.dt.Xcode.crash"),
                createdAt: .now,
                source: .reports
            ),
            .init(
                name: "com.apple.CoreSimulator.SimDevice.very.long.long.long.long.file.name.crash",
                path: URL(fileURLWithPath: "/Users/demo/Library/Logs/DiagnosticReports/com.apple.CoreSimulator.SimDevice.very.long.long.long.long.file.name.crash"),
                createdAt: Date(timeIntervalSinceNow: -1200),
                source: .reports
            )
        ]
    }
    
    override func retiredReports() async -> [DiagnosticReport] {
        [
            .init(
                name: "com.apple.dt.Xcode_2025-01-01-004040.crash",
                path: URL(fileURLWithPath: "/Users/demo/Library/Logs/DiagnosticReports/Retired/com.apple.dt.Xcode_2025-01-01-004040.crash"),
                createdAt: Date(timeIntervalSinceNow: -86_400),
                source: .retired
            )
        ]
    }
}
