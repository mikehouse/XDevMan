
import SwiftUI

struct CarthageListView: View {
    
    @Binding var carthageListItemSelected: CarthageSource?
    @Binding var deleteCarthageItemdItem: CarthageItem?
    @Binding var deleteCarthageDerivedDataItem: CarthageDerivedDataItem?
    @Environment(\.carthageService) private var carthageService
    @Environment(\.bashService) private var bashService
    @State private var list: [CarthageSource] = [.dependencies, .binaries, .derivedData]
    
    var body: some View {
        List(list, id: \.self, selection: $carthageListItemSelected) { item in
            CarthageListItemView(
                item: item,
                deletedItem: $deleteCarthageItemdItem,
                deleteCarthageDerivedDataItem: $deleteCarthageDerivedDataItem
            )
            .modifier(ListItemViewPaddingModifier())
        }
        .navigationTitle("CarthageKit")
        .toolbar {
            if let item = carthageListItemSelected, carthageService.exists(item) {
                ToolbarItem(id: "carthage-open") {
                    BashOpenView(
                        path: .custom({ try await carthageService.open(item) }),
                        type: .toolbarFolder
                    )
                }
            }
        }
        .onDisappear {
            carthageListItemSelected = nil
            deleteCarthageItemdItem = nil
            deleteCarthageDerivedDataItem = nil
        }
    }
}

#Preview {
    CarthageListView(
        carthageListItemSelected: .constant(nil),
        deleteCarthageItemdItem: .constant(nil),
        deleteCarthageDerivedDataItem: .constant(nil)
    )
    .frame(width: 400, height: 300)
    .withAppMocks()
}
