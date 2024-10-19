
import SwiftUI

struct IBSupportItemListView: View {
    
    @Binding var deletedIBSupportItem: IBSupportItem?
    @Environment(\.ibSupportService) private var ibSupportService
    @State private var items: [IBSupportItem]?
    
    var body: some View {
        Group {
            if let items {
                if items.isEmpty {
                    NothingView(text: "No Previews found.")
                } else {
                    List(items) { item in
                        IBSupportItemView(
                            item: item,
                            deletedIBSupportItem: $deletedIBSupportItem
                        )
                        .padding([.bottom], 10)
                        .padding([.top], item == items[0] ? 2 : 10)
                    }
                }
            } else {
                ProgressView()
            }
        }
        .onChange(of: deletedIBSupportItem, {
            if deletedIBSupportItem != nil {
                Task {
                    await reload()
                }
            }
        })
        .task {
            await reload()
        }
    }
    
    private func reload() async {
        Task {
            items = await ibSupportService.simulatorDevices()
        }
    }
}

#Preview {
    IBSupportItemListView(
        deletedIBSupportItem: .constant(nil)
    )
    .padding()
    .frame(width: 300)
    .withAppMocks()
}
