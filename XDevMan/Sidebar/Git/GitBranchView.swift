
import SwiftUI

struct GitBranchView: View {
    
    let branch: Branch
    let path: URL
    @Binding var deleted: Branch?
    @State private var commits: [Commit]?
    @State private var error: Error?
    @State private var deleteBranchAlertPresented = false
    @Environment(\.gitService) private var gitService
    @Environment(\.appLogger) private var appLogger
    
    var body: some View {
        Group {
            if let error {
                BaseErrorView(error: error)
            } else if let commits {
                ScrollView {
                    VStack(alignment: .leading) {
                        ForEach(commits) { commit in
                            VStack(alignment: .leading) {
                                Text(commit.commit).foregroundStyle(.orange).padding(.bottom, 1)
                                Text(commit.author).foregroundStyle(.mint).padding(.bottom, 1)
                                Text(commit.date).foregroundStyle(.indigo).padding(.bottom, 4)
                                Text(commit.message).foregroundStyle(.gray)
                            }
                        }
                    }
                    .padding([.leading, .trailing])
                }
                .scrollIndicators(.hidden)
                .padding()
                .toolbar {
                    if !branch.isProtected {
                        ToolbarItem(id: "git-delete-branch") {
                            Button {
                                deleteBranchAlertPresented = true
                            } label: {
                                VStack {
                                    Image(systemName: "trash")
                                    Text("Delete branch")
                                }
                            }
                            .buttonStyle(.toolbarDefault)
                        }
                        ToolbarItem(id: "git-copy-branch-name") {
                            Button {
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString(branch.name, forType: .string)
                            } label: {
                                VStack {
                                    Image(systemName: "doc.on.doc")
                                    Text("Copy name")
                                }
                            }
                            .buttonStyle(.toolbarDefault)
                        }
                    }
                }
                .alert((Text("Delete \(branch.name) branch ?")), isPresented: $deleteBranchAlertPresented) {
                    Button("Cancel", role: .cancel, action: {})
                    Button("Delete", role: .destructive, action: {
                        Task {
                            do {
                                try await gitService.delete(path, branch: branch)
                                deleted = branch
                            } catch {
                                self.error = error
                                appLogger.error(error)
                            }
                        }
                    })
                } message: {
                    Text("Not recoverable action.")
                }
            } else {
                ProgressView()
            }
        }
        .task(id: branch.id + path.absoluteString, {
            do {
                commits = try await gitService.commits(path, branch: branch, last: 5)
            } catch {
                self.error = error
                appLogger.error(error)
            }
        })
    }
}

#Preview {
    Group {
        GitBranchView(
            branch: .init(name: "dev"),
            path: URL(fileURLWithPath: "/"),
            deleted: .constant(.init(name: ""))
        )
        .withGitService(GitProviderMockObject.self)
        .withAppMocks()
    }
    .frame(width: 500, height: 300)
}

private class GitProviderMockObject: GitProviderMock {
    
    override class func commits(_ path: URL, branch: Branch?, last: UInt) async throws -> [Commit] {
        [
            .init(
                commit: "commit a66b81c58c015cd2cde5d0f0f7c3ebda01d441e0",
                hash: "a66b81c58c015cd2cde5d0f0f7c3ebda01d441e0",
                tag: "",
                author: "Author: Ajuk Hurse <img@gmail.com>",
                date: "Date:   Thu Jun 27 11:27:44 2024 +0700",
                message: "\tvideo player set preview mode as default\n"
            ),
            .init(
                commit: "commit a66b81c58c015cd2cde5d0f0f7c3ebda01d441e0 (HEAD -> master, origin/master, origin/HEAD)",
                hash: "a66b81c58c015cd2cde5d0f0f7c3ebda01d441e0",
                tag: "",
                author: "Author: Ajuk Hurse <img@gmail.com>",
                date: "Date:   Thu Jun 27 11:27:44 2024 +0700",
                message: "\tvideo player set preview mode as default\n"
            )
        ]
    }
}
