
import SwiftUI

struct XCArchivesListView: View {
    
    @Binding var xcArchiveSelected: XCArchiveID?
    @Binding var xcArchiveDeleted: XCArchiveID?
    @Environment(\.xcAchivesService) private var xcAchivesService
    @State private var size: String?
    @State private var archives: [XCArchives]?
    
    var body: some View {
        Group {
            if let archives {
                if archives.isEmpty {
                    NothingView(text: "No archives found.")
                } else {
                    HStack {
                        Text("Size: ")
                        Spacer()
                        StringSizeView(sizeProvider: {
                            await xcAchivesService.size() ?? "??"
                        }, size: $size)
                    }
                    .padding([.leading, .trailing, .top], 8)
                    List(archives, selection: $xcArchiveSelected) { archive in
                        Section(archive.date) {
                            ForEach(archive.archives, id: \.self) { id in
                                XCArchivesListItemView(archiveId: id)
                                    .modifier(ListItemViewPaddingModifier())
                            }
                        }
                    }
                }
            } else {
                ProgressView()
                    .controlSize(.small)
            }
        }
        .navigationTitle("Archives")
        .toolbar {
            ToolbarItem(id: "archives-open") {
                BashOpenView(
                    path: .custom({ _ = await xcAchivesService.open() }),
                    type: .toolbarFolder
                )
            }
        }
        .onChange(of: xcArchiveDeleted) {
            if xcArchiveDeleted != nil {
                xcArchiveSelected = nil
                update()
            }
        }
        .task {
            await updateArchives()
        }
        .onDisappear {
            xcArchiveSelected = nil
            xcArchiveDeleted = nil
        }
    }
    
    func update() {
        Task { await updateArchives() }
        updateSize()
    }
    
    private func updateArchives() async {
        archives = await xcAchivesService.archives()
    }
    
    private func updateSize() {
        size = nil
    }
}

#Preview {
    XCArchivesListView(
        xcArchiveSelected: .constant(nil),
        xcArchiveDeleted: .constant(nil)
    )
    .padding()
    .frame(width: 300, height: 400)
    .withAppMocks()
}
