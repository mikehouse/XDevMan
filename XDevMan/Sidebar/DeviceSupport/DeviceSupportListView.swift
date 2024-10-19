
import SwiftUI

struct DeviceSupportListView: View {
    
    let os: DeviceSupportOs
    @Binding var deletedDeviceSupportOsItem: DeviceSupportOsItem?
    
    var body: some View {
        Group {
            List(os.items, id: \.self) { device in
                DeviceSupportListItemView(
                    osItem: device,
                    deletedDeviceSupportOsItem: $deletedDeviceSupportOsItem
                )
                .padding([.bottom], 10)
                .padding([.top], device == os.items[0] ? 2 : 10)
            }
        }
    }
}

#Preview {
    DeviceSupportListView(
        os: .init(
            name: "watchOS",
            path: URL(fileURLWithPath: "/"),
            items: [
                .init(name: "Apple Watch 9", path: URL(fileURLWithPath: "/")),
                .init(name: "Apple Watch 10", path: URL(fileURLWithPath: "/")),
            ]
        ), deletedDeviceSupportOsItem: .constant(nil)
    )
    .frame(width: 300, height: 160)
    .padding()
    .withAppMocks()
}
