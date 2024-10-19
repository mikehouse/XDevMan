
import SwiftUI

struct IBSupportListView: View {
    
    @Binding var seletedIBSupportItem: String?
    @Binding var deletedIBSupportItem: IBSupportItem?
    @Environment(\.ibSupportService) private var ibSupportService
    @State private var list = ["IB Support"]
    
    var body: some View {
        List(list, id: \.self, selection: $seletedIBSupportItem) { item in
            IBSupportListItemView(
                title: item,
                deletedIBSupportItem: $deletedIBSupportItem
            )
            .modifier(ListItemViewPaddingModifier())
        }
        .navigationTitle("IB Support")
        .toolbar {
            ToolbarItem(id: "ib-support-open") {
                BashOpenView(
                    path: .custom({ await ibSupportService.open() }),
                    type: .toolbarFolder
                )
            }
        }
        .onDisappear {
            seletedIBSupportItem = nil
            deletedIBSupportItem = nil
        }
    }
}

#Preview {
    IBSupportListView(
        seletedIBSupportItem: .constant(nil),
        deletedIBSupportItem: .constant(nil)
    )
    .padding()
    .frame(width: 300)
    .withAppMocks()
}
