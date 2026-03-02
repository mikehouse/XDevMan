import SwiftUI
import UniformTypeIdentifiers

struct SwiftPMGraphListView: View {

    @Binding var selectedGraph: SwiftPMService.Graph?
    @Binding var graphs: [SwiftPMService.Graph]
    @Environment(\.swiftPMGraphService) private var swiftPMGraphService
    @Environment(\.swiftPMService) private var swiftPMService
    @Environment(\.alertHandler) private var alertHandler
    @Environment(\.appLogger) private var appLogger
    @State private var fileImporterIsPresented = false
    @State private var selectedDirectory: URL?
    @State private var isLoading = false
    @State private var progressTotal = 0
    @State private var progressCurrent = 0
    @State private var progressName = ""
    @State private var version: String?

    var body: some View {
        Group {
            if isLoading {
                progressView
            } else if graphs.isEmpty == false {
                List(graphs, id: \.self, selection: $selectedGraph) { graph in
                    HStack {
                        Text(graph.value.name)
                        Spacer()
                        Button.init(action: {
                            openDependency(graph: graph)
                        }, label: {
                            Image(systemName: "safari")
                                .resizable()
                                .frame(width: 16, height: 16)
                        })
                        .buttonStyle(.borderless)
                    }
                    .tag(graph)
                    .modifier(ListItemViewPaddingModifier())
                }
            } else if selectedDirectory == nil {
                VStack(spacing: 16) {
                    openButton
                    NothingView(text: "Select an Xcode project folder.")
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                NothingView(text: "No dependencies found.")
            }
        }
        .navigationTitle(navTitle)
        .toolbar {
            ToolbarItem(id: "spm-graph-select") {
                openButton
            }
            if let selectedDirectory {
                ToolbarItem(id: "spm-graph-open") {
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
                alertHandler.handle(title: "Folder import error", message: nil, error: failure)
                appLogger.error(failure)
            }
        }
        .onDisappear {
            selectedGraph = nil
            graphs = []
            selectedDirectory = nil
            resetProgress()
        }
        .onChange(of: selectedGraph) {
            version = selectedGraph?.value.version
        }
    }

    private var navTitle: String {
        if let selectedGraph {
            return "\(selectedGraph.value.name) \(selectedGraph.value.version ?? selectedGraph.value.revision.map({ String($0.prefix(8)) }) ?? "")"
        } else {
            return "SwiftPM Graph"
        }
    }

    private var openButton: some View {
        Button {
            fileImporterIsPresented = true
        } label: {
            Image(systemName: "folder.badge.plus")
        }
        .buttonStyle(.toolbarDefault)
    }

    private func openDependency(graph: SwiftPMService.Graph) {
        Task {
            if let location = graph.value.location, let url = await swiftPMGraphService.packageWebURL(
                for: graph.value.name,
                location: location,
                revision: graph.value.revision,
                exact: graph.value.version
            ) {
                NSWorkspace.shared.open(url)
            }
        }
    }

    private var progressView: some View {
        VStack(spacing: 14) {
            if progressTotal > 0 {
                ProgressView(value: Double(progressCurrent), total: Double(progressTotal))
                Text("\(progressCurrent) / \(progressTotal)")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            } else {
                ProgressView()
            }
            if progressName.isEmpty == false {
                Text(progressName)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    private func scan(_ directory: URL) async {
        isLoading = true
        selectedGraph = nil
        graphs = []
        selectedDirectory = directory
        resetProgress()
        defer {
            isLoading = false
        }
        do {
            let resolvedPath = try await swiftPMGraphService.resolvePackageResolved(in: directory)
            let resolvedGraphs = try await swiftPMService.buildGraph(resolvedPath: resolvedPath) { status in
                Task { @MainActor in
                    progressTotal = status.total
                    progressCurrent = status.current
                    progressName = status.name
                }
            }
            graphs = resolvedGraphs
        } catch {
            appLogger.error(error)
            alertHandler.handle(title: "SwiftPM graph error", message: nil, error: error)
        }
    }

    private func resetProgress() {
        progressTotal = 0
        progressCurrent = 0
        progressName = ""
    }
}

#Preview {
    SwiftPMGraphListPreviewContainer()
        .frame(width: 320, height: 360)
        .withAppMocks()
}

private struct SwiftPMGraphListPreviewContainer: View {

    @State private var selectedGraph: SwiftPMService.Graph?
    @State private var graphs: [SwiftPMService.Graph] = []

    var body: some View {
        SwiftPMGraphListView(
            selectedGraph: $selectedGraph,
            graphs: $graphs
        )
    }
}
