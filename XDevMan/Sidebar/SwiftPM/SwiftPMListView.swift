
import SwiftUI

struct SwiftPMListView: View {

    @Binding var sourceSelected: Source?
    @Binding var deletedRepository: SwiftPMCachesRepository?
    @Environment(\.swiftPMCachesService) private var swiftPMCachesService
    @State private var navigationTitle: String = "SPM"
    @State private var sources: [Source] = [.repositories]

    var body: some View {
        Group {
            List(sources, id: \.self, selection: $sourceSelected) { source in
                switch source {
                case .repositories:
                    SwiftPMListRepositoriesView(
                        deletedRepository: $deletedRepository
                    )
                    .modifier(ListItemViewPaddingModifier())
                }
            }
        }
        .navigationTitle(navigationTitle)
        .onDisappear {
            sourceSelected = nil
            deletedRepository = nil
        }
    }
}

extension SwiftPMListView {

    enum Source: String, Hashable, Identifiable {

        var id: RawValue { rawValue }

        case repositories
    }
}

#Preview {
    SwiftPMListView(
        sourceSelected: .constant(nil),
        deletedRepository: .constant(nil)
    )
    .frame(width: 300, height: 200)
    .padding()
    .withAppMocks()
}
