import SwiftUI

struct CocoaPodsVersionRowView: View {
    
    let version: CocoaPodsLibraryVersion
    
    var body: some View {
        HStack {
            Text(version.name)
                .textSelection(.enabled)
                .lineLimit(1)
            Spacer()
        }
    }
}

#Preview {
    CocoaPodsVersionRowView(version: .init(
        name: "1.20240116.2-d121d",
        library: "abseil",
        source: .release,
        podspecPath: URL(fileURLWithPath: "/a.podspec.json"),
        sourcePath: URL(fileURLWithPath: "/a")
    ))
    .padding()
    .frame(width: 300)
    .withAppMocks()
}
