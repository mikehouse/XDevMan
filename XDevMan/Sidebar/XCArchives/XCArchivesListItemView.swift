
import SwiftUI

struct XCArchivesListItemView: View {
    
    let archiveId: XCArchiveID
    @Environment(\.xcAchivesService) private var xcAchivesService
    @Environment(\.appLogger) private var appLogger
    @State private var archive: XCArchive?
    @State private var icon: NSImage?
    
    var body: some View {
        Group {
            if let archive {
                HStack {
                    if let icon {
                        Image(nsImage: icon)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 20, height: 20)
                    }
                    Text(archive.name)
                    Spacer()
                    Text("\(archive.shortVersion) (\(archive.version))")
                }
            } else {
                HStack {
                    Text(archiveId.name)
                    Spacer()
                }
            }
        }
        .task(id: archiveId) {
            do {
                archive = try await xcAchivesService.archive(archiveId)
                if let archive, let url = archive.primaryIcon {
                    icon = NSImage(contentsOf: url)
                }
            } catch {
                appLogger.error(error)
            }
        }
    }
}

#Preview {
    XCArchivesListItemView(
        archiveId: .init(
            path: URL(fileURLWithPath: "/"),
            name: "MyApp",
            date: Date()
        )
    )
    .padding()
    .frame(width: 300, height: 400)
    .withAppMocks()
}
