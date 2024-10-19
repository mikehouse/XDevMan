
import SwiftUI

struct RuntimeCreateNewSimulatorView: View {
    
    let runtime: Runtime
    let onCreate: (SupportedDeviceType, String) -> Void
    let onCancel: () -> Void
    @State private var simulatorName: String = ""
    @State private var selectedDevice: String
    
    init(runtime: Runtime, onCreate: @escaping (SupportedDeviceType, String) -> Void, onCancel: @escaping () -> Void) {
        self.runtime = runtime
        self.onCreate = onCreate
        self.onCancel = onCancel
        self.selectedDevice = runtime.supportedDeviceTypes[0].name
    }
    
    var body: some View {
        VStack {
            HStack {
                Text("Create a new Simulator for Runtime \(runtime.name):")
                Spacer()
            }
            .padding(.bottom, 4)
            Group {
                HStack {
                    Spacer()
                    VStack {
                        HStack {
                            Text("Simulator Name:")
                            TextField(selectedDevice, text: $simulatorName)
                            Spacer()
                        }
                        HStack {
                            Picker("Device Type: ", selection: $selectedDevice) {
                                ForEach(runtime.supportedDeviceTypes.map(\.name), id: \.self) { device in
                                    Text(device)
                                }
                            }
                            Spacer()
                        }
                    }
                    Spacer()
                }
            }
            .padding(32)
            .border(FillShapeStyle(), width: 1)
            HStack {
                Button("Cancel", action: onCancel)
                Spacer()
                Button("Create") {
                    if let device = runtime.supportedDeviceTypes.first(where: { $0.name == selectedDevice }) {
                        onCreate(device, simulatorName.isEmpty ? selectedDevice : simulatorName)
                    }
                }
            }
            .padding(.top, 12)
        }
        .padding()
        .frame(width: 600)
    }
}

#Preview {
    RuntimeCreateNewSimulatorView(runtime:  .init(
        bundlePath: "", buildversion: "20E247", platform: "", runtimeRoot: "",
        identifier: "com.apple.CoreSimulator.SimRuntime.iOS-16-4", version: "", isInternal: false, isAvailable: true,
        name: "iOS 16", supportedDeviceTypes: [
            .init(
                bundlePath: "",
                name: "iPhone 14",
                identifier: "com.apple.CoreSimulator.SimDeviceType.iPhone-14",
                productFamily: "iPhone"
            ),
            .init(
                bundlePath: "",
                name: "iPhone 15",
                identifier: "com.apple.CoreSimulator.SimDeviceType.iPhone-15",
                productFamily: "iPhone"
            )
        ]
    ), onCreate: { (_, _) in }, onCancel: { }
    )
    .withAppMocks()
}
