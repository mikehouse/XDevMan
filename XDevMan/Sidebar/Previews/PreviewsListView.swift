
import SwiftUI

struct PreviewsListView: View {
    
    @Binding var seletedPreviewsItem: String?
    @Binding var deletedPreviewsItem: PreviewsItem?
    @Environment(\.previewsService) private var previewsService
    @State private var list = ["Simulator Devices"]
    
    var body: some View {
        List(list, id: \.self, selection: $seletedPreviewsItem) { item in
            PreviewsListItemView(
                title: item,
                deletedPreviewsItem: $deletedPreviewsItem
            )
            .modifier(ListItemViewPaddingModifier())
        }
        .navigationTitle("Previews")
        .toolbar {
            ToolbarItem(id: "previews-open") {
                BashOpenView(
                    path: .custom({ await previewsService.open() }),
                    type: .toolbarFolder
                )
            }
        }
        .onDisappear {
            seletedPreviewsItem = nil
            deletedPreviewsItem = nil
        }
    }
}

#Preview {
    PreviewsListView(
        seletedPreviewsItem: .constant(nil),
        deletedPreviewsItem: .constant(nil)
    )
    .padding()
    .frame(width: 300)
    .withAppMocks()
}
