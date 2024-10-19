
import SwiftUI

struct DeviceSupportOsListView: View {
    
    @Binding var deletedDeviceSupportOsItem: DeviceSupportOsItem?
    @Binding var selectedDeviceSupportOs: DeviceSupportOs?
    @Environment(\.deviceSupportService) private var deviceSupportService
    @State private var osList: [DeviceSupportOs]?
    
    var body: some View {
        Group {
            if let osList {
                if osList.isEmpty {
                    NothingView(text: "Not found.")
                } else {
                    List(osList, id: \.self, selection: $selectedDeviceSupportOs) { os in
                        DeviceSupportOsListItemView(os: os)
                            .modifier(ListItemViewPaddingModifier())
                    }
                }
            } else {
                ProgressView()
                    .task {
                        await reloadList()
                    }
            }
        }
        .navigationTitle("Devices Symbols")
        .onChange(of: deletedDeviceSupportOsItem) {
            if deletedDeviceSupportOsItem != nil {
                Task { await reloadList() }
            }
        }
        .onDisappear {
            selectedDeviceSupportOs = nil
            deletedDeviceSupportOsItem = nil
        }
    }
    
    private func reloadList() async {
        osList = await deviceSupportService.osList()
        selectedDeviceSupportOs = osList?
            .first(where: { $0.name == selectedDeviceSupportOs?.name })
    }
}

#Preview {
    DeviceSupportOsListView(
        deletedDeviceSupportOsItem: .constant(nil),
        selectedDeviceSupportOs: .constant(nil)
    )
    .withDeviceSupportService(DeviceSupportServiceMockImpl())
    .withAppMocks()
    .frame(width: 300, height: 300)
    .padding()
}

private final class DeviceSupportServiceMockImpl: DeviceSupportServiceMock {
    
    override func osList() async -> [DeviceSupportOs] {
        [
            .init(
                name: "iOS", path: URL(fileURLWithPath: "/"),
                items: [.init(name: "iPhone 16", path: URL(fileURLWithPath: "/"))]
            ),
            .init(
                name: "tvOS", path: URL(fileURLWithPath: "/"),
                items: [.init(name: "Apple TV 5", path: URL(fileURLWithPath: "/"))]
            ),
            .init(
                name: "watchOS", path: URL(fileURLWithPath: "/"),
                items: [.init(name: "Apple watch 10", path: URL(fileURLWithPath: "/"))]
            ),
        ]
    }
}
