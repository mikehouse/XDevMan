import SwiftUI

struct SwiftPMGraphView: View {

    let graph: SwiftPMService.Graph
    let graphs: [SwiftPMService.Graph]
    @Environment(\.swiftPMGraphService) private var swiftPMGraphService

    var body: some View {
        Group {
            if lines.isEmpty {
                NothingView(text: "No dependencies found.")
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                            HStack(spacing: 6) {
                                ForEach(Array(line.enumerated()), id: \.offset) { _, element in
                                    if element.isEmpty {
                                        Rectangle()
                                            .foregroundStyle(.clear)
                                            .frame(width: 36)
                                    } else {
                                        GraphNameView(identity: element, graphs: graphs)
                                    }
                                }
                                Spacer(minLength: 0)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                }
            }
        }
    }

    private var lines: [[String]] {
        graph
            .description
            .components(separatedBy: .newlines)
            .dropFirst()
            .map({ line in
                Array(line.components(separatedBy: graph.marker).dropFirst())
            })
    }
}

private struct GraphNameView: View {

    let identity: String
    let graphs: [SwiftPMService.Graph]
    @State private var version: String?
    @Environment(\.swiftPMGraphService) private var swiftPMGraphService

    var body: some View {
        Button(action: {
            openDependency(named: identity)
        }, label: {
            HStack {
                Text(identity)
                if let version = version {
                    Text(version)
                }
            }
        })
        .buttonStyle(.borderedProminent)
        .task {
            if let first = graphs.first(where: { $0.graph(name: identity) != nil }),
               let graph = first.graph(name: identity) {
                if let version = graph.value.version {
                    self.version = version
                } else if let revision = graph.value.revision {
                    self.version = String(revision.prefix(8))
                }
            }
        }
    }

    private func openDependency(named name: String) {
        Task {
            if let url = await swiftPMGraphService.packageWebURL(for: name, in: graphs) {
                NSWorkspace.shared.open(url)
            }
        }
    }
}

#Preview {
    SwiftPMGraphPreviewContainer()
        .frame(width: 620, height: 420)
        .withAppMocks()
}

private struct SwiftPMGraphPreviewContainer: View {

    @State private var graphs: [SwiftPMService.Graph] = []

    var body: some View {
        Group {
            if let graph = graphs.first {
                SwiftPMGraphView(graph: graph, graphs: graphs)
            } else {
                ProgressView()
            }
        }
        .task {
            if graphs.isEmpty {
                graphs = await SwiftPMGraphPreviewData.sampleGraphs()
            }
        }
    }
}

private enum SwiftPMGraphPreviewData {

    static func sampleGraphs() async -> [SwiftPMService.Graph] {
        let swiftPMService = SwiftPMService(bashService: BashProviderMock.self)
        let packages: [SwiftPMService.Package] = [
            .init(name: "swift-navigation", dependencies: [
                dependency(identity: "swift-collections", remote: "https://github.com/apple/swift-collections.git", version: "1.1.0"),
                dependency(identity: "swift-case-paths", remote: "https://github.com/pointfreeco/swift-case-paths.git", version: "1.5.0"),
            ]),
            .init(name: "swift-collections", dependencies: []),
            .init(name: "swift-case-paths", dependencies: [
                dependency(identity: "swift-benchmark", remote: "https://github.com/apple/swift-benchmark.git", revision: "main")
            ]),
            .init(name: "swift-benchmark", dependencies: []),
        ]
        return await swiftPMService.graphs(packages)
    }

    static func dependency(
        identity: String,
        remote: String,
        revision: String? = nil,
        version: String? = nil
    ) -> SwiftPMService.Package.Dependency {
        let sourceControl = SwiftPMService.Package.Dependency.SourceControl(
            identity: identity,
            location: .init(remote: [.init(urlString: remote)]),
            requirement: .init(
                range: version.map({ [.init(lowerBound: $0)] }),
                revision: revision.map({ [$0] }),
                exact: version.map({ [$0] })
            )
        )
        return .init(sourceControl: [sourceControl])
    }
}
