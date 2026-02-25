import SwiftUI

struct CocoaPodsPodspecView: View {
    
    let version: CocoaPodsLibraryVersion
    @Binding var selectedVersion: CocoaPodsLibraryVersion?
    @Binding var deletedVersion: CocoaPodsLibraryVersion?
    @Environment(\.cocoaPodsService) private var cocoaPodsService
    @Environment(\.alertHandler) private var alertHandler
    @Environment(\.appLogger) private var appLogger
    @State private var podspec: String?
    @State private var loadFailed = false
    @State private var isDeleting = false
    
    var body: some View {
        Group {
            if loadFailed {
                NothingView(text: "Unable to read podspec.")
            } else if let podspec {
                ScrollView {
                    Text(podspec)
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding()
            } else {
                ProgressView()
            }
        }
        .toolbar {
            ToolbarItem(id: "cocoapods-delete") {
                if isDeleting {
                    ProgressView()
                        .controlSize(.mini)
                } else {
                    Button {
                        Task {
                            do {
                                isDeleting = true
                                try await cocoaPodsService.delete(version)
                                deletedVersion = version
                                selectedVersion = nil
                            } catch {
                                isDeleting = false
                                alertHandler.handle(title: "Delete error for \(version.library)", message: nil, error: error)
                                appLogger.error(error)
                            }
                        }
                    } label: {
                        DeleteIconView()
                    }
                    .buttonStyle(.toolbarDefault)
                }
            }
            ToolbarItem(id: "cocoapods-open") {
                BashOpenView(
                    path: .custom({ try await cocoaPodsService.open(version) }),
                    type: .toolbarFolder
                )
            }
        }
        .task(id: version) {
            do {
                loadFailed = false
                podspec = try await cocoaPodsService.podspec(for: version)
            } catch {
                loadFailed = true
                alertHandler.handle(title: "Podspec read error", message: nil, error: error)
                appLogger.error(error)
            }
        }
    }
}

#Preview {
    CocoaPodsPodspecView(version: .init(
        name: "1.20240116.2-d121d",
        library: "abseil",
        source: .release,
        podspecPath: URL(fileURLWithPath: "/a.podspec.json"),
        sourcePath: URL(fileURLWithPath: "/a")
    ), selectedVersion: .constant(nil), deletedVersion: .constant(nil))
    .frame(width: 500, height: 400)
    .withCocoaPodsService(CocoaPodsServiceMockImpl())
    .withAppMocks()
}

private final class CocoaPodsServiceMockImpl: CocoaPodsServiceMock {
    
    override func podspec(for version: CocoaPodsLibraryVersion) async throws -> String {
        "{\n  \"name\": \"abseil\",\n  \"version\": \"1.20240116.2-d121d\"\n}"
    }
}
