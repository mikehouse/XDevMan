
import SwiftUI

struct DerivedDataListAppItemView: View {
    
    let app: DerivedDataApp
    let ide: String
    @Binding var appDeleted: DerivedDataApp?
    @State private var size: String?
    @State private var isDeleting = false
    @Environment(\.alertHandler) private var alertHandler
    @Environment(\.bashService) private var bashService
    @Environment(\.appLogger) private var appLogger
    @Environment(\.derivedDataService) private var derivedDataService
    
    var body: some View {
        Group {
            HStack {
                Text(app.name)
                    .lineLimit(1)
                Spacer()
                HStack(spacing: 16) {
                    StringSizeView(sizeProvider: {
                        try await bashService.size(app.path)
                    }, size: $size)
                    if isDeleting {
                        ProgressView()
                            .controlSize(.mini)
                    } else {
                        Button {
                            Task {
                                do {
                                    isDeleting = true
                                    try await derivedDataService.delete(app, for: ide)
                                    appDeleted = app
                                } catch {
                                    isDeleting = false
                                    appLogger.error(error)
                                    alertHandler.handle(title: "Delete error for \(app.name)", message: nil, error: error)
                                }
                            }
                        } label: {
                            DeleteIconView()
                        }
                        .buttonStyle(BorderlessButtonStyle())
                    }
                    BashOpenView(path: .url(app.path), type: .folder)
                }
            }
        }
        .task(id: app) {
        }
    }
}

#Preview {
    DerivedDataListAppItemView(app: .init(
        name: "MyApp",
        path: URL(fileURLWithPath: "/")), ide: "Xcode", appDeleted: .constant(nil)
    )
    .frame(width: 300, height: 64)
    .padding()
    .withAppMocks()
}
