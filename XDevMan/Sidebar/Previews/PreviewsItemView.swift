
import SwiftUI

struct PreviewsItemView: View {
    
    let item: PreviewsItem
    @Binding var deletedPreviewsItem: PreviewsItem?
    @Environment(\.simulatorAppsService) private var simulatorAppsService
    @Environment(\.previewsService) private var previewsService
    @Environment(\.bashService) private var bashService
    @Environment(\.alertHandler) private var alertHandler
    @Environment(\.appLogger) private var appLogger
    @State private var size: String?
    @State private var isDeleting = false
    @State private var apps: [SimAppItem] = []
    
    var body: some View {
        VStack {
            HStack {
                Text(name())
                    .textSelection(.enabled)
                    .lineLimit(1)
                Spacer()
                HStack(spacing: 16) {
                    StringSizeView(sizeProvider: {
                        try await previewsService.size(item)
                    }, size: $size)
                    if isDeleting {
                        ProgressView()
                            .controlSize(.mini)
                    } else {
                        Button {
                            Task {
                                do {
                                    isDeleting = true
                                    try await previewsService.delete(item)
                                    deletedPreviewsItem = item
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
                        path: .custom({ try await previewsService.open(item) }),
                        type: .folder
                    )
                }
            }
            if !apps.isEmpty {
                Spacer(minLength: 12)
                SimulatorAppsListView(items: apps)
            }
        }
        .task(id: item) {
            apps = await simulatorAppsService.apps(for: item)
        }
    }
    
    func name() -> String {
        guard let runtime = item.runtime.components(separatedBy: ".").last else {
            return item.name
        }
        let parts = runtime.components(separatedBy: "-")
        return "\(item.name) (\(parts[0]) \(parts.dropFirst().joined(separator: ".")))"
    }
}

#Preview {
    PreviewsItemView(
        item: .init(
            name: "iPhone 15",
            dataPath: URL(fileURLWithPath: "/"),
            udid: "C17547A2-F6BB-4AC2-9B2D-BCE8F958352C",
            runtime: "com.apple.CoreSimulator.SimRuntime.iOS-16-4"
        ),
        deletedPreviewsItem: .constant(nil)
    )
    .padding()
    .frame(width: 300)
    .withAppMocks()
}
