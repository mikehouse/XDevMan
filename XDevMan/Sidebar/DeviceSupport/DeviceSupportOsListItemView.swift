
import SwiftUI

struct DeviceSupportOsListItemView: View {
    
    let os: DeviceSupportOs
    @Environment(\.bashService) private var bashService
    @State private var size: String?
    
    var body: some View {
        Group {
            HStack {
                switch os.name {
                case "iOS":
                    Image(systemName: "iphone")
                        .resizable()
                        .frame(width: 18, height: 26)
                case "macOS":
                    Image(systemName: "macbook")
                        .resizable()
                        .frame(width: 28, height: 18)
                case "tvOS":
                    Image(systemName: "tv")
                        .resizable()
                        .frame(width: 26, height: 22)
                case "watchOS":
                    Image(systemName: "applewatch")
                        .resizable()
                        .frame(width: 18, height: 26)
                default:
                    EmptyView()
                }
                Text(os.name)
                Spacer()
                StringSizeView(sizeProvider: {
                    try await bashService.size(os.path)
                }, size: $size)
            }
        }
        .task(id: os) {
        }
    }
    
    private func makeIcon(_ systemName: String) -> some View {
        Image(systemName: systemName)
            .resizable()
            .frame(width: 24, height: 24)
    }
}

#Preview {
    VStack(spacing: 16) {
        DeviceSupportOsListItemView(
            os: .init(
                name: "iOS",
                path: URL(fileURLWithPath: "/"),
                items: [.init(name: "iPhone 16", path: URL(fileURLWithPath: "/"))]
            )
        )
        DeviceSupportOsListItemView(
            os: .init(
                name: "tvOS",
                path: URL(fileURLWithPath: "/"),
                items: [.init(name: "Apple TV 6", path: URL(fileURLWithPath: "/"))]
            )
        )
        DeviceSupportOsListItemView(
            os: .init(
                name: "watchOS",
                path: URL(fileURLWithPath: "/"),
                items: [.init(name: "Apple watch 10", path: URL(fileURLWithPath: "/"))]
            )
        )
    }
    .withAppMocks()
    .frame(width: 300, height: 200)
    .padding()
}
