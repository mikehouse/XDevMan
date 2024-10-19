
import SwiftUI

struct SwiftPMListRepositoriesView: View {
    
    @Binding var deletedRepository: SwiftPMCachesRepository?
    @Environment(\.swiftPMCachesService) private var swiftPMCachesService
    @State private var size: String?
    
    var body: some View {
        Group {
            HStack {
                Image(systemName: "swift")
                    .resizable()
                    .frame(width: 18, height: 18)
                    .foregroundColor(.orange)
                Text("Repositories")
                Spacer()
                StringSizeView(sizeProvider: {
                    guard await swiftPMCachesService.exists() else {
                        return ""
                    }
                    return try await swiftPMCachesService.size()
                }, size: $size)
            }
        }
        .task {
        }
        .onChange(of: deletedRepository) {
            if deletedRepository != nil {
                size = nil
            }
        }
    }
}

#Preview {
    SwiftPMListRepositoriesView(
        deletedRepository: .constant(nil)
    )
    .frame(width: 300, height: 44)
    .padding()
    .withAppMocks()
}
