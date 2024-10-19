
import SwiftUI

struct PreviewsItemListView: View {
    
    @Binding var deletedPreviewsItem: PreviewsItem?
    @Environment(\.previewsService) private var previewsService
    @State private var items: [PreviewsItem]?
    
    var body: some View {
        Group {
            if let items {
                if items.isEmpty {
                    NothingView(text: "No Previews found.")
                } else {
                    List(items) { item in
                        PreviewsItemView(
                            item: item,
                            deletedPreviewsItem: $deletedPreviewsItem
                        )
                        .padding([.bottom], 10)
                        .padding([.top], item == items[0] ? 2 : 10)
                    }
                }
            } else {
                ProgressView()
            }
        }
        .onChange(of: deletedPreviewsItem, {
            if deletedPreviewsItem != nil {
                reload()
            }
        })
        .task {
            reload()
        }
    }
    
    private func reload() {
        Task {
            items = await previewsService.simulatorDevices()
        }
    }
}

#Preview {
    PreviewsItemListView(
        deletedPreviewsItem: .constant(nil)
    )
    .padding()
    .frame(width: 300)
    .withAppMocks()
}
