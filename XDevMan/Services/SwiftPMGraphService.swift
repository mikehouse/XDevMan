import Foundation
import SwiftUI

protocol SwiftPMGraphServiceInterface: Sendable {

    func resolvePackageResolved(in directory: URL) async throws -> URL
    func packageWebURL(for identity: String, in graphs: [SwiftPMService.Graph]) async -> URL?
    func packageWebURL(for identity: String, location: String, revision: String?, exact: String?) async -> URL?
}

actor SwiftPMGraphService: SwiftPMGraphServiceInterface {

    private lazy var appLogger = AppLogger.current

    func resolvePackageResolved(in directory: URL) async throws -> URL {
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

    func packageWebURL(for identity: String, in graphs: [SwiftPMService.Graph]) async -> URL? {
        var stack = graphs
        while stack.isEmpty == false {
            let graph = stack.removeFirst()
            for dependency in graph.value.dependencies {
                guard let sourceControl = dependency.sourceControl?.first else {
                    continue
                }
                if sourceControl.identity == identity {
                    return await packageWebURL(sourceControl: sourceControl)
                }
            }
            stack.append(contentsOf: graph.dependencies)
        }
        return nil
    }

    func packageWebURL(for identity: String, location: String, revision: String?, exact: String?) async -> URL? {
        let sourceControl = SwiftPMService.Package.Dependency.SourceControl(
            identity: identity,
            location: .init(remote: [
                .init(urlString: location)
            ]),
            requirement: .init(range: nil, revision: revision.map { [$0] }, exact: exact.map { [$0] })
        )
        return await packageWebURL(sourceControl: sourceControl)
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

    private func packageWebURL(sourceControl: SwiftPMService.Package.Dependency.SourceControl) async -> URL? {
        func checkURLExists(url: URL) async -> Bool {
            var request = URLRequest(url: url)
            request.httpMethod = "HEAD"
            request.timeoutInterval = 5.0
            do {
                let (_, response) = try await URLSession.shared.data(for: request)
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 200 {
                        return true
                    }
                    appLogger?.warning("code \(httpResponse.statusCode) for \(url)")
                }
            } catch {
                appLogger?.error(error)
            }
            return false
        }
        let rules: [[WebPageAdjustment]] = [
            [],
            [.vAddToVersion],
            [.vRemoveFromVersion],
            [.keepExtension],
            [.vAddToVersion, .keepExtension],
            [.vRemoveFromVersion, .keepExtension],
        ]
        for rule in rules {
            if let url = packageWebURLBase(sourceControl: sourceControl, adjustment: rule) {
                if await checkURLExists(url: url) {
                    return url
                }
            }
        }
        return nil
    }

    private enum WebPageAdjustment: Equatable {
        case vRemoveFromVersion
        case vAddToVersion
        case keepExtension
    }

    private func packageWebURLBase(sourceControl: SwiftPMService.Package.Dependency.SourceControl, adjustment: [WebPageAdjustment]) -> URL? {
        guard
            let remote = sourceControl.location.remote.first?.urlString,
            var repo = normalizeRepositoryURL(remote, adjustment: adjustment)
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

        func adjustVersion(_ reference: String) -> String {
            var reference = reference
            for adjustment in adjustment {
                switch adjustment {
                case .vAddToVersion:
                    if !reference.hasPrefix("v") {
                        reference = "v\(reference)"
                    }
                case .vRemoveFromVersion:
                    if reference.hasPrefix("v") {
                        reference = String(reference.dropFirst(1))
                    }
                default:
                    break
                }
            }
            return reference
        }

        switch repo.host?.lowercased() {
        case "github.com":
            repo.append(path: "tree")
            repo.append(path: adjustVersion(reference))
            return repo
        case "gitlab.com":
            repo.append(path: "-")
            repo.append(path: "tree")
            repo.append(path: adjustVersion(reference))
            return repo
        default:
            repo.append(path: adjustVersion(reference))
            return repo
        }
    }

    private func normalizeRepositoryURL(_ raw: String, adjustment: [WebPageAdjustment]) -> URL? {
        if raw.hasPrefix("git@") {
            let trimmed = String(raw.dropFirst(4))
            let parts = trimmed.split(separator: ":", maxSplits: 1).map(String.init)
            guard parts.count == 2 else {
                return nil
            }
            return normalizeHTTPSURL(host: parts[0], path: parts[1], adjustment: adjustment)
        }

        if raw.hasPrefix("ssh://"), let components = URLComponents(string: raw), let host = components.host {
            return normalizeHTTPSURL(host: host, path: components.path, adjustment: adjustment)
        }

        guard let url = URL(string: raw) else {
            return nil
        }
        return normalizeHTTPSURL(host: url.host ?? "", path: url.path, adjustment: adjustment)
    }

    private func normalizeHTTPSURL(host: String, path: String, adjustment: [WebPageAdjustment]) -> URL? {
        guard host.isEmpty == false else {
            return nil
        }
        var normalizedPath = path
        if normalizedPath.hasPrefix("/") {
            normalizedPath.removeFirst()
        }
        if normalizedPath.hasSuffix(".git"), !adjustment.contains(.keepExtension) {
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
