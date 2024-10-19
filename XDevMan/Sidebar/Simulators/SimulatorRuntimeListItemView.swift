
import SwiftUI

struct SimulatorRuntimeListItemView: View {
    
    let runtime: Runtime
    let isBeta: Bool
    let size: Int?
    
    var body: some View {
        HStack {
            if !runtime.isAvailable {
                Image(systemName: "xmark.circle")
                    .foregroundColor(.red)
            } else {
                Image(systemName: "checkmark.circle")
                    .foregroundColor(.green)
            }
            HStack {
                if isBeta {
                    Text("\(runtime.name) beta (\(runtime.buildversion)) ")
                        .textSelection(.enabled)
                } else {
                    Text("\(runtime.name) (\(runtime.buildversion)) ")
                        .textSelection(.enabled)
                }
                Spacer()
                if let size {
                    ByteSizeView(title: nil, size: size)
                }
            }
        }
    }
}

#Preview {
    SimulatorRuntimeListItemView(
        runtime: .init(
            bundlePath: "",
            buildversion: "20E247",
            platform: "",
            runtimeRoot: "",
            identifier: "com.apple.CoreSimulator.SimRuntime.iOS-16-4",
            version: "",
            isInternal: false,
            isAvailable: true,
            name: "iOS 16",
            supportedDeviceTypes: []
        ),
        isBeta: false,
        size: 10202290
    )
    .padding()
    .frame(width: 300)
    .withAppMocks()
}
