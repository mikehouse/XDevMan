
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
    @State private var buttonsDisabled = false
    @State private var buttonOpacity: Double = 1
    @State private var buttonAnimation = Animation.easeInOut(duration: 0.3).repeatForever(autoreverses: true)
    
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
                                self.buttonsDisabled = false
                            } catch {
                                self.alertHandler.handle(title: "Delete error for \(device.name)", message: nil, error: error)
                                self.buttonsDisabled = false
                                self.appLogger.error(error)
                            }
                        }
                    } label: {
                        DeleteIconView()
                    }
                    .buttonStyle(BorderlessButtonStyle())
                    .disabled(buttonsDisabled)
                    Button {
                        Task {
                            do {
                                self.buttonsDisabled = true
                                try await devicesService.delete(device)
                                try await runtimesService.create(device, runtime: runtime, name: nil)
                                self.deleteSimulator = device
                                self.buttonsDisabled = false
                            } catch {
                                self.alertHandler.handle(title: "Delete error for \(device.name)", message: nil, error: error)
                                self.buttonsDisabled = false
                                self.appLogger.error(error)
                            }
                        }
                    } label: {
                        VStack {
                            Image(systemName: "arrow.clockwise.circle")
                                .resizable()
                                .frame(width: 20, height: 20)
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
            HStack {
                ByteSizeView(title: "Data", size: device.dataPathSize)
                BashOpenView(path: .url(URL(filePath: device.dataPath)), type: .folder)
                Spacer()
            }
        }
    }
}

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
