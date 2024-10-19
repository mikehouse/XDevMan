
import SwiftUI

struct CarthageDerivedDataListView: View {
    
    let item: CarthageSource
    @Binding var deleteCarthageDerivedDataItem: CarthageDerivedDataItem?
    @Environment(\.carthageService) private var carthageService
    @State private var items: [CarthageDerivedData]?
    
    var body: some View {
        Group {
            if let items {
                if items.isEmpty {
                    NothingView(text: "No Carthage \(item.rawValue.lowercased()) found.")
                } else {
                    List(items) { item in
                        Section(header: xcodeDisplayName(item)) {
                            ForEach(item.items) { lib in
                                CarthageDerivedDataListItemView(
                                    item: lib,
                                    deleteCarthageDerivedDataItem: $deleteCarthageDerivedDataItem
                                )
                                .padding([.bottom], 10)
                                .padding([.top], lib == item.items[0] ? 2 : 10)
                            }
                        }
                    }
                }
            } else {
                ProgressView()
            }
        }
        .onChange(of: deleteCarthageDerivedDataItem, {
            if deleteCarthageDerivedDataItem != nil {
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
        Task {
            switch item {
            case .derivedData:
                items = await carthageService.derivedData()
            default:
                fatalError()
            }
        }
    }
    
    private func xcodeDisplayName(_ data: CarthageDerivedData) -> some View {
        let xcode = "Xcode \(data.xcode.components(separatedBy: "_")[0]) (\(data.xcode.components(separatedBy: "_")[1]))"
        return Text(xcode).font(.title2).padding([.bottom, .top], 8)
    }
}

#Preview {
    CarthageDerivedDataListView(
        item: .derivedData,
        deleteCarthageDerivedDataItem: .constant(nil)
    )
    .padding()
    .frame(width: 400, height: 400)
    .withCarthageService(CarthageServiceMockImpl())
    .withAppMocks()
}

private final class CarthageServiceMockImpl: CarthageServiceMock {
    
    override func derivedData() async -> [CarthageDerivedData] {
        [
            .init(xcode: "16.0_16A242d", items: [
                .init(name: "SnapKit", version: "1.0.1", path: URL(fileURLWithPath: "/a")),
                .init(name: "DeviceKit", version: "1.0.1", path: URL(fileURLWithPath: "/b"))
            ]),
            .init(xcode: "16.1_16A24A", items: [
                .init(name: "SnapKit", version: "1.0.1", path: URL(fileURLWithPath: "/a")),
                .init(name: "DeviceKit", version: "1.0.1", path: URL(fileURLWithPath: "/b"))
            ])
        ]
    }
}
