
import SwiftUI

struct DevIssuesCoreSimulatorLogsListView: View {
    
    @Environment(\.coreSimulatorLogsService) private var coreSimulatorLogsService
    @Environment(\.devicesService) private var devicesService
    @Environment(\.alertHandler) private var alertHandler
    @Environment(\.appLogger) private var appLogger
    @State private var logItems: [LogItem]?
    @State private var deletedLogItem: LogItem?
    
    var body: some View {
        Group {
            if let logItems {
                if logItems.isEmpty {
                    NothingView(text: "No missed logs found. All looks good.")
                } else {
                    HStack(alignment: .center) {
                        Text("Logs data found for not existed or missed simulators")
                            .foregroundStyle(.orange)
                    }
                    .padding()
                    List(logItems) { log in
                        DevIssuesCoreSimulatorLogsListItemView(
                            logItem: log,
                            deletedLogItem: $deletedLogItem
                        )
                        .modifier(ListItemViewPaddingModifier())
                    }
                }
            } else {
                ProgressView()
                    .task {
                        await reloadLogItems()
                    }
            }
        }
        .toolbar {
            ToolbarItem(id: "core-simaltors-open") {
                BashOpenView(
                    path: .custom({ await coreSimulatorLogsService.open() }),
                    type: .toolbarFolder
                )
            }
        }
        .onChange(of: deletedLogItem) {
            if deletedLogItem != nil {
                Task { await reloadLogItems() }
            }
        }
    }
    
    private func reloadLogItems() async {
        do {
            let devices = try await devicesService.devices().devices.flatMap({ $0.value }).map({ $0.udid })
            logItems = await coreSimulatorLogsService.logs().filter({ !devices.contains($0.udid) })
        } catch {
            logItems = []
            alertHandler.handle(title: "Error", message: nil, error: error)
            appLogger.error(error)
        }
    }
    
    typealias LogItem = CoreSimulatorLogs.LogItem
}

#Preview {
    DevIssuesCoreSimulatorLogsListView()
        .padding()
        .frame(width: 500, height: 300)
        .withDevicesService(DevicesProviderMockImpl.self)
        .withCoreSimulatorLogsService(CoreSimulatorLogsServiceMock())
        .withAppMocks()
}

private final class CoreSimulatorLogsServiceMock: CoreSimulatorLogs.ServiceMock {
    
    override func logs() async -> [CoreSimulatorLogs.LogItem] {
        [
            .init(udid: "0A1D4C81-8626-4ECD-975C-FF47681ADB10", path: URL(fileURLWithPath: "/")),
            .init(udid: "0A8CE0CD-8B72-48A6-A7C8-F17927D1F41C", path: URL(fileURLWithPath: "/")),
            .init(udid: "0A759CFF-3CDF-4F15-85EA-FAE5649B1562", path: URL(fileURLWithPath: "/")),
            .init(udid: "00A994E5-A32B-432C-83B1-2920CB8DEE03", path: URL(fileURLWithPath: "/")),
        ]
    }
}

private final class DevicesProviderMockImpl: DevicesProviderMock {
    
    override class func devices() async throws -> CliTool.SimCtl.List.Devices {
        .init(devices: [
            "": [
                .init(
                    lastBootedAt: nil,
                    dataPath: "/",
                    dataPathSize: 0,
                    logPath: "/",
                    udid: "0A1D4C81-8626-4ECD-975C-FF47681ADB10",
                    isAvailable: true,
                    availabilityError: nil,
                    logPathSize: nil,
                    deviceTypeIdentifier: "",
                    state: "",
                    name: ""
                )
            ]
        ])
    }
}
