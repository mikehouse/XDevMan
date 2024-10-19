
import SwiftUI

struct DeviceSupportListItemView: View {
    
    let osItem: DeviceSupportOsItem
    @Binding var deletedDeviceSupportOsItem: DeviceSupportOsItem?
    @State private var deleteDeviceSupportAlertShown = false
    @State private var size: String?
    @State private var isDeleting = false
    @Environment(\.alertHandler) private var alertHandler
    @Environment(\.bashService) private var bashService
    @Environment(\.appLogger) private var appLogger
    
    var body: some View {
        Group {
            HStack {
                Text(osItem.displayName ?? osItem.name)
                    .textSelection(.enabled)
                    .lineLimit(1)
                Spacer()
                HStack(spacing: 16) {
                    StringSizeView(sizeProvider: {
                        try await bashService.size(osItem.path)
                    }, size: $size)
                    if isDeleting {
                        ProgressView()
                            .controlSize(.mini)
                    } else {
                        Button {
                            deleteDeviceSupportAlertShown = true
                        } label: {
                            DeleteIconView()
                        }
                        .buttonStyle(BorderlessButtonStyle())
                    }
                    BashOpenView(path: .url(osItem.path), type: .folder)
                }
            }
        }
        .alert((Text("Delete Device Symbols ?")), isPresented: $deleteDeviceSupportAlertShown) {
            Button("Cancel", role: .cancel, action: {})
            Button("Delete", role: .destructive, action: {
                Task {
                    do {
                        isDeleting = true
                        try await bashService.rmDir(osItem.path)
                        deletedDeviceSupportOsItem = osItem
                    } catch {
                        isDeleting = false
                        appLogger.error(error)
                        alertHandler.handle(title: "Delete error for \(osItem.name)", message: nil, error: error)
                    }
                }
            })
        } message: {
            Text("Symbols for \(osItem.displayName ?? osItem.name) ?")
        }
        .task(id: osItem) {
        }
    }
}

#Preview {
    DeviceSupportListItemView(
        osItem: .init(
            name: "iPhone15,3 17.5.1 (21F90)",
            path: URL(fileURLWithPath: "/")
        ),
        deletedDeviceSupportOsItem: .constant(nil)
    )
    .frame(width: 360, height: 100)
    .padding()
    .withAppMocks()
}
