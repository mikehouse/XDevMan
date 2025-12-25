
import SwiftUI
import UniformTypeIdentifiers

struct GitBranchListView: View {
    
    @Binding var branch: Branch?
    @Binding var gitRepoPath: URL?
    @Binding var reloadBranches: Bool
    @Binding var deleted: Branch?
    @State private var branches: [Branch]?
    @State private var error: Error?
    @State private var fileImporterIsPresented = false
    @State private var navigationTitle = "Git"
    @Environment(\.gitService) private var gitService
    @Environment(\.appLogger) private var appLogger
    
    var body: some View {
        Group {
            if gitRepoPath == nil {
                NothingView(text: "Select git repository path.")
            } else {
                if let error {
                    BaseErrorView(error: error)
                } else {
                    if let gitRepoPath, reloadBranches || deleted != nil {
                        ProgressView()
                            .task {
                                do {
                                    branches = try await gitService.branches(gitRepoPath)
                                    reloadBranches = false
                                    deleted = nil
                                    branch = nil
                                } catch {
                                    self.error = error
                                    branches = nil
                                    reloadBranches = false
                                    deleted = nil
                                    branch = nil
                                    appLogger.error(error)
                                }
                            }
                    } else if let branches {
                        if branches.isEmpty {
                            NothingView(text: "No branches found at \(gitRepoPath?.path ?? "NULL")")
                        } else {
                            List(branches, id: \.self, selection: $branch) { branch in
                                GitBranchListItemView(branch: branch)
                                    .modifier(ListItemViewPaddingModifier())
                            }
                        }
                    } else {
                        NothingView(text: "Should not be here.")
                    }
                }
            }
        }
        .onAppear {
            runReloadBranches()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.willBecomeActiveNotification)) { _ in
            runReloadBranches()
        }
        .toolbar {
            Button {
                fileImporterIsPresented = true
            } label: {
                VStack {
                    Image(systemName: "folder.badge.plus")
                    Text("Git repository")
                }
            }
            .buttonStyle(.toolbarDefault)
        }
        .navigationTitle(navigationTitle)
        .onDisappear {
            branch = nil
            deleted = nil
            reloadBranches = false
        }
        .fileImporter(
            isPresented: $fileImporterIsPresented,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false) { (result: Result<[URL], any Error>) in
                reloadBranches = true
                switch result {
                case .success(let success):
                    branch = nil
                    navigationTitle = success.first?.lastPathComponent ?? ""
                    gitRepoPath = success.first
                case .failure(let failure):
                    navigationTitle = "Git"
                    error = failure
                    appLogger.error(failure)
                }
            }
    }
    
    private func runReloadBranches() {
        branch = nil
        error = nil
        reloadBranches = true
    }
}

#Preview {
    GitBranchListView(
        branch: .constant(nil),
        gitRepoPath: .constant(nil),
        reloadBranches: .constant(false),
        deleted: .constant(nil)
    )
    .frame(width: 420, height: 300)
    .withAppMocks()
}
