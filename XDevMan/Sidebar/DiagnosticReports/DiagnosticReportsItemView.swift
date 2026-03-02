import SwiftUI

struct DiagnosticReportsItemView: View {
    
    let item: DiagnosticReport
    @Binding var selectedItem: DiagnosticReport?
    @Binding var refreshToken: UUID
    @Environment(\.diagnosticReportsService) private var diagnosticReportsService
    @Environment(\.alertHandler) private var alertHandler
    @Environment(\.appLogger) private var appLogger
    @State private var content: String?
    @State private var isDeleting = false
    
    var body: some View {
        Group {
            if let content {
                GeometryReader { _ in
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Created:")
                                .fontWeight(.bold)
                            Text(item.createdAt.formatted(.dateTime.year().month().day().hour().minute().second()))
                                .textSelection(.enabled)
                        }
                        Text(item.name)
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .fixedSize(horizontal: false, vertical: true)
                        Divider()
                        TextEditor(text: .constant(content))
                            .font(.system(.body, design: .monospaced))
                    }
                    .padding()
                }
            } else {
                ProgressView()
            }
        }
        .toolbar {
            ToolbarItem(id: "diagnostic-reports-delete", placement: .destructiveAction) {
                if isDeleting {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Button {
                        Task {
                            do {
                                isDeleting = true
                                try await diagnosticReportsService.delete(item)
                                selectedItem = nil
                                refreshToken = UUID()
                            } catch {
                                isDeleting = false
                                alertHandler.handle(title: "Delete error for \(item.name)", message: nil, error: error)
                                appLogger.error(error)
                            }
                        }
                    } label: {
                        DeleteIconView()
                    }
                }
            }
        }
        .task(id: item) {
            do {
                content = try await diagnosticReportsService.content(item)
            } catch {
                content = nil
                alertHandler.handle(title: "Diagnostic report read error", message: nil, error: error)
                appLogger.error(error)
            }
        }
    }
}

#Preview {
    DiagnosticReportsItemView(
        item: .init(
            name: "com.apple.dt.Xcode.crash",
            path: URL(fileURLWithPath: "/Users/demo/Library/Logs/DiagnosticReports/com.apple.dt.Xcode.crash"),
            createdAt: .now,
            source: .reports
        ),
        selectedItem: .constant(nil),
        refreshToken: .constant(UUID())
    )
    .frame(width: 600, height: 420)
    .withDiagnosticReportsService(DiagnosticReportsServiceMockImpl())
    .withAppMocks()
}

private final class DiagnosticReportsServiceMockImpl: DiagnosticReportsServiceMock {
    
    override func content(_ item: DiagnosticReport) async throws -> String {
        """
        Process: Xcode [12345]
        Path: /Applications/Xcode.app/Contents/MacOS/Xcode
        Identifier: com.apple.dt.Xcode
        Version: 16.2
        
        Termination Reason: SIGNAL 9
        """
    }
}
