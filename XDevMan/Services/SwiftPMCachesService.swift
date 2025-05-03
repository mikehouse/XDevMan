
import SwiftUI

typealias SwiftPMCachesRepository = SwiftPMCachesService.Repository

@MainActor
protocol SwiftPMCachesServiceInterface: Sendable {
    
    nonisolated func path() -> URL
    nonisolated func exists() async -> Bool
    nonisolated func size() async throws -> String
    nonisolated func repositories() async -> [SwiftPMCachesRepository]
    nonisolated func delele(_ repository: SwiftPMCachesRepository) async throws
}

final class SwiftPMCachesService: SwiftPMCachesServiceInterface {
    
    private let root: URL = URL(fileURLWithPath: "/Users/\(NSUserName())/Library/Caches/org.swift.swiftpm/repositories", isDirectory: true)
    private var bashService: BashProvider.Type
    
    init(bashService: BashProvider.Type) {
        self.bashService = bashService
    }
    
    func path() -> URL { root }
    
    func exists() async -> Bool {
        FileManager.default.fileExists(atPath: root.path)
    }
    
    func size() async throws -> String {
        try await bashService.size(root)
    }
    
    func repositories() async -> [Repository] {
        let task = Task<[Repository], Never>(priority: .high) { [self] in
            guard FileManager.default.fileExists(atPath: root.path) else {
                return []
            }
            let list = ((try? FileManager.default.contentsOfDirectory(atPath: root.path)) ?? [])
                .filter({ $0.contains("-") })
                .sorted()
            return list.map { child in
                Repository(
                    path: root.appending(path: child),
                    name: valueSplitingByLast(child),
                    hash: String(child.dropFirst(valueSplitingByLast(child).count + 1))
                )
            }
        }
        return await task.value
    }
    
    func delele(_ repository: SwiftPMCachesRepository) async throws {
        let task = Task<Void, Error>(priority: .high) { [self] in
            try await bashService.rmDir(repository.path)
            if await repositories().map(\.name).filter({ $0 == repository.name }).isEmpty {
                let manifest = root.deletingLastPathComponent()
                    .appendingPathComponent("manifests", isDirectory: true)
                    .appendingPathComponent("ManifestLoading", isDirectory: true)
                    .appendingPathComponent(repository.name.lowercased(), isDirectory: false)
                    .appendingPathExtension("dia")
                let fingerprints = root.deletingLastPathComponent()
                    .deletingLastPathComponent()
                    .appendingPathComponent("security", isDirectory: true)
                    .appendingPathComponent("fingerprints", isDirectory: true)
                let list = ((try? FileManager.default.contentsOfDirectory(atPath: fingerprints.path)) ?? [])
                    .filter({ valueSplitingByLast($0) == repository.name.lowercased() })
                    .map({ fingerprints.appendingPathComponent($0, isDirectory: false) })
                await withTaskGroup(of: Void.self) { [self] group in
                    if FileManager.default.fileExists(atPath: manifest.path) {
                        group.addTask { [self] in
                            try? await bashService.rmFile(manifest)
                        }
                    }
                    for fingerprint in list {
                        group.addTask { [self] in
                            try? await bashService.rmFile(fingerprint)
                        }
                    }
                    await group.waitForAll()
                }
            }
        }
        do {
            try await task.value
        } catch {
            throw Errors.cli(error as? CliToolError ?? CliToolError.fs(error))
        }
    }
    
    nonisolated private func valueSplitingByLast(_ value: String, symbol: String = "-") -> String {
        value.components(separatedBy: symbol).dropLast().joined(separator: symbol)
    }
    
    enum Errors: Error {
        
        case cli(CliToolError)
    }
}

private final class SwiftPMCachesServiceEmpty: SwiftPMCachesServiceMock { }

class SwiftPMCachesServiceMock: SwiftPMCachesServiceInterface {
    static let shared = SwiftPMCachesServiceMock()
    func path() -> URL { URL(fileURLWithPath: "/") }
    func exists() async -> Bool { false }
    func size() async throws -> String { "" }
    func repositories() async -> [SwiftPMCachesService.Repository] { [] }
    func delele(_ repository: SwiftPMCachesRepository) async throws { }
}

extension EnvironmentValues {
    
    @Entry var swiftPMCachesService: SwiftPMCachesServiceInterface = SwiftPMCachesServiceEmpty()
}

extension View {
    
    func withSwiftPMCachesService(_ swiftPMCachesService: SwiftPMCachesServiceInterface) -> some View {
        environment(\.swiftPMCachesService, swiftPMCachesService)
    }
}

extension SwiftPMCachesService {
    
    struct Repository: HashableIdentifiable {
        
        var id: String { path.path }
        
        let path: URL
        let name: String
        let hash: String
    }
}
