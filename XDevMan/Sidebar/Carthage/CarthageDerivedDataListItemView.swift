
import SwiftUI

struct CarthageDerivedDataListItemView: View {
    
    let item: CarthageDerivedDataItem
    @Binding var deleteCarthageDerivedDataItem: CarthageDerivedDataItem?
    @Environment(\.bashService) private var bashService
    @Environment(\.alertHandler) private var alertHandler
    @Environment(\.gitService) private var gitService
    @Environment(\.carthageService) private var carthageService
    @Environment(\.appLogger) private var appLogger
    @State private var size: String?
    @State private var isDeleting = false
    
    var body: some View {
        Group {
            HStack {
                Text("\(item.name) (\(item.version.count == 40 ? String(item.version.dropLast(32)) : item.version))")
                    .textSelection(.enabled)
                    .lineLimit(1)
                Spacer()
                HStack(spacing: 16) {
                    StringSizeView(sizeProvider: {
                        try await carthageService.size(item)
                    }, size: $size)
                    if isDeleting {
                        ProgressView()
                            .controlSize(.mini)
                    } else {
                        Button {
                            Task {
                                do {
                                    isDeleting = true
                                    try await carthageService.delete(item)
                                    self.deleteCarthageDerivedDataItem = item
                                } catch {
                                    isDeleting = false
                                    self.alertHandler.handle(title: "Delete error for \(item.name)", message: nil, error: error)
                                }
                            }
                        } label: {
                            DeleteIconView()
                        }
                        .buttonStyle(BorderlessButtonStyle())
                    }
                    BashOpenView(path: .url(item.path), type: .folder)
                }
            }
        }
        .task(id: item) {
        }
    }
}

#Preview {
    CarthageDerivedDataListItemView(
        item: .init(name: "SnapKit", version: "1.0.2", path: URL(fileURLWithPath: "/")),
        deleteCarthageDerivedDataItem: .constant(nil)
    )
    .padding()
    .frame(width: 300)
    .withAppMocks()
}
