
import SwiftUI

struct DerivedDataListItemView: View {
    
    let derivedData: DerivedData
    @State private var size: String?
    @Environment(\.bashService) private var bashService
    
    var body: some View {
        Group {
            HStack {
                switch derivedData.ideName {
                case "Fleet":
                    makeIcon(.fleet)
                case _ where derivedData.ideName.hasPrefix("AppCode"):
                    makeIcon(.appcode)
                default:
                    makeIcon(.xcode)
                }
                Text(derivedData.ideName)
                Spacer()
                StringSizeView(sizeProvider: {
                    try await bashService.size(derivedData.path)
                }, size: $size)
            }
        }
        .task(id: derivedData.id) {
        }
    }
    
    private func makeIcon(_ resource: ImageResource) -> some View {
        Image(resource)
            .resizable()
            .frame(width: 24, height: 24)
    }
}

#Preview {
    DerivedDataListItemView(derivedData: .init(
        ideName: "Xcode", path: URL(fileURLWithPath: "/"), apps: [])
    )
    .padding()
    .frame(width: 300, height: 64)
    .withAppMocks()
}
