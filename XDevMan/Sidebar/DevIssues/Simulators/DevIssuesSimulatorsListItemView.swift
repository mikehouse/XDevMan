
import SwiftUI

struct DevIssuesSimulatorsListItemView: View {
    
    let device: DeviceSim
    let isPreview: Bool
    @Binding var deletedDevice: DeviceSim?
    @Environment(\.devicesService) private var devicesService
    @Environment(\.alertHandler) private var alertHandler
    @Environment(\.bashService) private var bashService
    @Environment(\.appLogger) private var appLogger
    @State private var isDeleting = false
    
    var body: some View {
        VStack {
            HStack {
                Text(device.name)
                    .textSelection(.enabled)
                Spacer()
                if isDeleting {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Button {
                        Task {
                            do {
                                isDeleting = true
                                CliTool.SimCtl.setPreviewsMode(isPreview)
                                try await devicesService.delete(device)
                                deletedDevice = device
                            } catch {
                                alertHandler.handle(title: "Delete error for \(device.name)", message: nil, error: error)
                                isDeleting = false
                                appLogger.error(error)
                            }
                        }
                    } label: {
                        DeleteIconView()
                    }
                    .buttonStyle(BorderlessButtonStyle())
                }
            }
            HStack {
                Text("Error:")
                Text(device.availabilityError ?? "Unknown.")
                    .foregroundStyle(.orange)
                    .textSelection(.enabled)
                if device.availabilityError == "device type profile not found" {
                    Text("(Use new Xcode version)")
                        .foregroundStyle(.green)
                }
                Spacer()
            }
            HStack {
                Text("UDID: \(device.udid)")
                    .textSelection(.enabled)
                PasteboardCopyView(text: device.udid)
                Spacer()
            }
            HStack {
                ByteSizeView(title: "Data", size: device.dataPathSize)
                BashOpenView(path: .url(URL(filePath: device.dataPath)), type: .folder)
                Spacer()
            }
            Spacer()
        }
    }
}

#Preview {
    VStack {
        DevIssuesSimulatorsListItemView(
            device: .init(
                lastBootedAt: nil,
                dataPath: "/",
                dataPathSize: 1234566771,
                logPath: "/",
                udid: "C17547A2-F6BB-4AC2-9B2D-BCE8F958352C",
                isAvailable: false,
                availabilityError: "runtime profile not found using \"System\" match policy",
                logPathSize: nil,
                deviceTypeIdentifier: "com.apple.CoreSimulator.SimDeviceType.iPhone-15",
                state: "Shutdown",
                name: "iPhone 15"
            ), isPreview: false, deletedDevice: .constant(nil)
        )
        DevIssuesSimulatorsListItemView(
            device: .init(
                lastBootedAt: nil,
                dataPath: "/",
                dataPathSize: 1234566771,
                logPath: "/",
                udid: "C17547A2-F6BB-4AC2-9B2D-BCE8F958352AA",
                isAvailable: true,
                availabilityError: "device type profile not found",
                logPathSize: nil,
                deviceTypeIdentifier: "com.apple.CoreSimulator.SimDeviceType.iPhone-16",
                state: "Shutdown",
                name: "iPhone 16"
            ), isPreview: false, deletedDevice: .constant(nil)
        )
    }
    .padding()
    .frame(width: 500, height: 300)
    .withAppMocks()
}
