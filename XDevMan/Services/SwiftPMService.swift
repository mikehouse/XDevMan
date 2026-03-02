import SwiftUI

protocol SwiftPMServiceInterface: Sendable {

    func buildGraph(resolvedPath: URL, progress: @Sendable ((total: Int, current: Int, name: String)) -> Void) async throws -> [SwiftPMService.Graph]
}

actor SwiftPMService: SwiftPMServiceInterface {

    private let bashService: BashProvider.Type

    init(bashService: BashProvider.Type) {
        self.bashService = bashService
    }

    func buildGraph(resolvedPath: URL, progress: @Sendable ((total: Int, current: Int, name: String)) -> Void) async throws -> [Graph] {
        let packageResolved = try parse(resolvedPath: resolvedPath)
        let packages = packageResolved.pins.map({
            PackageShortInfo.init(
                identity: $0.identity,
                location: $0.location,
                revision: $0.state.revision,
                version: $0.state.version
            )
        })
        var storage: [Package] = []
        var counter = 0
        await traverse(packages: packages, storage: &storage, resolved: packageResolved, counter: &counter, progress: progress)
        let graphs = graphs(storage)
        return graphs
    }

    func graphs(_ packages: [Package]) -> [Graph] {
        var packages = packages
        let originPackages = packages

        while true {
            var repeatedPackages: [SwiftPMService.Package] = []
            for package in packages {
                for packageLoop in packages where package.name != packageLoop.name && package.dependencies.isEmpty {
                    if packageLoop.dependencies.contains(where: { package.name == $0.sourceControl!.first!.identity }) {
                        if !repeatedPackages.contains(where: { $0.name == package.name }) {
                            repeatedPackages.append(package)
                        }
                    }
                }
            }
            if repeatedPackages.isEmpty {
                break
            }
            packages.removeAll(where: { p in repeatedPackages.contains(where: { $0.name == p.name }) })
            packages = packages.map({ package in
                let remove = repeatedPackages.map(\.name)
                return SwiftPMService.Package(
                    name: package.name,
                    dependencies: package.dependencies.filter({ !remove.contains($0.sourceControl![0].identity) })
                )
            })
        }

        packages = packages.compactMap({ p -> SwiftPMService.Package? in
            originPackages.first(where: { b in b.name == p.name })
        })

        let graphRoots: [Graph] = packages.map({ Graph(value: $0) })

        var graphs = graphRoots

        while true {
            var notAdded = true

            for graph in graphs {
                for dependency in graph.value.dependencies {
                    if let package = originPackages.first(where: { $0.name == dependency.sourceControl![0].identity }) {
                        graph.dependencies.append(.init(value: package))
                        notAdded = false
                    }
                }
            }

            graphs = graphs.flatMap(\.dependencies)

            if notAdded {
                break
            }
        }
        return graphRoots
    }

    private func traverse(packages: [PackageShortInfo], storage: inout [Package], resolved: PackageResolved, counter: inout Int, progress: ((total: Int, current: Int, name: String)) -> Void) async {
        for pin in packages {
            let name = pin.identity
            do {
                let urlComponents = URLComponents(string: pin.location)
                guard var urlComponents else {
                    continue
                }
                let packageURL: URL?
                switch urlComponents.host {
                case "github.com":
                    urlComponents.host = "raw.githubusercontent.com"
                    if let revision = pin.revision {
                        packageURL = urlComponents.url?.deletingPathExtension().appendingPathComponent("/\(revision)/Package.swift")
                    } else if let version = pin.version {
                        packageURL = urlComponents.url?.deletingPathExtension().appendingPathComponent("refs/tags/\(version)/Package.swift")
                    } else {
                        packageURL = nil
                    }
                case "gitlab.com":
                    if let subpath = pin.revision ?? pin.version {
                        packageURL = urlComponents.url?.deletingPathExtension().appendingPathComponent("/-/raw/\(subpath)/Package.swift")
                    } else {
                        packageURL = nil
                    }
                default:
                    packageURL = nil
                }
                guard let packageURL else {
                    continue
                }
                let packageDir = FileManager.default.temporaryDirectory
                    .appendingPathComponent(name)
                    .appendingPathComponent(pin.revision ?? pin.version ?? "")
                if !FileManager.default.fileExists(atPath: packageDir.path) {
                    try FileManager.default.createDirectory(at: packageDir, withIntermediateDirectories: true)
                }
                let packagePath = packageDir
                    .appendingPathComponent("Package.swift")
                if !FileManager.default.fileExists(atPath: packagePath.path) {
                    let content = try Data(contentsOf: packageURL)
                    try content.write(to: packagePath, options: .atomicWrite)
                }
                let jsonString = try await CliTool.exec("/usr/bin/xcrun", arguments: ["swift", "package", "dump-package", "--package-path", packagePath.deletingLastPathComponent().path])
                let jsonData = jsonString.data(using: .utf8)!
                var package = try JSONDecoder().decode(Package.self, from: jsonData)
                package.name = pin.identity
                package.location = pin.location
                package.revision = pin.revision
                package.version = pin.version

                if storage.contains(where: { $0.name == package.name }) {
                    continue
                }

                storage.append(package)

                if resolved.pins.contains(where: { $0.identity == pin.identity }) {
                    counter += 1
                    progress((total: resolved.pins.count, current: counter, name: pin.identity))
                }

                let next: [PackageShortInfo] = package.dependencies.flatMap({ dependency -> [PackageShortInfo] in
                    dependency.sourceControl?.compactMap({ sourceControl -> PackageShortInfo? in
                        PackageShortInfo.init(
                            identity: sourceControl.identity,
                            location: sourceControl.location.remote[0].urlString,
                            revision: sourceControl.requirement.revision?.last,
                            version: sourceControl.requirement.exact?.last ?? sourceControl.requirement.range?.last?.lowerBound
                        )
                    }) ?? []
                })

                await traverse(packages: next, storage: &storage, resolved: resolved, counter: &counter, progress: progress)
            } catch {
                AppLogger.shared.error(error)
                if resolved.pins.contains(where: { $0.identity == pin.identity }) {
                    counter += 1
                    progress((total: resolved.pins.count, current: counter, name: pin.identity))
                }
            }
        }
    }

    struct Package: Decodable {
        var name: String
        var location: String?
        var revision: String?
        var version: String?
        let dependencies: [Dependency]

        struct Dependency: Decodable {
            let sourceControl: [SourceControl]?

            struct SourceControl: Decodable {
                let identity: String
                let location: Location
                let requirement: Requirement

                struct Location: Decodable {
                    let remote: [Remote]

                    struct Remote: Decodable {
                        let urlString: String
                    }
                }

                struct Requirement: Decodable {
                    let range: [Range]?
                    let revision: [String]?
                    let exact: [String]?

                    struct Range: Decodable {
                        let lowerBound: String
                    }
                }
            }
        }
    }

    nonisolated final class Graph: CustomStringConvertible, Sendable, @MainActor HashableIdentifiable {

        let marker = " -> "

        let value: Package
        nonisolated(unsafe) fileprivate(set) var dependencies: [Graph] = []

        init(value: Package) {
            self.value = value
        }

        var id: String { "\(value.name)" }

        /// - returns multiline graph string like this:
        /// swift-navigation
        ///  -> swift-collections
        ///  -> swift-docc-plugin
        ///  -> swift-case-paths
        ///  ->  -> swift-benchmark
        ///  ->  ->  -> swift-argument-parser
        ///  ->  -> xctest-dynamic-overlay
        ///  ->  ->  -> swift-docc-plugin
        ///  ->  ->  -> carton
        ///  ->  ->  ->  -> swift-log
        ///  ->  ->  ->  ->  -> swift-docc-plugin
        ///  ->  ->  ->  -> swift-argument-parser
        ///  ->  ->  ->  -> swift-nio
        ///  ->  ->  ->  -> wasmtransformer
        ///  ->  ->  ->  ->  -> swift-argument-parser
        ///  ->  -> swift-docc-plugin
        ///  -> swift-concurrency-extras
        ///  ->  -> swift-docc-plugin

        var description: String {
            toString()
        }

        nonisolated(unsafe) private var nameCache: [String: Graph] = [:]

        func graph(name: String) -> Graph? {
            if let cached = nameCache[name] {
                return cached
            }
            if value.name == name {
                return self
            }
            for dep in self.dependencies {
                if let graph = dep.graph(name: name) {
                    nameCache[name] = graph
                    return graph
                }
            }
            return nil
        }

        private func toString() -> String {
            var buffer = [value.name]
            toString(dependencies: dependencies, count: 1, buffer: &buffer)
            return buffer.joined(separator: "\n")
        }

        private func toString(dependencies: [Graph], count: Int, buffer: inout [String]) {
            for dep in dependencies {
                buffer.append("\(String(repeating: marker, count: count))\(dep.value.name)")
                toString(dependencies: dep.dependencies, count: count + 1, buffer: &buffer)
            }
        }
    }

    private struct PackageShortInfo {
        let identity: String
        let location: String
        let revision: String?
        let version: String?
    }
}

private extension SwiftPMService {

    struct PackageResolved: Decodable {
        let pins: [Pin]
        let version: Int

        struct Pin: Decodable {
            let identity: String
            let kind: String
            let location: String
            let state: State

            struct State: Decodable {
                let revision: String
                let version: String?
                let branch: String?
            }
        }
    }

    func parse(resolvedPath: URL) throws -> PackageResolved {
        return try JSONDecoder().decode(PackageResolved.self, from: Data(contentsOf: resolvedPath))
    }
}

private final class SwiftPMServiceEmpty: SwiftPMServiceMock { }

class SwiftPMServiceMock: SwiftPMServiceInterface {
    static let shared = SwiftPMServiceMock()
    init() { }
    func buildGraph(resolvedPath: URL, progress: @Sendable ((total: Int, current: Int, name: String)) -> Void) async throws -> [SwiftPMService.Graph] { [] }
}

extension EnvironmentValues {

    @Entry var swiftPMService: SwiftPMServiceInterface = SwiftPMServiceEmpty()
}

extension View {

    func withSwiftPMService(_ swiftPMService: SwiftPMServiceInterface) -> some View {
        environment(\.swiftPMService, swiftPMService)
    }
}
