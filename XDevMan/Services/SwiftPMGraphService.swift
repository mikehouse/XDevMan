import Foundation
import SwiftUI

protocol SwiftPMGraphServiceInterface: Sendable {

    func resolvePackageResolved(in directory: URL) async throws -> URL
    func packageWebURL(for identity: String, in graphs: [SwiftPMService.Graph]) async -> URL?
    func packageWebURL(for identity: String, location: String, revision: String?, exact: String?) async -> URL?
}

actor SwiftPMGraphService: SwiftPMGraphServiceInterface {

    func resolvePackageResolved(in directory: URL) throws -> URL {
        let fileManager = FileManager.default
        let rootResolved = directory.appendingPathComponent("Package.resolved", isDirectory: false)
        if fileManager.fileExists(atPath: rootResolved.path) {
            return rootResolved
        }

        let entries = (try? fileManager.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        )) ?? []
        let xcodeProjects = entries
            .filter({ $0.pathExtension == "xcodeproj" })

        for project in xcodeProjects {
            let resolved = project
                .appendingPathComponent("project.xcworkspace", isDirectory: true)
                .appendingPathComponent("xcshareddata", isDirectory: true)
                .appendingPathComponent("swiftpm", isDirectory: true)
                .appendingPathComponent("Package.resolved", isDirectory: false)
            if fileManager.fileExists(atPath: resolved.path) {
                return resolved
            }
        }

        throw Errors.packageResolvedNotFound
    }

    func packageWebURL(for identity: String, in graphs: [SwiftPMService.Graph]) -> URL? {
        var stack = graphs
        while stack.isEmpty == false {
            let graph = stack.removeFirst()
            for dependency in graph.value.dependencies {
                guard let sourceControl = dependency.sourceControl?.first else {
                    continue
                }
                if sourceControl.identity == identity {
                    return packageWebURL(sourceControl: sourceControl)
                }
            }
            stack.append(contentsOf: graph.dependencies)
        }
        return nil
    }

    func packageWebURL(for identity: String, location: String, revision: String?, exact: String?) -> URL? {
        let sourceControl = SwiftPMService.Package.Dependency.SourceControl(
            identity: identity,
            location: .init(remote: [
                .init(urlString: location)
            ]),
            requirement: .init(range: nil, revision: revision.map { [$0] }, exact: exact.map { [$0] })
        )
        return packageWebURL(sourceControl: sourceControl)
    }
}

extension SwiftPMGraphService {

    private enum Errors: LocalizedError {

        case packageResolvedNotFound

        var errorDescription: String? {
            switch self {
            case .packageResolvedNotFound:
                return "Unable to find Package.resolved in the selected folder."
            }
        }
    }

    private func packageWebURL(sourceControl: SwiftPMService.Package.Dependency.SourceControl) -> URL? {
        guard
            let remote = sourceControl.location.remote.first?.urlString,
            var repo = normalizeRepositoryURL(remote)
        else {
            return nil
        }

        let reference =
            sourceControl.requirement.revision?.last ??
            sourceControl.requirement.exact?.last ??
            sourceControl.requirement.range?.last?.lowerBound
        guard let reference else {
            return repo
        }

        switch repo.host?.lowercased() {
        case "github.com":
            repo.append(path: "tree")
            repo.append(path: reference)
            return repo
        case "gitlab.com":
            repo.append(path: "-")
            repo.append(path: "tree")
            repo.append(path: reference)
            return repo
        default:
            repo.append(path: reference)
            return repo
        }
    }

        func normalizeRepositoryURL(_ raw: String) -> URL? {
        if raw.hasPrefix("git@") {
            let trimmed = String(raw.dropFirst(4))
            let parts = trimmed.split(separator: ":", maxSplits: 1).map(String.init)
            guard parts.count == 2 else {
                return nil
            }
            return normalizeHTTPSURL(host: parts[0], path: parts[1])
        }

        if raw.hasPrefix("ssh://"), let components = URLComponents(string: raw), let host = components.host {
            return normalizeHTTPSURL(host: host, path: components.path)
        }

        guard let url = URL(string: raw) else {
            return nil
        }
        return normalizeHTTPSURL(host: url.host ?? "", path: url.path)
    }

    func normalizeHTTPSURL(host: String, path: String) -> URL? {
        guard host.isEmpty == false else {
            return nil
        }
        var normalizedPath = path
        if normalizedPath.hasPrefix("/") {
            normalizedPath.removeFirst()
        }
        if normalizedPath.hasSuffix(".git") {
            normalizedPath = String(normalizedPath.dropLast(4))
        }
        return URL(string: "https://\(host)/\(normalizedPath)")
    }
}

private final class SwiftPMGraphServiceEmpty: SwiftPMGraphServiceMock { }

class SwiftPMGraphServiceMock: SwiftPMGraphServiceInterface {
    static let shared = SwiftPMGraphServiceMock()
    init() { }
    func resolvePackageResolved(in directory: URL) async throws -> URL { directory.appendingPathComponent("Package.resolved") }
    func packageWebURL(for identity: String, location: String, revision: String?, exact: String?) -> URL? { nil }
    func packageWebURL(for identity: String, in graphs: [SwiftPMService.Graph]) async -> URL? { nil }
}

extension EnvironmentValues {

    @Entry var swiftPMGraphService: SwiftPMGraphServiceInterface = SwiftPMGraphServiceEmpty()
}

extension View {

    func withSwiftPMGraphService(_ swiftPMGraphService: SwiftPMGraphServiceInterface) -> some View {
        environment(\.swiftPMGraphService, swiftPMGraphService)
    }
}
