
import SwiftUI

struct CarthageItemListView: View {
    
    let item: CarthageSource
    @Binding var deleteCarthageItemdItem: CarthageItem?
    @Environment(\.carthageService) private var carthageService
    @State private var items: [CarthageItem]?
    
    var body: some View {
        Group {
            if let items {
                if items.isEmpty {
                    NothingView(text: "No Carthage \(item.rawValue.lowercased()) found.")
                } else {
                    List(items) { item in
                        CarthageItemView(
                            item: item,
                            deleteCarthageItemdItem: $deleteCarthageItemdItem
                        )
                        .padding([.bottom], 10)
                        .padding([.top], item == items[0] ? 2 : 10)
                    }
                }
            } else {
                ProgressView()
            }
        }
        .onChange(of: deleteCarthageItemdItem, {
            if deleteCarthageItemdItem != nil {
                Task {
                    await reload()
                }
            }
        })
        .task(id: item) {
            await reload()
        }
    }
    
    private func reload() async {
        switch item {
        case .dependencies:
            items = await carthageService.dependencies()
        case .binaries:
            items = await carthageService.binaries()
        default:
            assertionFailure()
        }
    }
}

#Preview {
    CarthageItemListView(
        item: .dependencies,
        deleteCarthageItemdItem: .constant(nil)
    )
    .padding()
    .frame(width: 400, height: 200)
    .withCarthageService(CarthageServiceMockImpl())
    .withAppMocks()
}

private final class CarthageServiceMockImpl: CarthageServiceMock {
    
    override func dependencies() async -> [CarthageItem] {
        [
            .init(name: "SnapKit", path: URL(fileURLWithPath: "/a"), hasGit: true, source: .dependencies),
            .init(name: "DeviceKit", path: URL(fileURLWithPath: "/b"), hasGit: false, source: .dependencies),
        ]
    }
}
