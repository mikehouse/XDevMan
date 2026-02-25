import SwiftUI

struct CocoaPodsListView: View {
    
    @Binding var selectedVersion: CocoaPodsLibraryVersion?
    @Binding var deletedVersion: CocoaPodsLibraryVersion?
    @Environment(\.cocoaPodsService) private var cocoaPodsService
    @State private var libraries: [CocoaPodsLibrary]?
    @State private var version: String?
    @State private var size: String?

    var body: some View {
        Group {
            if let libraries {
                if libraries.isEmpty {
                    NothingView(text: "No CocoaPods libraries found.")
                } else {
                    List(selection: $selectedVersion) {
                        ForEach(libraries) { library in
                            Section(header: sectionHeader(library.name)) {
                                ForEach(library.versions) { version in
                                    CocoaPodsVersionRowView(version: version)
                                        .tag(version)
                                        .padding([.bottom], 10)
                                        .padding([.top], version == library.versions.first ? 2 : 10)
                                }
                            }
                        }
                    }
                }
            } else {
                ProgressView()
            }
        }
        .navigationTitle(navigationTitle)
        .task {
            version = await cocoaPodsService.version()
        }
        .task {
            libraries = await cocoaPodsService.libraries()
        }
        .task {
            size = await cocoaPodsService.size()
        }
        .onChange(of: deletedVersion) {
            if deletedVersion != nil {
                Task {
                    libraries = await cocoaPodsService.libraries()
                    size = await cocoaPodsService.size()
                    deletedVersion = nil
                }
            }
        }
        .onDisappear {
            selectedVersion = nil
        }
    }
    
    private var navigationTitle: String {
        var title = "CocoaPods"
        if let version, version.isEmpty == false {
            title = "\(title) \(version)"
        }
        if let size, size.isEmpty == false {
            title = "\(title) (\(size))"
        }
        return title
    }
    
    private func sectionHeader(_ name: String) -> some View {
        Text(name)
            .font(.title2)
            .padding([.bottom, .top], 8)
    }
}

#Preview {
    CocoaPodsListView(selectedVersion: .constant(nil), deletedVersion: .constant(nil))
        .frame(width: 400, height: 400)
        .withCocoaPodsService(CocoaPodsServiceMockImpl())
        .withAppMocks()
}

private final class CocoaPodsServiceMockImpl: CocoaPodsServiceMock {
    
    override func libraries() async -> [CocoaPodsLibrary] {
        [
            .init(name: "Biometrics", versions: [
                .init(
                    name: "16eb1722868e420ca55617a4b66f40c7",
                    library: "Biometrics",
                    source: .external,
                    podspecPath: URL(fileURLWithPath: "/a.podspec.json"),
                    sourcePath: URL(fileURLWithPath: "/a")
                ),
                .init(
                    name: "25db7194a5851b7842c050bd150e1857",
                    library: "Biometrics",
                    source: .external,
                    podspecPath: URL(fileURLWithPath: "/b.podspec.json"),
                    sourcePath: URL(fileURLWithPath: "/b")
                )
            ]),
            .init(name: "abseil", versions: [
                .init(
                    name: "1.20240116.2-d121d",
                    library: "abseil",
                    source: .release,
                    podspecPath: URL(fileURLWithPath: "/c.podspec.json"),
                    sourcePath: URL(fileURLWithPath: "/c")
                )
            ])
        ]
    }
}
