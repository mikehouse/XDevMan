
import SwiftUI

struct SimulatorListView: View {
    
    let runtime: Runtime
    @Binding var reloadSimulators: UUID?
    @Environment(\.devicesService) private var devicesService
    @Environment(\.bashService) private var bashService
    @Environment(\.runtimesService) private var runtimesService
    @Environment(\.alertHandler) private var alertHandler
    @Environment(\.appLogger) private var appLogger
    @State private var reloadSimulator: DeviceSim?
    @State private var deleteSimulator: DeviceSim?
    @State private var devices: [DeviceSim]?
    @State private var dyldSize: String?
    @State private var size = 0
    @State private var hasNewDevicesThanXcodeSelected = false
    
    var body: some View {
        Group {
            if let devices {
                HStack {
                    VStack(spacing: 8) {
                        if hasNewDevicesThanXcodeSelected {
                            HStack {
                                Text("Detected Simulators not supported by current Xcode.")
                                    .foregroundStyle(.yellow)
                                Spacer()
                            }
                        }
                        HStack {
                            ByteSizeView(
                                title: "Simulators Data",
                                size: size
                            )
                            if let dyldSize {
                                HStack {
                                    Text("Dyld Cache:")
                                    Text(dyldSize)
                                }
                            }
                            Spacer()
                        }
                        List(devices) { device in
                            SimulatorView(
                                device: device,
                                runtime: runtime,
                                reloadSimulator: $reloadSimulator,
                                deleteSimulator: $deleteSimulator
                            )
                            .padding([.bottom], 10)
                            .padding([.top], device == devices[0] ? 2 : 10)
                        }
                        Spacer()
                    }
                    Spacer()
                }
                .padding()
            } else {
                ProgressView()
            }
        }
        .task(id: runtime) {
            await reloadSimulators()
        }
        .task(id: runtime) {
            dyldSize = nil
            do {
                if let cacheURL = try await runtimesService.dyldCache(runtime) {
                    dyldSize = try await bashService.size(cacheURL)
                }
            } catch {
                appLogger.error(error)
            }
        }
        .onChange(of: deleteSimulator) {
            guard deleteSimulator != nil else {
                return
            }
            Task {
                await reloadSimulators()
            }
        }
        .onChange(of: reloadSimulators) {
            guard reloadSimulators != nil else {
                return
            }
            Task {
                await reloadSimulators()
            }
        }
        .onChange(of: reloadSimulator) {
            guard reloadSimulator != nil else {
                return
            }
            Task { await reloadSimulators() }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.willBecomeActiveNotification)) { _ in
            Task { await reloadSimulators() }
        }
    }
    
    private func reloadSimulators() async {
        do {
            let devices = (try await devicesService.devices().devices[runtime.identifier] ?? [])
            self.hasNewDevicesThanXcodeSelected = devices
                .contains(where: { $0.availabilityError == "device type profile not found" })
            self.size = devices.map({ $0.dataPathSize }).reduce(0, +)
            self.devices = devices.filter({ $0.isAvailable && $0.availabilityError == nil })
        } catch {
            alertHandler.handle(title: "Reload simulators error", message: nil, error: error)
            appLogger.error(error)
        }
    }
}

#Preview {
    SimulatorListView(
        runtime: .init(
            bundlePath: "/Library/Developer/CoreSimulator/Volumes/iOS_20E247/Library/Developer/CoreSimulator/Profiles/Runtimes/iOS 16.4.simruntime",
            buildversion: "20E247",
            platform: "iOS",
            runtimeRoot: "/Library/Developer/CoreSimulator/Volumes/iOS_20E247/Library/Developer/CoreSimulator/Profiles/Runtimes/iOS 16.4.simruntime/Contents/Resources/RuntimeRoot",
            identifier: "com.apple.CoreSimulator.SimRuntime.iOS-16-4",
            version: "16.4",
            isInternal: false,
            isAvailable: true,
            name: "iOS 16.4",
            supportedDeviceTypes: [
                .init(
                    bundlePath: "/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Library/Developer/CoreSimulator/Profiles/DeviceTypes/iPhone 8.simdevicetype",
                    name: "iPhone 8",
                    identifier: "com.apple.CoreSimulator.SimDeviceType.iPhone-8",
                    productFamily: "iPhone"
                )
            ]
        ),
        reloadSimulators: .constant(nil)
    )
    .frame(width: 550, height: 500)
    .withDevicesService(DevicesProviderMockObject.self)
    .withAppMocks()
}

private class DevicesProviderMockObject: DevicesProviderMock {
    
    override class func devices() async throws -> CliTool.SimCtl.List.Devices {
        return .init(devices: [
            "com.apple.CoreSimulator.SimRuntime.iOS-16-4": [
                CliTool.SimCtl.List.Devices.Device(
                    lastBootedAt: "2024-06-27T04:11:14Z",
                    dataPath: "/Users/mikhaildemidov/Library/Developer/CoreSimulator/Devices/11D70F23-84DB-4613-8721-DA42D19A03D3/data",
                    dataPathSize: 595816448,
                    logPath: "/Users/mikhaildemidov/Library/Logs/CoreSimulator/11D70F23-84DB-4613-8721-DA42D19A03D3",
                    udid: "11D70F23-84DB-4613-8721-DA42D19A03D3",
                    isAvailable: true,
                    availabilityError: nil,
                    logPathSize: 479232,
                    deviceTypeIdentifier: "com.apple.CoreSimulator.SimDeviceType.Apple-TV-4K-3rd-generation-1080p",
                    state: "Shutdown",
                    name: "Apple TV 4K (3rd generation) (at 1080p)"
                ),
                CliTool.SimCtl.List.Devices.Device(
                    lastBootedAt: "2024-06-10T08:14:15Z",
                    dataPath: "/Users/mikhaildemidov/Library/Developer/CoreSimulator/Devices/C17547A2-F6BB-4AC2-9B2D-BCE8F958352C/data",
                    dataPathSize: 595816448,
                    logPath: "/Users/mikhaildemidov/Library/Logs/CoreSimulator/C17547A2-F6BB-4AC2-9B2D-BCE8F958352C",
                    udid: "C17547A2-F6BB-4AC2-9B2D-BCE8F958352C",
                    isAvailable: false, 
                    availabilityError: "runtime profile not found using \"System\" match policy",
                    logPathSize: 479232,
                    deviceTypeIdentifier: "com.apple.CoreSimulator.SimDeviceType.iPhone-15",
                    state: "Shutdown",
                    name: "iPhone 15"
                ),
                CliTool.SimCtl.List.Devices.Device(
                    lastBootedAt: "2024-06-10T08:14:15Z",
                    dataPath: "/Users/mikhaildemidov/Library/Developer/CoreSimulator/Devices/C17547A2-F6BB-4AC2-9B2D-BCE8F9583522/data",
                    dataPathSize: 595816448,
                    logPath: "/Users/mikhaildemidov/Library/Logs/CoreSimulator/C17547A2-F6BB-4AC2-9B2D-BCE8F9583522",
                    udid: "C17547A2-F6BB-4AC2-9B2D-BCE8F9583522",
                    isAvailable: true,
                    availabilityError: "device type profile not found",
                    logPathSize: 479232,
                    deviceTypeIdentifier: "com.apple.CoreSimulator.SimDeviceType.iPhone-16",
                    state: "Shutdown",
                    name: "iPhone 16"
                )
            ]
        ]
        )
    }
}
