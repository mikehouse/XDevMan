
import SwiftUI

struct CarthageListItemView: View {
    
    let item: CarthageSource
    @Binding var deletedItem: CarthageItem?
    @Binding var deleteCarthageDerivedDataItem: CarthageDerivedDataItem?
    @Environment(\.carthageService) private var carthageService
    @State private var size: String?
    
    var body: some View {
        Group {
            HStack {
                Image(systemName: "swift")
                    .resizable()
                    .frame(width: 18, height: 18)
                    .foregroundColor(.orange)
                Text(item.rawValue)
                Spacer()
                StringSizeView(
                    sizeProvider: {
                        guard carthageService.exists(item) else {
                            return "??"
                        }
                        return try await carthageService.size(item)
                    },
                    size: $size
                )
            }
        }
        .task(id: item) {
        }
        .onChange(of: deletedItem) {
            if deletedItem?.source == self.item {
                size = nil
            }
        }
        .onChange(of: deleteCarthageDerivedDataItem) {
            if deleteCarthageDerivedDataItem?.source == self.item {
                size = nil
            }
        }
    }
}

#Preview {
    CarthageListItemView(
        item: .binaries,
        deletedItem: .constant(nil),
        deleteCarthageDerivedDataItem: .constant(nil)
    )
    .padding()
    .frame(width: 200)
    .withAppMocks()
}
