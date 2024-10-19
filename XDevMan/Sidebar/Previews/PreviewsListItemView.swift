
import SwiftUI

struct PreviewsListItemView: View {
    
    let title: String
    @Binding var deletedPreviewsItem: PreviewsItem?
    @Environment(\.previewsService) private var previewsService
    @State private var size: String?
    
    var body: some View {
        Group {
            HStack {
                Image(systemName: "iphone")
                    .resizable()
                    .frame(width: 14, height: 20)
                    .foregroundColor(.brown)
                Text(title)
                Spacer()
                StringSizeView(sizeProvider: {
                    await previewsService.size() ?? "??"
                }, size: $size)
            }
        }
        .task(id: title) {
        }
        .onChange(of: deletedPreviewsItem) {
            if deletedPreviewsItem != nil {
                size = nil
            }
        }
    }
}

#Preview {
    PreviewsListItemView(
        title: "Previews",
        deletedPreviewsItem: .constant(nil)
    )
    .padding()
    .frame(width: 300)
    .withAppMocks()
}
