import Foundation
import SwiftUI

struct ScipioPackageResult: @MainActor HashableIdentifiable {
    enum Source: String, Sendable, Hashable {
        case packageSwift = "Package.swift"
        case packageResolved = "Package.resolved"
    }

    var id: String { packageSwiftContent }

    let selectedDirectory: URL
    let packageFile: URL
    let source: Source
    let packageSwiftContent: String
}

struct ScipioOptions: Sendable, Hashable {
    enum Configuration: String, Sendable, Hashable, CaseIterable, Identifiable {
        var id: RawValue { rawValue }

        case release
        case debug
    }

    enum FrameworkType: String, Sendable, Hashable, CaseIterable, Identifiable {
        var id: RawValue { rawValue }

        case dynamic
        case `static`
        case mergeable
    }

    var configuration: Configuration = .release
    var frameworkType: FrameworkType = .dynamic
    var embedDebugSymbols = true
    var supportSimulators = true
    var enableLibraryEvolution = true
    var stripStaticLibDwarfSymbols = false
}

protocol ScipioServiceInterface: Sendable {
    func validateScipioDirectory(_ directory: URL) async throws -> URL
    func resolvePackage(in directory: URL, minimumIOSVersion: Int) async throws -> ScipioPackageResult
    func open(_ path: URL) async throws
    func runBuild(
        scipioExecutable: URL,
        packageDirectory: URL,
        packageSwiftContent: String,
        options: ScipioOptions
    ) async throws
}

actor ScipioService: ScipioServiceInterface {

    private let bashService: BashProvider.Type

    init(bashService: BashProvider.Type) {
        self.bashService = bashService
    }

    func validateScipioDirectory(_ directory: URL) throws -> URL {
        let executable = directory.appendingPathComponent("scipio", isDirectory: false)
        guard FileManager.default.fileExists(atPath: executable.path) else {
            throw Errors.invalidScipioDirectory
        }
        return executable
    }

    func resolvePackage(in directory: URL, minimumIOSVersion: Int) async throws -> ScipioPackageResult {
        let packageSwift = directory.appendingPathComponent("Package.swift", isDirectory: false)
        if FileManager.default.fileExists(atPath: packageSwift.path) {
            let content = try readFile(packageSwift)
            return .init(
                selectedDirectory: directory,
                packageFile: packageSwift,
                source: .packageSwift,
                packageSwiftContent: content
            )
        }

        let rootResolved = directory.appendingPathComponent("Package.resolved", isDirectory: false)
        if FileManager.default.fileExists(atPath: rootResolved.path) {
            let converted = try convertPackageResolved(rootResolved, minimumIOSVersion: minimumIOSVersion)
            return .init(
                selectedDirectory: directory,
                packageFile: rootResolved,
                source: .packageResolved,
                packageSwiftContent: converted
            )
        }

        let resolvedFromProject = try findPackageResolvedInsideXcodeproj(in: directory)
        let converted = try convertPackageResolved(resolvedFromProject, minimumIOSVersion: minimumIOSVersion)
        return .init(
            selectedDirectory: directory,
            packageFile: resolvedFromProject,
            source: .packageResolved,
            packageSwiftContent: converted
        )
    }

    func open(_ path: URL) async throws {
        try await bashService.open(path)
    }

    func runBuild(
        scipioExecutable: URL,
        packageDirectory: URL,
        packageSwiftContent: String,
        options: ScipioOptions
    ) async throws {
        let convertDirectory = packageDirectory.appendingPathComponent("scipio-convert", isDirectory: true)
        let sourcesDirectory = convertDirectory.appendingPathComponent("Sources", isDirectory: true)
        let packageSwift = convertDirectory.appendingPathComponent("Package.swift", isDirectory: false)

        try FileManager.default.createDirectory(at: convertDirectory, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: sourcesDirectory, withIntermediateDirectories: true)
        try packageSwiftContent.write(to: packageSwift, atomically: true, encoding: .utf8)

        let command = makePrepareCommand(
            scipioExecutable: scipioExecutable,
            convertDirectory: convertDirectory,
            options: options
        )
        try await bashService.runInTerminal(command)
    }
}

private extension ScipioService {

    struct PackageResolved: Decodable {
        struct Pin: Decodable {
            struct State: Decodable {
                let revision: String
            }

            let location: String
            let state: State
        }

        let pins: [Pin]
    }

    func readFile(_ file: URL) throws -> String {
        do {
            return try String(contentsOf: file)
        } catch {
            throw Errors.unableToReadPackageFile
        }
    }

    func findPackageResolvedInsideXcodeproj(in directory: URL) throws -> URL {
        let fileManager = FileManager.default
        let entries = (try? fileManager.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        )) ?? []

        guard let project = entries.first(where: {
            $0.pathExtension == "xcodeproj"
        }) else {
            throw Errors.packageFileNotFound
        }

        let resolved = project
            .appendingPathComponent("project.xcworkspace", isDirectory: true)
            .appendingPathComponent("xcshareddata", isDirectory: true)
            .appendingPathComponent("swiftpm", isDirectory: true)
            .appendingPathComponent("Package.resolved", isDirectory: false)

        guard fileManager.fileExists(atPath: resolved.path) else {
            throw Errors.packageFileNotFound
        }

        return resolved
    }

    func convertPackageResolved(_ resolvedURL: URL, minimumIOSVersion: Int) throws -> String {
        let data: Data
        do {
            data = try Data(contentsOf: resolvedURL)
        } catch {
            throw Errors.unableToReadPackageFile
        }

        let resolved: PackageResolved
        do {
            resolved = try JSONDecoder().decode(PackageResolved.self, from: data)
        } catch {
            throw Errors.invalidPackageResolved
        }

        guard resolved.pins.isEmpty == false else {
            throw Errors.emptyPackageResolved
        }

        let dependencies = resolved.pins.map({ pin -> String in
            "        .package(url: \"\(pin.location)\", revision: \"\(pin.state.revision)\")"
        })

        let products = resolved.pins.map({ pin -> String in
            let name = packageName(from: pin.location)
            return "                .product(name: \"\(name)\", package: \"\(name)\") // Name might be incorrect"
        })

        return """
        // swift-tools-version: 6.0
        // The swift-tools-version declares the minimum version of Swift required to build this package.

        import PackageDescription

        let package = Package(
            name: "MyAppDependencies",
            platforms: [
                // Specify platforms to build
                .iOS(.v\(minimumIOSVersion)),
            ],
            products: [],
            dependencies: [
                // Add dependencies
        \(dependencies.joined(separator: ",\n")),
            ],
            targets: [
                .target(
                    name: "MyAppDependency",
                    dependencies: [
                        // List all dependencies to build
        \(products.joined(separator: ",\n")),
                    ]),
            ]
        )
        """
    }

    func packageName(from location: String) -> String {
        let lastPath = URL(string: location)?.deletingPathExtension().lastPathComponent ?? "/"
        let fallback = location.components(separatedBy: "/").last ?? location
        let raw = (lastPath.isEmpty == false ? lastPath : fallback)
        if raw.hasSuffix(".git") {
            return String(raw.dropLast(4))
        }
        return raw
    }

    func makePrepareCommand(
        scipioExecutable: URL,
        convertDirectory: URL,
        options: ScipioOptions
    ) -> String {
        var parts: [String] = []
        parts.append(shellQuoted(scipioExecutable.path))
        parts.append("prepare")
        parts.append(shellQuoted(convertDirectory.path))
        parts.append("--configuration")
        parts.append(options.configuration.rawValue)
        parts.append("--framework-type")
        parts.append(options.frameworkType.rawValue)

        if options.embedDebugSymbols {
            parts.append("--embed-debug-symbols")
        }
        if options.supportSimulators {
            parts.append("--support-simulators")
        }
        if options.enableLibraryEvolution {
            parts.append("--enable-library-evolution")
        }
        if options.stripStaticLibDwarfSymbols {
            parts.append("--strip-static-lib-dwarf-symbols")
        }

        return parts.joined(separator: " ")
    }

    func shellQuoted(_ value: String) -> String {
        "'\(value.replacingOccurrences(of: "'", with: "'\\''"))'"
    }

    enum Errors: LocalizedError {

        case invalidScipioDirectory
        case packageFileNotFound
        case unableToReadPackageFile
        case invalidPackageResolved
        case emptyPackageResolved

        var errorDescription: String? {
            switch self {
            case .invalidScipioDirectory:
                return "Unable to find scipio executable. Select a folder that contains the scipio file."
            case .packageFileNotFound:
                return "Unable to find Package.swift or Package.resolved in the selected folder."
            case .unableToReadPackageFile:
                return "Unable to read package file content."
            case .invalidPackageResolved:
                return "Package.resolved has unsupported JSON format."
            case .emptyPackageResolved:
                return "Package.resolved does not contain any dependencies."
            }
        }
    }
}

private final class ScipioServiceEmpty: ScipioServiceMock { }

class ScipioServiceMock: ScipioServiceInterface {
    static let shared = ScipioServiceMock()

    func validateScipioDirectory(_ directory: URL) async throws -> URL {
        directory.appendingPathComponent("scipio", isDirectory: false)
    }

    func resolvePackage(in directory: URL, minimumIOSVersion: Int) async throws -> ScipioPackageResult {
        .init(
            selectedDirectory: directory,
            packageFile: directory.appendingPathComponent("Package.swift", isDirectory: false),
            source: .packageSwift,
            packageSwiftContent: "// swift-tools-version: 6.0"
        )
    }

    func open(_ path: URL) async throws { }

    func runBuild(
        scipioExecutable: URL,
        packageDirectory: URL,
        packageSwiftContent: String,
        options: ScipioOptions
    ) async throws { }

    init() { }
}

extension EnvironmentValues {

    @Entry var scipioService: ScipioServiceInterface = ScipioServiceEmpty()
}

extension View {

    func withScipioService(_ scipioService: ScipioServiceInterface) -> some View {
        environment(\.scipioService, scipioService)
    }
}
