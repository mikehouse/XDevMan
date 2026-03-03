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
    var verbose = false
}

protocol ScipioServiceInterface: Sendable {
    func validateScipioDirectory(_ directory: URL) async throws -> URL
    func resolvePackage(in directory: URL, minimumIOSVersion: Int) async throws -> ScipioPackageResult
    func open(_ path: URL) async throws
    func runBuild(
        scipioExecutable: URL,
        packageDirectory: URL,
        packageSwiftContent: String,
        options: ScipioOptions,
        packageResult: ScipioPackageResult
    ) async throws
}

actor ScipioService: ScipioServiceInterface {

    private let bashService: BashProvider.Type
    private let appLogger: AppLogger
    private let swiftPMService: SwiftPMService

    init(bashService: BashProvider.Type, appLogger: AppLogger) {
        self.bashService = bashService
        self.appLogger = appLogger
        self.swiftPMService = SwiftPMService(bashService: bashService, appLogger: appLogger)
    }

    func validateScipioDirectory(_ directory: URL) throws -> URL {
        let executable = directory.appendingPathComponent("scipio", isDirectory: false)
        guard FileManager.default.fileExists(atPath: executable.path) else {
            throw Errors.invalidScipioDirectory
        }
        return executable
    }

    func resolvePackage(in directory: URL, minimumIOSVersion: Int) async throws -> ScipioPackageResult {
        var packageSwift = directory.appendingPathComponent("Package.swift", isDirectory: false)
        if var swiftVersion = (try await bashService.swiftVersion()).flatMap({ Double($0) }) {
            while swiftVersion >= 5.6 {
                let maybePackageSwift = directory.appendingPathComponent("Package@swift-\(swiftVersion).swift", isDirectory: false)
                if FileManager.default.fileExists(atPath: maybePackageSwift.path) {
                    packageSwift = maybePackageSwift
                    break
                }
                swiftVersion = Double(String(format: "%.1f", swiftVersion - 0.1))!
            }
        }
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
            let converted = try await convertPackageResolved(rootResolved, minimumIOSVersion: minimumIOSVersion)
            return .init(
                selectedDirectory: directory,
                packageFile: rootResolved,
                source: .packageResolved,
                packageSwiftContent: converted
            )
        }

        let resolvedFromProject = try findPackageResolvedInsideXcodeproj(in: directory)
        let converted = try await convertPackageResolved(resolvedFromProject, minimumIOSVersion: minimumIOSVersion)
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
        options: ScipioOptions,
        packageResult: ScipioPackageResult
    ) async throws {
        let rootDirectory: URL
        if packageResult.source == .packageSwift {
            rootDirectory = packageDirectory
            let packageSwift = rootDirectory.appendingPathComponent(packageResult.packageFile.lastPathComponent, isDirectory: false)
            try packageSwiftContent.write(to: packageSwift, atomically: true, encoding: .utf8)
        } else {
            rootDirectory = packageDirectory.appendingPathComponent("scipio-convert", isDirectory: true)
            let sourcesDirectory = rootDirectory.appendingPathComponent("Sources", isDirectory: true)
            let dummySwift = sourcesDirectory.appendingPathComponent("dummy.swift", isDirectory: false)
            try FileManager.default.createDirectory(at: sourcesDirectory, withIntermediateDirectories: true)
            try "import Foundation\n".write(to: dummySwift, atomically: true, encoding: .utf8)
            let packageSwift = rootDirectory.appendingPathComponent("Package.swift", isDirectory: false)
            try packageSwiftContent.write(to: packageSwift, atomically: true, encoding: .utf8)
        }

        let command = makePrepareCommand(
            scipioExecutable: scipioExecutable,
            convertDirectory: rootDirectory,
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

    func convertPackageResolved(_ resolvedURL: URL, minimumIOSVersion: Int) async throws -> String {
        let resolved: PackageResolved
        do {
            let topmostPins = try await swiftPMService.buildGraph(resolvedPath: resolvedURL) { _, _, _ in }
            resolved = PackageResolved(pins: topmostPins.compactMap({ pin -> PackageResolved.Pin? in
                guard let location = pin.value.location, let revision = pin.value.revision else { return nil }
                return PackageResolved.Pin(location: location, state: PackageResolved.Pin.State(revision: revision))
            }))
        } catch {
            throw Errors.invalidPackageResolved
        }

        guard resolved.pins.isEmpty == false else {
            throw Errors.emptyPackageResolved
        }

        var dependencies = resolved.pins.map({ pin -> String in
            "        .package(url: \"\(pin.location)\", revision: \"\(pin.state.revision)\")"
        })

        struct PackageDump: Decodable {
            let name: String
            let products: [Product]
            struct Product: Decodable {
                let name: String
            }
        }
        var products: [String] = []
        for pin in resolved.pins {
            let packageName = packageName(from: pin.location)
            var name = packageName
            var nameChanged = false
            do {
                let urlComponents = normalizeRepositoryURL(pin.location).flatMap({ URLComponents(string: $0.absoluteString) })
                guard var urlComponents else {
                    throw Errors.packageBadUrl(pin.location)
                }
                let packageURL: URL?
                switch urlComponents.host {
                case "github.com":
                    urlComponents.host = "raw.githubusercontent.com"
                    packageURL = urlComponents.url?.deletingPathExtension().appendingPathComponent("/\(pin.state.revision)/Package.swift")
                case "gitlab.com":
                    packageURL = urlComponents.url?.deletingPathExtension().appendingPathComponent("/-/raw/\(pin.state.revision)/Package.swift")
                default:
                    packageURL = nil
                }
                guard let packageURL else {
                    throw Errors.packageUnsupportedHost(urlComponents.host ?? "")
                }
                let packageDir = FileManager.default.temporaryDirectory
                    .appendingPathComponent(name)
                    .appendingPathComponent(pin.state.revision)
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
                let package = try JSONDecoder().decode(PackageDump.self, from: jsonData)
                if package.products.count == 1 {
                    name = package.products[0].name
                    nameChanged = true
                } else if package.products.count > 1 {
                    if name.hasPrefix("swift-") { // From swiftlang repository.
                        let maybeNames = [
                            name.components(separatedBy: "-").map({ $0.capitalized }).joined(separator: ""),
                            name.components(separatedBy: "-").dropFirst().map({ $0.capitalized }).joined(separator: ""),
                        ]
                        if let foundName = package.products.first(where: { maybeNames.contains($0.name) }) {
                            name = foundName.name
                            nameChanged = true
                        }
                    } else if let swiftPackageVer = package.products.first(where: { $0.name == "\(package.name)Swift" }) {
                        name = swiftPackageVer.name
                        nameChanged = true
                    } else if let originalPackageVer = package.products.first(where: { $0.name == package.name }) {
                        name = originalPackageVer.name
                        nameChanged = true
                    }
                }
            } catch {
                appLogger.error(error)
            }
            if nameChanged {
                products.append("                .product(name: \"\(name)\", package: \"\(packageName)\"),")
            } else {
                products.append("                // .product(name: \"\(name)\", package: \"\(packageName)\"), // Check the package name")
                if let idx = dependencies.firstIndex(where: { $0.contains(pin.location) }) {
                    dependencies[idx] = dependencies[idx].replacingOccurrences(of: "        ", with: "        // ")
                }
            }
        }

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
        \(products.joined(separator: "\n"))
                    ]),
            ]
        )
        """
    }

    func packageName(from location: String) -> String {
        URL(string: location)?.deletingPathExtension().lastPathComponent ?? "/"
    }

    func makePrepareCommand(
        scipioExecutable: URL,
        convertDirectory: URL,
        options: ScipioOptions
    ) -> String {
        var parts: [String] = []
        parts.append("cd")
        parts.append(shellQuoted(convertDirectory.path))
        parts.append("&&")
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
        if options.verbose {
            parts.append("--verbose")
        }
        return parts.joined(separator: " ")
    }

    func shellQuoted(_ value: String) -> String {
        "'\(value.replacingOccurrences(of: "'", with: "'\\''"))'"
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

    enum Errors: LocalizedError {

        case invalidScipioDirectory
        case packageFileNotFound
        case unableToReadPackageFile
        case invalidPackageResolved
        case emptyPackageResolved
        case packageBadUrl(String)
        case packageUnsupportedHost(String)

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
            case .packageBadUrl(let url):
                return "Package url is invalid: \(url)"
            case .packageUnsupportedHost(let host):
                return "Package url host is not supported: \(host)"
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
        options: ScipioOptions,
        packageResult: ScipioPackageResult
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
