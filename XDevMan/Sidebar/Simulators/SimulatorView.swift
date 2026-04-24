
import SwiftUI

struct SimulatorView: View {
    
    let device: DeviceSim
    let runtime: Runtime
    @Binding var reloadSimulator: DeviceSim?
    @Binding var deleteSimulator: DeviceSim?
    @Environment(\.bashService) private var bashService
    @Environment(\.devicesService) private var devicesService
    @Environment(\.alertHandler) private var alertHandler
    @Environment(\.runtimesService) private var runtimesService
    @Environment(\.appLogger) private var appLogger
    @Environment(\.simulatorAppsService) private var simulatorAppsService
    @State private var buttonsDisabled = false
    @State private var buttonOpacity: Double = 1
    @State private var buttonAnimation = Animation.easeInOut(duration: 0.3).repeatForever(autoreverses: true)
    @State private var apps: [SimAppItem] = []
    @State private var selectedAppearance: SimulatorAppearance = .dark
    @State private var isApplyingAppearance = false
    @State private var fixedTime = Date()
    @State private var isApplyingFixedTime = false
    
    var body: some View {
        VStack {
            HStack(spacing: 10) {
                if !device.isAvailable {
                    Image(systemName: "xmark.circle")
                        .foregroundColor(.red)
                } else {
                    Image(systemName: "checkmark.circle")
                        .foregroundColor(.green)
                }
                Text(device.name).textSelection(.enabled)
                if device.isAvailable {
                    if device.state == "Shutdown" {
                        Button {
                            withAnimation(buttonAnimation) {
                                buttonOpacity = 0.5
                            }
                            Task {
                                do {
                                    self.buttonsDisabled = true
                                    try await bashService.open(.init(name: CliTool.simulatorApp()), args: ["--args", "-SessionOnLaunch", "NO"])
                                    try await devicesService.boot(device)
                                    self.buttonOpacity = 1
                                    self.reloadSimulator = device
                                    self.buttonsDisabled = false
                                } catch {
                                    self.alertHandler.handle(title: "Booting error for \(device.name)", message: nil, error: error)
                                    self.buttonsDisabled = false
                                    self.buttonOpacity = 1
                                    self.appLogger.error(error)
                                }
                            }
                        } label: {
                            VStack {
                                Image(systemName: "power.circle.fill")
                                    .resizable()
                                    .frame(width: 20, height: 20)
                                    .foregroundStyle(.green)
                            }
                            .opacity(buttonOpacity)
                        }
                        .buttonStyle(BorderlessButtonStyle())
                        .disabled(buttonsDisabled)
                        
                    } else if device.state == "Booted" {
                        Button {
                            withAnimation(buttonAnimation) {
                                buttonOpacity = 0.5
                            }
                            Task {
                                do {
                                    self.buttonsDisabled = true
                                    try await devicesService.shutdown(device)
                                    self.buttonOpacity = 1
                                    self.reloadSimulator = device
                                    self.buttonsDisabled = false
                                } catch {
                                    self.alertHandler.handle(title: "Shutdown error for \(device.name)", message: nil, error: error)
                                    self.buttonsDisabled = false
                                    self.buttonOpacity = 1
                                    self.appLogger.error(error)
                                }
                            }
                        } label: {
                            VStack {
                                Image(systemName: "power.circle")
                                    .resizable()
                                    .frame(width: 20, height: 20)
                                    .foregroundStyle(.yellow)
                            }
                            .opacity(buttonOpacity)
                        }
                        .buttonStyle(BorderlessButtonStyle())
                        .disabled(buttonsDisabled)
                        if let lastBootedAt = device.lastBootedAt,
                            let date = ISO8601DateFormatter().date(from: lastBootedAt) {
                            Text(relativeDateFormatter.localizedString(for: date, relativeTo: Date()))
                        }
                    }
                }
                Spacer()
                if device.state != "Booted" {
                    Button {
                        Task {
                            do {
                                self.buttonsDisabled = true
                                try await devicesService.delete(device)
                                self.deleteSimulator = device
                            } catch {
                                self.alertHandler.handle(title: "Delete error for \(device.name)", message: nil, error: error)
                                self.buttonsDisabled = false
                                self.appLogger.error(error)
                            }
                        }
                    } label: {
                        if self.buttonsDisabled {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            DeleteIconView()
                        }
                    }
                    .buttonStyle(BorderlessButtonStyle())
                    .disabled(buttonsDisabled)
                    Button {
                        Task {
                            do {
                                self.buttonsDisabled = true
                                try await devicesService.erase(device)
                                self.reloadSimulator = device
                                self.buttonsDisabled = false
                            } catch {
                                self.alertHandler.handle(title: "Erase error for \(device.name)", message: nil, error: error)
                                self.buttonsDisabled = false
                                self.appLogger.error(error)
                            }
                        }
                    } label: {
                        VStack {
                            Image(systemName: "eraser.line.dashed")
                                .resizable()
                                .frame(width: 25, height: 22)
                                .foregroundStyle(.teal)
                        }
                    }
                    .buttonStyle(BorderlessButtonStyle())
                    .disabled(buttonsDisabled)
                }
            }
            HStack {
                Text("UDID:")
                Text(device.udid).textSelection(.enabled)
                PasteboardCopyView(text: device.udid)
                Spacer()
            }
            if let deviceTypeIdentifier = device.deviceTypeIdentifier,
                let deviceType = deviceTypeIdentifier.components(separatedBy: ".").last.flatMap({ $0.replacingOccurrences(of: "-", with: " ") }) {
                HStack {
                    Text("Type:")
                    Text(deviceType).textSelection(.enabled)
                    Spacer()
                }
            }
            HStack {
                ByteSizeView(title: "Data", size: device.dataPathSize)
                BashOpenView(path: .url(URL(filePath: device.dataPath)), type: .folder)
                Spacer()
            }
            if runtime.platform != "tvOS" {
                HStack {
                    Picker("Appearance:", selection: $selectedAppearance) {
                        ForEach(SimulatorAppearance.allCases) { appearance in
                            Text(appearance.rawValue).tag(appearance)
                        }
                    }
                    .fixedSize(horizontal: true, vertical: false)
                    Button("Apply") {
                        Task {
                            await applyAppearance()
                        }
                    }
                    Spacer()
                }
                .disabled(device.state != "Booted" || buttonsDisabled || isApplyingAppearance)
                HStack {
                    Text("Status Bar Time")
                    DatePicker("", selection: $fixedTime, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                        .fixedSize(horizontal: true, vertical: false)
                    Button("Apply") {
                        Task {
                            await applyFixedTime()
                        }
                    }
                    Button("Reset") {
                        Task {
                            await resetFixedTime()
                        }
                    }
                    Spacer()
                }
                .disabled(device.state != "Booted" || buttonsDisabled || isApplyingFixedTime)
            }
            if !apps.isEmpty {
                Spacer(minLength: 12)
                SimulatorAppsListView(device: device, items: apps) {
                    await reloadApps()
                }
            }
        }
        .task(id: device) {
            await reloadApps()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.willBecomeActiveNotification)) { _ in
            Task {
                await reloadApps()
            }
        }
    }
    
    private func reloadApps() async {
        apps = await simulatorAppsService.apps(for: device)
    }
    
    private func applyAppearance() async {
        isApplyingAppearance = true
        defer {
            isApplyingAppearance = false
        }
        do {
            try await devicesService.setAppearance(selectedAppearance, for: device)
        } catch {
            appLogger.error("Apply simulator UI theme error for \(device.name): \(error)")
        }
    }
    
    private func applyFixedTime() async {
        isApplyingFixedTime = true
        defer {
            isApplyingFixedTime = false
        }
        do {
            try await devicesService.setFixedTime(fixedTime, for: device)
        } catch {
            appLogger.error("Apply simulator fixed time error for \(device.name): \(error)")
        }
    }
    
    private func resetFixedTime() async {
        isApplyingFixedTime = true
        defer {
            isApplyingFixedTime = false
        }
        do {
            try await devicesService.resetFixedTime(for: device)
        } catch {
            appLogger.error("Reset simulator fixed time error for \(device.name): \(error)")
        }
    }
}

private let relativeDateFormatter: RelativeDateTimeFormatter = {
    let formatter = RelativeDateTimeFormatter()
    formatter.unitsStyle = .short
    return formatter
}()


#Preview {
    SimulatorView(
        device: .init(
            lastBootedAt: nil,
            dataPath: "/",
            dataPathSize: 1234566771,
            logPath: "/",
            udid: "C17547A2-F6BB-4AC2-9B2D-BCE8F958352C",
            isAvailable: true,
            availabilityError: nil,
            logPathSize: nil,
            deviceTypeIdentifier: "com.apple.CoreSimulator.SimDeviceType.iPhone-15",
            state: "Shutdown",
            name: "iPhone 15"
        ),
        runtime: .init(
            bundlePath: "",
            buildversion: "",
            platform: "",
            runtimeRoot: "",
            identifier: "",
            version: "",
            isInternal: false,
            isAvailable: true,
            name: "iOS 15",
            supportedDeviceTypes: []
        ),
        reloadSimulator: .constant(nil),
        deleteSimulator: .constant(nil)
    )
    .padding()
    .frame(width: 500)
    .withAppMocks()
}
