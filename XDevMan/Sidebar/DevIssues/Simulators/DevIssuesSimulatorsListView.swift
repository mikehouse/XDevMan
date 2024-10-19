
import SwiftUI

struct DevIssuesSimulatorsListView: View {
    
    @Environment(\.devicesService) private var devicesService
    @Environment(\.runtimesService) private var runtimesService
    @Environment(\.alertHandler) private var alertHandler
    @Environment(\.appLogger) private var appLogger
    @State private var errorDevices: [Item]?
    @State private var deletedDevice: DeviceSim?
    
    var body: some View {
        Group {
            if let errorDevices {
                if errorDevices.isEmpty {
                    NothingView(text: "No issues found.")
                } else {
                    Text("Unavailable simulators found.")
                        .padding()
                        .foregroundStyle(.orange)
                    List(errorDevices) { devices in
                        Section(content: {
                            ForEach(devices.devices) { device in
                                DevIssuesSimulatorsListItemView(
                                    device: device,
                                    deletedDevice: $deletedDevice
                                )
                                .modifier(ListItemViewPaddingModifier())
                            }
                        }, header: {
                            Text(devices.runtime)
                                .foregroundStyle(.cyan)
                        })
                    }
                }
            } else {
                ProgressView()
                    .task {
                        await reloadSims()
                    }
            }
        }
        .onChange(of: deletedDevice) {
            if deletedDevice != nil {
                Task { await reloadSims() }
            }
        }
        .toolbar {
            ToolbarItem(id: "xcode-import") {
                XCodeImporter {
                    if $0 {
                        Task { await reloadSims() }
                    }
                }
            }
        }
    }
    
    private func reloadSims() async {
        do {
            errorDevices = try await Task<[Item], Error>.detached {
                let devices = try await devicesService.devices().devices
                let errored = devices.filter({ !$0.value.filter({ !$0.isAvailable || $0.availabilityError != nil }).isEmpty })
                let runtimes = try await runtimesService.runtimes().runtimes
                return errored.compactMap({ t in
                    if let runtime = runtimes.first(where: { $0.identifier == t.key }) {
                        return Item(runtime: "\(runtime.name) (\(runtime.buildversion))", devices: t.value)
                    } else {
                        let last = t.key.components(separatedBy: ".").last ?? ""
                        let chunks = last.components(separatedBy: "-")
                        let platform = chunks[0]
                        let version = chunks.dropFirst().joined(separator: ".")
                        return Item(runtime: "\(platform) \(version)", devices: t.value)
                    }
                })
            }.value
        } catch {
            alertHandler.handle(title: "Read Error", message: nil, error: error)
            appLogger.error(error)
        }
    }
    
    private struct Item: HashableIdentifiable {
        
        var id: String { "\(runtime)+\(devices.count)" }
        
        let runtime: String
        let devices: [DeviceSim]
    }
}

#Preview {
    DevIssuesSimulatorsListView()
        .padding()
        .frame(width: 500, height: 300)
        .withDevicesService(DevicesProviderMockObject.self)
        .withRuntimesService(RuntimesProviderMockObject.self)
        .withAppMocks()
}

private class DevicesProviderMockObject: DevicesProviderMock {
    
    override class func devices() async throws -> CliTool.SimCtl.List.Devices {
        return .init(devices: [
            "com.apple.CoreSimulator.SimRuntime.iOS-18-0": [
                CliTool.SimCtl.List.Devices.Device(
                    lastBootedAt: nil,
                    dataPath: "/Users/mikhaildemidov/Library/Developer/CoreSimulator/Devices/2A34E43F-1C28-441C-B4C2-7582569C7C7D/data",
                    dataPathSize: 18337792,
                    logPath: "/Users/mikhaildemidov/Library/Logs/CoreSimulator/2A34E43F-1C28-441C-B4C2-7582569C7C7D",
                    udid: "2A34E43F-1C28-441C-B4C2-7582569C7C7D",
                    isAvailable: false,
                    availabilityError: "runtime profile not found using \"System\" match policy",
                    logPathSize: nil,
                    deviceTypeIdentifier: "com.apple.CoreSimulator.SimDeviceType.iPhone-15",
                    state: "Shutdown",
                    name: "iPhone 15"
                ),
                CliTool.SimCtl.List.Devices.Device(
                    lastBootedAt: "2024-08-14T10:00:18Z",
                    dataPath: "/Users/mikhaildemidov/Library/Developer/CoreSimulator/Devices/E646186B-8C73-4481-A6D4-2694A509C3AC/data",
                    dataPathSize: 435945472,
                    logPath: "/Users/mikhaildemidov/Library/Logs/CoreSimulator/E646186B-8C73-4481-A6D4-2694A509C3AC",
                    udid: "E646186B-8C73-4481-A6D4-2694A509C3AC",
                    isAvailable: true,
                    availabilityError: "runtime profile not found using \"System\" match policy",
                    logPathSize: 77824,
                    deviceTypeIdentifier: "com.apple.CoreSimulator.SimDeviceType.iPhone-15-Pro",
                    state: "Shutdown",
                    name: "iPhone 15 Pro"
                )
            ],
            "com.apple.CoreSimulator.SimRuntime.iOS-15-5": [
                CliTool.SimCtl.List.Devices.Device(
                    lastBootedAt: "2024-04-10T06:22:46Z",
                    dataPath: "/Users/mikhaildemidov/Library/Developer/CoreSimulator/Devices/14562998-CA7F-495F-AD95-CCAA21B055A5/data",
                    dataPathSize: 518995968,
                    logPath: "/Users/mikhaildemidov/Library/Logs/CoreSimulator/14562998-CA7F-495F-AD95-CCAA21B055A5",
                    udid: "14562998-CA7F-495F-AD95-CCAA21B055A5",
                    isAvailable: false,
                    availabilityError: "runtime profile not found using \"System\" match policy",
                    logPathSize: 921600,
                    deviceTypeIdentifier: "com.apple.CoreSimulator.SimDeviceType.iPhone-X",
                    state: "Shutdown",
                    name: "iPhone X"
                )
            ]
        ]
        )
    }
}

private class RuntimesProviderMockObject: RuntimesProviderMock {
    
    override class func runtimes() async throws -> CliTool.SimCtl.List.Runtimes {
        return .init(
            runtimes: [
                .init(
                    bundlePath: "", buildversion: "20E247", platform: "", runtimeRoot: "",
                    identifier: "com.apple.CoreSimulator.SimRuntime.iOS-18-0", version: "", isInternal: false, isAvailable: true,
                    name: "iOS 18.0", supportedDeviceTypes: [
                    ]
                ),
                .init(
                    bundlePath: "", buildversion: "21F79", platform: "", runtimeRoot: "",
                    identifier: "com.apple.CoreSimulator.SimRuntime.iOS-14-5", version: "", isInternal: false, isAvailable: true,
                    name: "iOS 14", supportedDeviceTypes: [
                    ]
                )
            ]
        )
    }
}
