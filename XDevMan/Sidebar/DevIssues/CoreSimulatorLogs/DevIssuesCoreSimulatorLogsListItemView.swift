
import SwiftUI

struct DevIssuesCoreSimulatorLogsListItemView: View {
    
    let logItem: LogItem
    @Binding var deletedLogItem: LogItem?
    @Environment(\.coreSimulatorLogsService) private var coreSimulatorLogsService
    @Environment(\.alertHandler) private var alertHandler
    @Environment(\.bashService) private var bashService
    @Environment(\.appLogger) private var appLogger
    @State private var size: String?
    @State private var isDeleting = false
    
    var body: some View {
        HStack(spacing: 10) {
            Text(logItem.udid)
                .textSelection(.enabled)
            Spacer()
            StringSizeView(sizeProvider: {
                try await bashService.size(logItem.path)
            }, size: $size)
            if isDeleting {
                ProgressView()
                    .controlSize(.small)
            } else {
                Button {
                    Task {
                        do {
                            isDeleting = true
                            try await coreSimulatorLogsService.delete(logItem)
                            deletedLogItem = logItem
                        } catch {
                            alertHandler.handle(title: "Delete error for \(logItem.udid)", message: nil, error: error)
                            isDeleting = false
                            appLogger.error(error)
                        }
                    }
                } label: {
                    DeleteIconView()
                }
                .buttonStyle(BorderlessButtonStyle())
            }
            BashOpenView(path: .url(logItem.path), type: .folder)
        }
        .task(id: logItem) {
        }
    }
    
    typealias LogItem = CoreSimulatorLogs.LogItem
}

#Preview {
    DevIssuesCoreSimulatorLogsListItemView(
        logItem: .init(
            udid: "0A1D4C81-8626-4ECD-975C-FF47681ADB10",
            path: URL(fileURLWithPath: "/")),
        deletedLogItem: .constant(nil)
    )
    .padding()
    .frame(width: 500, height: 100)
    .withAppMocks()
}
