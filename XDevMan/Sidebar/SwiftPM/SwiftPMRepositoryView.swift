
import SwiftUI

struct SwiftPMRepositoryView: View {
    
    let repository: SwiftPMCachesRepository
    @Binding var deletedRepository: SwiftPMCachesRepository?
    @Environment(\.bashService) private var bashService
    @Environment(\.alertHandler) private var alertHandler
    @Environment(\.gitService) private var gitService
    @Environment(\.swiftPMCachesService) private var swiftPMCachesService
    @Environment(\.appLogger) private var appLogger
    @State private var size: String?
    @State private var revision: String?
    @State private var isDeleting = false
    
    var body: some View {
        Group {
            HStack {
                Text(repository.name)
                    .textSelection(.enabled)
                    .lineLimit(1)
                Spacer()
                HStack(spacing: 16) {
                    if let revision {
                        Text(revision)
                            .textSelection(.enabled)
                    } else {
                        ProgressView()
                            .controlSize(.mini)
                    }
                    StringSizeView(sizeProvider: {
                        try await bashService.size(repository.path)
                    }, size: $size)
                    if isDeleting {
                        ProgressView()
                            .controlSize(.mini)
                    } else {
                        Button {
                            Task {
                                do {
                                    isDeleting = true
                                    try await swiftPMCachesService.delele(repository)
                                    deletedRepository = repository
                                } catch {
                                    isDeleting = false
                                    alertHandler.handle(title: "Delete error for \(repository.name)", message: nil, error: error)
                                    appLogger.error(error)
                                }
                            }
                        } label: {
                            DeleteIconView()
                        }
                        .buttonStyle(BorderlessButtonStyle())
                    }
                    OpenLinkView {
                        try await gitService.remote(repository.path)
                    }
                    BashOpenView(path: .url(repository.path), type: .folder)
                }
            }
        }
        .task(id: repository) {
            if revision == nil {
                do {
                    if let tag = try await gitService.tagAtHead(repository.path) {
                        revision = tag
                    } else if let commit = try await gitService.commits(repository.path, branch: nil, last: 1).first {
                        revision = String(commit.hash.dropLast(commit.hash.count - 8))
                    } else {
                        revision = repository.hash
                    }
                } catch {
                    appLogger.error(error)
                }
            }
        }
    }
}

#Preview {
    SwiftPMRepositoryView(
        repository: .init(
            path: URL(fileURLWithPath: "/"),
            name: "Amplitude-iOS",
            hash: "b18f1843"),
        deletedRepository: .constant(nil)
    )
    .withAppMocks()
    .frame(width: 400, height: 64)
    .padding()
}
