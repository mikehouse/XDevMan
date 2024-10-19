
import SwiftUI

struct IBSupportListItemView: View {
    
    let title: String
    @Binding var deletedIBSupportItem: IBSupportItem?
    @Environment(\.ibSupportService) private var ibSupportService
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
                    await ibSupportService.size() ?? "??"
                }, size: $size)
            }
        }
        .task(id: title) {
        }
        .onChange(of: deletedIBSupportItem) {
            if deletedIBSupportItem != nil {
                size = nil
            }
        }
    }
}

#Preview {
    IBSupportListItemView(
        title: "Previews",
        deletedIBSupportItem: .constant(nil)
    )
    .padding()
    .frame(width: 300)
    .withAppMocks()
}
