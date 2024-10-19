
import SwiftUI

struct IBSupportItemView: View {
    
    let item: IBSupportItem
    @Binding var deletedIBSupportItem: IBSupportItem?
    @Environment(\.ibSupportService) private var ibSupportService
    @Environment(\.bashService) private var bashService
    @Environment(\.alertHandler) private var alertHandler
    @Environment(\.appLogger) private var appLogger
    @State private var size: String?
    @State private var isDeleting = false
    
    var body: some View {
        Group {
            HStack {
                Text(name())
                    .textSelection(.enabled)
                    .lineLimit(1)
                Spacer()
                HStack(spacing: 16) {
                    StringSizeView(sizeProvider: {
                        try await ibSupportService.size(item)
                    }, size: $size)
                    if isDeleting {
                        ProgressView()
                            .controlSize(.mini)
                    } else {
                        Button {
                            Task {
                                do {
                                    isDeleting = true
                                    try await ibSupportService.delete(item)
                                    deletedIBSupportItem = item
                                } catch {
                                    isDeleting = false
                                    alertHandler.handle(title: "Delete error for \(item.name)", message: nil, error: error)
                                    appLogger.error(error)
                                }
                            }
                        } label: {
                            DeleteIconView()
                        }
                        .buttonStyle(BorderlessButtonStyle())
                    }
                    BashOpenView(
                        path: .custom({ try await ibSupportService.open(item) }),
                        type: .folder
                    )
                }
            }
        }
        .task(id: item) {
        }
    }
    
    func name() -> String {
        guard let runtime = item.runtime.components(separatedBy: ".").last else {
            return item.deviceType.components(separatedBy: ".").last ?? item.name
        }
        let parts = runtime.components(separatedBy: "-")
        let name = item.name.hasPrefix("IB")
            ? item.deviceType.components(separatedBy: ".").last ?? item.name : item.name
        return "\(name) (\(parts[0]) \(parts.dropFirst().joined(separator: ".")))"
    }
}

#Preview {
    IBSupportItemView(
        item: .init(
            name: "IBSimDeviceTypeiPad2x",
            path: URL(fileURLWithPath: "/"),
            udid: "C17547A2-F6BB-4AC2-9B2D-BCE8F958352C",
            runtime: "com.apple.CoreSimulator.SimRuntime.iOS-16-4",
            deviceType: "com.apple.dt.Xcode.IBSimDeviceType.iPad-2x"
        ),
        deletedIBSupportItem: .constant(nil)
    )
    .padding()
    .frame(width: 340)
    .withAppMocks()
}
