
import SwiftUI

struct CarthageItemView: View {
    
    let item: CarthageItem
    @Binding var deleteCarthageItemdItem: CarthageItem?
    @Environment(\.bashService) private var bashService
    @Environment(\.alertHandler) private var alertHandler
    @Environment(\.gitService) private var gitService
    @Environment(\.carthageService) private var carthageService
    @Environment(\.appLogger) private var appLogger
    @State private var size: String?
    @State private var revision: String?
    @State private var source: URL?
    @State private var isDeleting = false
    
    var body: some View {
        Group {
            HStack {
                if let revision {
                    Text("\(item.name) (\(revision))")
                        .textSelection(.enabled)
                        .lineLimit(1)
                } else {
                    Text(item.name)
                        .textSelection(.enabled)
                        .lineLimit(1)
                }
                Spacer()
                HStack(spacing: 16) {
                    StringSizeView(
                        sizeProvider: {
                            try await carthageService.size(item)
                        }, size: $size
                    )
                    if isDeleting {
                        ProgressView()
                            .controlSize(.mini)
                    } else {
                        Button {
                            Task {
                                do {
                                    isDeleting = true
                                    try await carthageService.delete(item)
                                    deleteCarthageItemdItem = item
                                } catch {
                                    isDeleting = false
                                    appLogger.error(error)
                                    alertHandler.handle(title: "Delete error for \(item.name)", message: nil, error: error)
                                }
                            }
                        } label: {
                            DeleteIconView()
                        }
                        .buttonStyle(BorderlessButtonStyle())
                    }
                    if let source = source {
                        OpenLinkView { source }
                    }
                    BashOpenView(path: .url(item.path), type: .folder)
                }
            }
        }
        .task(id: item) {
            if item.hasGit {
                Task {
                    if revision == nil {
                        do {
                            revision = try await gitService.tagAtHead(item.path)
                            if revision == nil {
                                let commit = try await gitService.commits(item.path, branch: nil, last: 1).first
                                revision = commit.map({ String($0.hash.dropLast(32)) })
                            }
                        } catch {
                            appLogger.error(error)
                        }
                    }
                }
                Task {
                    if source == nil {
                        do {
                            source = try await gitService.remote(item.path)
                        } catch {
                            appLogger.error(error)
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    CarthageItemView(
        item: .init(name: "SnapKit", path: URL(fileURLWithPath: ""), hasGit: false, source: .dependencies),
        deleteCarthageItemdItem: .constant(nil)
    )
    .padding()
    .frame(width: 300)
    .withAppMocks()
}
