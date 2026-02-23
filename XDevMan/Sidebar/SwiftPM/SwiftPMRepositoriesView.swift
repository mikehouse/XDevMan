
import SwiftUI

struct SwiftPMRepositoriesView: View {
    
    @Binding var deletedRepository: SwiftPMCachesRepository?
    @Environment(\.swiftPMCachesService) private var swiftPMCachesService
    @State private var repositories: [SwiftPMCachesRepository]?
    @State private var spmPath: URL?
    
    var body: some View {
        Group {
            if let repositories {
                if repositories.isEmpty {
                    NothingView(text: "No SPM packages found.")
                } else {
                    List(repositories) { repository in
                        SwiftPMRepositoryView(repository: repository, deletedRepository: $deletedRepository)
                            .padding([.bottom], 10)
                            .padding([.top], repository == repositories[0] ? 2 : 10)
                    }
                }
            } else {
                ProgressView()
            }
        }
        .toolbar {
            if let spmPath {
                ToolbarItem(id: "spm-open") {
                    BashOpenView(path: .url(spmPath), type: .toolbarFolder)
                }
            }
        }
        .onChange(of: deletedRepository) {
            if deletedRepository != nil {
                Task { await reloadRepositories() }
            }
        }
        .task {
            spmPath = await swiftPMCachesService.path()
            await reloadRepositories()
        }
    }
    
    private func reloadRepositories() async {
        repositories = await swiftPMCachesService.repositories()
    }
}

#Preview {
    SwiftPMRepositoriesView(deletedRepository: .constant(nil))
        .frame(width: 300, height: 300)
        .padding()
        .withAppMocks()
}
