import SwiftUI

struct CocoaPodsLibrary: @MainActor HashableIdentifiable {
    
    var id: String { name }
    
    let name: String
    let versions: [CocoaPodsLibraryVersion]
}

struct CocoaPodsLibraryVersion: @MainActor HashableIdentifiable {
    
    var id: URL { podspecPath }
    
    let name: String
    let library: String
    let source: CocoaPodsSource
    let podspecPath: URL
    let sourcePath: URL
}

enum CocoaPodsSource: String, Hashable, Identifiable, CaseIterable {
    
    var id: RawValue { rawValue }
    
    case external = "External"
    case release = "Release"
    
    var specsFolderName: String { rawValue }
    var sourceFolderName: String { rawValue }
}

protocol CocoaPodsServiceInterface: Sendable {
    
    func version() async -> String?
    func libraries() async -> [CocoaPodsLibrary]
    func podspec(for version: CocoaPodsLibraryVersion) async throws -> String
    func delete(_ version: CocoaPodsLibraryVersion) async throws
    func open(_ version: CocoaPodsLibraryVersion) async throws
    func size() async -> String?
}

actor CocoaPodsService: CocoaPodsServiceInterface {
    
    private let bashService: BashProvider.Type
    private let root = URL(fileURLWithPath: "/Users/\(NSUserName())/Library/Caches/CocoaPods/Pods", isDirectory: true)
    
    init(bashService: BashProvider.Type) {
        self.bashService = bashService
    }
    
    func version() async -> String? {
        let versionPath = root.appendingPathComponent("VERSION")
        guard FileManager.default.fileExists(atPath: versionPath.path) else {
            return nil
        }
        guard let raw = try? String(contentsOf: versionPath) else {
            return nil
        }
        return raw.components(separatedBy: .newlines).first?.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    func libraries() async -> [CocoaPodsLibrary] {
        let fileManager = FileManager.default
        var storage: [String: [CocoaPodsLibraryVersion]] = [:]
        for source in CocoaPodsSource.allCases {
            let specsRoot = await root
                .appendingPathComponent("Specs", isDirectory: true)
                .appendingPathComponent(source.specsFolderName, isDirectory: true)
            guard fileManager.fileExists(atPath: specsRoot.path) else {
                continue
            }
            let libraries = ((try? fileManager.contentsOfDirectory(atPath: specsRoot.path)) ?? [])
                .filter({ $0 != ".DS_Store" })
            let suffix = ".podspec.json"
            for library in libraries {
                let libraryPath = specsRoot.appendingPathComponent(library, isDirectory: true)
                let versions = ((try? fileManager.contentsOfDirectory(atPath: libraryPath.path)) ?? [])
                    .filter({ $0 != ".DS_Store" })
                    .filter({ $0.hasSuffix(suffix) })
                for file in versions {
                    let versionName = String(file.dropLast(suffix.count))
                    let podspecPath = libraryPath.appendingPathComponent(file)
                    let sourcePath = await root
                        .appendingPathComponent(source.sourceFolderName, isDirectory: true)
                        .appendingPathComponent(library, isDirectory: true)
                        .appendingPathComponent(versionName, isDirectory: true)
                    let item = CocoaPodsLibraryVersion(
                        name: versionName,
                        library: library,
                        source: source,
                        podspecPath: podspecPath,
                        sourcePath: sourcePath
                    )
                    storage[library, default: []].append(item)
                }
            }
        }
        return storage
            .map { name, items in
                CocoaPodsLibrary(
                    name: name,
                    versions: items.sorted(by: { $0.name < $1.name })
                )
            }
            .sorted(by: { $0.name < $1.name })
    }
    
    func podspec(for version: CocoaPodsLibraryVersion) async throws -> String {
        try String(contentsOf: version.podspecPath)
    }
    
    func delete(_ version: CocoaPodsLibraryVersion) async throws {
        do {
            if FileManager.default.fileExists(atPath: version.sourcePath.path) {
                try await bashService.rmDir(version.sourcePath)
            }
            if FileManager.default.fileExists(atPath: version.podspecPath.path) {
                try await bashService.rmFile(version.podspecPath)
            }
            try await removeLibraryIfNeeded(version)
        } catch {
            throw Errors.cli(error as? CliToolError ?? CliToolError.fs(error))
        }
    }
    
    func open(_ version: CocoaPodsLibraryVersion) async throws {
        try await bashService.open(version.sourcePath)
    }

    func size() async -> String? {
        guard FileManager.default.fileExists(atPath: root.path) else {
            return nil
        }
        return try? await bashService.size(root)
    }
    
    private func removeLibraryIfNeeded(_ version: CocoaPodsLibraryVersion) async throws {
        let fileManager = FileManager.default
        let librarySpecsPath = await root
            .appendingPathComponent("Specs", isDirectory: true)
            .appendingPathComponent(version.source.specsFolderName, isDirectory: true)
            .appendingPathComponent(version.library, isDirectory: true)
        let librarySourcePath = await root
            .appendingPathComponent(version.source.sourceFolderName, isDirectory: true)
            .appendingPathComponent(version.library, isDirectory: true)
        if fileManager.fileExists(atPath: librarySpecsPath.path) {
            let remainingSpecs = ((try? fileManager.contentsOfDirectory(atPath: librarySpecsPath.path)) ?? [])
                .filter({ $0 != ".DS_Store" })
                .filter({ $0.hasSuffix(".podspec.json") })
            if remainingSpecs.isEmpty {
                try await bashService.rmDir(librarySpecsPath)
            }
        }
        if fileManager.fileExists(atPath: librarySourcePath.path) {
            let remainingSources = ((try? fileManager.contentsOfDirectory(atPath: librarySourcePath.path)) ?? [])
                .filter({ $0 != ".DS_Store" })
            if remainingSources.isEmpty {
                try await bashService.rmDir(librarySourcePath)
            }
        }
    }
}

private final class CocoaPodsServiceEmpty: CocoaPodsServiceMock { }

class CocoaPodsServiceMock: CocoaPodsServiceInterface {
    static let shared = CocoaPodsServiceMock()
    func version() async -> String? { "1.16.2" }
    func libraries() async -> [CocoaPodsLibrary] { [] }
    func podspec(for version: CocoaPodsLibraryVersion) async throws -> String { "{}" }
    func delete(_ version: CocoaPodsLibraryVersion) async throws { }
    func open(_ version: CocoaPodsLibraryVersion) async throws { }
    func size() async -> String? { "1 Gb" }
    
    init() { }
}

extension EnvironmentValues {
    
    @Entry var cocoaPodsService: CocoaPodsServiceInterface = CocoaPodsServiceEmpty()
}

extension View {
    
    func withCocoaPodsService(_ cocoaPodsService: CocoaPodsServiceInterface) -> some View {
        environment(\.cocoaPodsService, cocoaPodsService)
    }
}

extension CocoaPodsService {
    
    enum Errors: Error {
        
        case cli(CliToolError)
    }
}
