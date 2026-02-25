import SwiftUI
import UniformTypeIdentifiers

struct FastlaneListView: View {
    
    @Binding var selectedLane: FastlaneLane?
    @Binding var commandDirectory: URL?
    @Environment(\.fastlaneService) private var fastlaneService
    @Environment(\.appLogger) private var appLogger
    @Environment(\.alertHandler) private var alertHandler
    @State private var fileImporterIsPresented = false
    @State private var lanes: [FastlaneLane] = []
    @State private var selectedDirectory: URL?
    @State private var isLoading = false
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView()
            } else if lanes.isEmpty == false {
                List(lanes, id: \.self, selection: $selectedLane) { lane in
                    Text(lane.name)
                        .tag(lane)
                        .modifier(ListItemViewPaddingModifier())
                }
            } else {
                VStack(spacing: 16) {
                    openButton
                    NothingView(text: "Select a fastlane directory.")
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle("Fastlane")
        .toolbar {
            ToolbarItem(id: "fastlane-select") {
                openButton
            }
            if let selectedDirectory {
                ToolbarItem(id: "fastlane-open") {
                    BashOpenView(path: .url(selectedDirectory), type: .toolbarFolder)
                }
            }
        }
        .fileImporter(
            isPresented: $fileImporterIsPresented,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let selection):
                guard let directory = selection.first else {
                    return
                }
                Task {
                    await scan(directory)
                }
            case .failure(let failure):
                alertHandler.handle(title: "File Import error", message: nil, error: failure)
                appLogger.error(failure)
            }
        }
        .onDisappear {
            selectedLane = nil
            commandDirectory = nil
        }
    }
    
    private var openButton: some View {
        Button {
            fileImporterIsPresented = true
        } label: {
            VStack {
                Image(systemName: "folder.badge.plus")
            }
        }
        .buttonStyle(.toolbarDefault)
    }
    
    private func scan(_ directory: URL) async {
        isLoading = true
        selectedLane = nil
        defer {
            isLoading = false
        }
        do {
            let result = try await fastlaneService.scan(directory)
            lanes = result.lanes
            selectedDirectory = result.selectedDirectory
            commandDirectory = result.commandDirectory
        } catch {
            lanes = []
            selectedDirectory = nil
            commandDirectory = nil
            appLogger.error(error)
            alertHandler.handle(title: "Directory error", message: nil, error: error)
        }
    }
}

#Preview {
    FastlaneListView(
        selectedLane: .constant(nil),
        commandDirectory: .constant(nil)
    )
        .frame(width: 400, height: 300)
        .withFastlaneService(FastlaneServiceMockImpl())
        .withAppMocks()
}

private final class FastlaneServiceMockImpl: FastlaneServiceMock {
    
    override func scan(_ selectedDirectory: URL) async throws -> FastlaneScanResult {
        .init(selectedDirectory: selectedDirectory, fastlaneDirectory: selectedDirectory, commandDirectory: selectedDirectory, lanes: [
            .init(name: "make_ipa", inputs: []),
            .init(name: "ios crowdin_upload", inputs: [
                .init(name: "verbose", type: .bool),
                .init(name: "slack", type: .bool)
            ])
        ])
    }
}
