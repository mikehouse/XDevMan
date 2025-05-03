
import SwiftUI

struct CarthageItem: HashableIdentifiable {
    
    var id: URL { path }
    
    let name: String
    let path: URL
    let hasGit: Bool
    let source: CarthageSource
}

enum CarthageSource: String, Hashable, Identifiable, CaseIterable {
    
    var id: RawValue { rawValue }
    
    case dependencies = "Dependencies"
    case binaries = "Binaries"
    case derivedData = "DerivedData"
}

struct CarthageDerivedData: HashableIdentifiable {
    
    var id: String { "\(xcode) \(items.count)" }
    
    let xcode: String
    let items: [CarthageDerivedDataItem]
}

struct CarthageDerivedDataItem: HashableIdentifiable {
    
    var id: URL { path }
    
    let name: String
    let version: String
    let path: URL
    let source = CarthageSource.derivedData
}

@MainActor
protocol CarthageServiceInteface: Sendable {
    
    nonisolated func dependencies() async -> [CarthageItem]
    nonisolated func binaries() async -> [CarthageItem]
    nonisolated func derivedData() async -> [CarthageDerivedData]
    nonisolated func exists() -> Bool
    nonisolated func exists(_ source: CarthageSource) -> Bool
    nonisolated func size() async throws -> String
    nonisolated func size(_ item: CarthageItem) async throws -> String
    nonisolated func size(_ item: CarthageDerivedDataItem) async throws -> String
    nonisolated func size(_ source: CarthageSource) async throws -> String
    nonisolated func delete(_ item: CarthageItem) async throws
    nonisolated func delete(_ item: CarthageDerivedDataItem) async throws
    nonisolated func open(_ source: CarthageSource) async throws
}

final class CarthageService: CarthageServiceInteface {
    
    private let bashService: BashProvider.Type
    private let root = URL(fileURLWithPath: "/Users/\(NSUserName())/Library/Caches/org.carthage.CarthageKit", isDirectory: true)
    
    init(bashService: BashProvider.Type) {
        self.bashService = bashService
    }
    
    var rootPath: URL { root }
    
    func size() async throws -> String {
        try await bashService.size(root)
    }
    
    func size(_ item: CarthageItem) async throws -> String {
        try await bashService.size(item.path)
    }
    
    func size(_ source: CarthageSource) async throws -> String {
        try await bashService.size(path(for: source))
    }
    
    func size(_ item: CarthageDerivedDataItem) async throws -> String {
        try await bashService.size(item.path)
    }
    
    func exists() -> Bool {
        FileManager.default.fileExists(atPath: root.path)
    }
    
    func exists(_ source: CarthageSource) -> Bool {
        FileManager.default.fileExists(atPath: path(for: source).path)
    }
    
    func open(_ source: CarthageSource) async throws {
        return try await bashService.open(path(for: source))
    }
    
    func derivedData() async -> [CarthageDerivedData] {
        let task = Task<[CarthageDerivedData], Never>(priority: .high) { [self] in
            let fileManager = FileManager.default
            let derivedData = root.appendingPathComponent("DerivedData", isDirectory: true)
            guard fileManager.fileExists(atPath: derivedData.path) else {
                return []
            }
            return ((try? fileManager.contentsOfDirectory(atPath: derivedData.path)) ?? [])
                .filter({ $0 != ".DS_Store" })
                .map({ xcode -> CarthageDerivedData in
                    let sdk = derivedData.appendingPathComponent(xcode, isDirectory: true)
                    let items = ((try? fileManager.contentsOfDirectory(atPath: sdk.path)) ?? [])
                        .filter({ $0 != ".DS_Store" })
                        .map({ name -> [CarthageDerivedDataItem] in
                            let lib = sdk.appendingPathComponent(name, isDirectory: true)
                            return ((try? fileManager.contentsOfDirectory(atPath: lib.path)) ?? [])
                                .filter({ $0 != ".DS_Store" })
                                .map({ version -> CarthageDerivedDataItem in
                                    let path = lib.appendingPathComponent(version, isDirectory: true)
                                    return CarthageDerivedDataItem(name: name, version: version, path: path)
                                })
                        })
                        .flatMap({ $0 })
                    return CarthageDerivedData(xcode: xcode, items: items)
                })
        }
        return await task.value
    }
    
    func dependencies() async -> [CarthageItem] {
        let task = Task<[CarthageItem], Never>(priority: .high) { [self] in
            let fileManager = FileManager.default
            let dependencies = root.appendingPathComponent("dependencies", isDirectory: true)
            guard fileManager.fileExists(atPath: dependencies.path) else {
                return []
            }
            return ((try? fileManager.contentsOfDirectory(atPath: dependencies.path)) ?? [])
                .filter({ $0 != ".DS_Store" })
                .map({ name -> CarthageItem in
                    CarthageItem(
                        name: name,
                        path: dependencies.appendingPathComponent(name, isDirectory: true),
                        hasGit: true,
                        source: .dependencies
                    )
                })
                .sorted(by: { $0.name < $1.name })
        }
        return await task.value
    }
    
    func binaries() async -> [CarthageItem] {
        let task = Task<[CarthageItem], Never>(priority: .high) { [self] in
            let fileManager = FileManager.default
            let binaries = root.appendingPathComponent("binaries", isDirectory: true)
            guard fileManager.fileExists(atPath: binaries.path) else {
                return []
            }
            return ((try? fileManager.contentsOfDirectory(atPath: binaries.path)) ?? [])
                .filter({ $0 != ".DS_Store" })
                .map({ name -> [CarthageItem] in
                    let sub = binaries.appendingPathComponent(name, isDirectory: true)
                    return ((try? fileManager.contentsOfDirectory(atPath: sub.path)) ?? [])
                        .filter({ $0 != ".DS_Store" })
                        .map({ version -> CarthageItem in
                            CarthageItem(
                                name: "\(name) (\(version))",
                                path: sub.appendingPathComponent(version, isDirectory: true),
                                hasGit: false,
                                source: .binaries
                            )
                        })
                })
                .flatMap({ $0 })
                .sorted(by: { $0.name < $1.name })
        }
        return await task.value
    }
    
    func delete(_ item: CarthageItem) async throws {
        try await delete(item: item.path)
    }
    
    func delete(_ item: CarthageDerivedDataItem) async throws {
        try await delete(item: item.path)
    }
    
    private func delete(item path: URL) async throws {
        let parent = path.deletingLastPathComponent()
        if ((try? FileManager.default.contentsOfDirectory(atPath: parent.path)) ?? []).filter({ $0 != ".DS_Store" }).count < 2 {
            try await bashService.rmDir(parent)
        } else {
            try await bashService.rmDir(path)
        }
    }
    
    nonisolated private func path(for source: CarthageSource) -> URL {
        let path: URL
        switch source {
        case .dependencies:
            path = root.appendingPathComponent("dependencies", isDirectory: true)
        case .binaries:
            path = root.appendingPathComponent("binaries", isDirectory: true)
        case .derivedData:
            path = root.appendingPathComponent("DerivedData", isDirectory: true)
        }
        return path
    }
}

private final class CarthageServiceEmpty: CarthageServiceMock { }

class CarthageServiceMock: CarthageServiceInteface {
    static let shared = CarthageServiceMock()
    func binaries() async -> [CarthageItem] { [] }
    func dependencies() async -> [CarthageItem] { [] }
    func derivedData() async -> [CarthageDerivedData] { [] }
    func size() throws -> String { "-" }
    func size(_ item: CarthageItem) throws -> String { "-" }
    func size(_ item: CarthageDerivedDataItem) async throws -> String { "" }
    func delete(_ item: CarthageItem) async throws { }
    func delete(_ item: CarthageDerivedDataItem) async throws { }
    func exists() -> Bool { false }
    func exists(_ source: CarthageSource) -> Bool { false }
    func size(_ source: CarthageSource) async throws -> String { "" }
    func open(_ source: CarthageSource) async throws { }
}

extension EnvironmentValues {
    
    @Entry var carthageService: CarthageServiceInteface = CarthageServiceEmpty()
}

extension View {
    
    func withCarthageService(_ carthageService: CarthageServiceInteface) -> some View {
        environment(\.carthageService, carthageService)
    }
}
