import Foundation
import SwiftUI
import UniformTypeIdentifiers

struct ScipioView: View {

    @Environment(\.scipioService) private var scipioService
    @Environment(\.alertHandler) private var alertHandler
    @Environment(\.appLogger) private var appLogger
    @State private var importer: Importer?
    @State private var isImporterPresented = false
    @State private var scipioDirectory: URL?
    @State private var scipioExecutable: URL?
    @State private var packageResult: ScipioPackageResult?
    @State private var options = ScipioOptions()
    @State private var minimumIOSVersion = 15
    @State private var swiftToolsVersion = "6.2"
    @State private var isResolvingPackage = false
    @State private var isRunning = false
    private let supportedIOSVersions = [14, 15, 16, 17, 18, 26]
    private let supportedSwiftToolsVersions = ["5.9", "6.0", "6.1", "6.2"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                scipioDirectorySection
                Divider()
                optionsSection
                Divider()
                packageSection
                HStack(spacing: 10) {
                    Button {
                        Task {
                            await runBuild()
                        }
                    } label: {
                        Text("Build in Terminal")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(canBuild == false || isRunning)

                    if isRunning {
                        ProgressView()
                            .controlSize(.mini)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                TextEditor(text: packageSwiftContent)
                    .font(.system(.body, design: .monospaced))
                    .frame(minHeight: 320)
            }
            .padding()
        }
        .navigationTitle("Scipio")
        .fileImporter(
            isPresented: $isImporterPresented,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false
        ) { result in
            handleImporterResult(result)
        }
        .onChange(of: minimumIOSVersion) {
            guard let current = packageResult else {
                return
            }
            packageResult = .init(
                selectedDirectory: current.selectedDirectory,
                packageFile: current.packageFile,
                source: current.source,
                packageSwiftContent: packageSwiftWithSelectedIOSVersion(current.packageSwiftContent, packageResult: current)
            )
        }
        .onChange(of: swiftToolsVersion) {
            guard let current = packageResult else {
                return
            }
            packageResult = .init(
                selectedDirectory: current.selectedDirectory,
                packageFile: current.packageFile,
                source: current.source,
                packageSwiftContent: packageSwiftWithSelectedIOSVersion(current.packageSwiftContent, packageResult: current)
            )
        }
    }

    private var canBuild: Bool {
        scipioExecutable != nil && packageResult != nil
    }

    private var packageSwiftContent: Binding<String> {
        .init(get: {
            packageResult?.packageSwiftContent ?? ""
        }, set: { _ in
        })
    }

    private var scipioDirectorySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Button {
                    importer = .scipioDirectory
                    isImporterPresented = true
                } label: {
                    Label("", systemImage: "folder.badge.plus")
                }
                .buttonStyle(.toolbarDefault)

                Text("scipio")
                    .foregroundStyle(.secondary)

                if let scipioDirectory {
                    BashOpenView(path: .url(scipioDirectory), type: .folder)
                }
            }
            if let scipioExecutable {
                Text(scipioExecutable.path)
                    .textSelection(.enabled)
                    .font(.system(.callout, design: .monospaced))
            } else {
                Text("Select a directory that contains scipio binary.")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var optionsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Scipio options")
                .font(.headline)
            Picker("configuration", selection: $options.configuration) {
                ForEach(ScipioOptions.Configuration.allCases) { item in
                    Text(item.rawValue).tag(item)
                }
            }
            Picker("framework-type", selection: $options.frameworkType) {
                ForEach(ScipioOptions.FrameworkType.allCases) { item in
                    Text(item.rawValue).tag(item)
                }
            }
            Toggle("embed-debug-symbols", isOn: $options.embedDebugSymbols)
            Toggle("support-simulators", isOn: $options.supportSimulators)
            Toggle("enable-library-evolution", isOn: $options.enableLibraryEvolution)
            Toggle("strip-static-lib-dwarf-symbols", isOn: $options.stripStaticLibDwarfSymbols)
            Toggle("verbose", isOn: $options.verbose)
        }
    }

    private var packageSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Picker("iOS min version", selection: $minimumIOSVersion) {
                    ForEach(supportedIOSVersions, id: \.self) { version in
                        Text("\(version)").tag(version)
                    }
                }
                .pickerStyle(.segmented)
            }
            HStack(spacing: 10) {
                Picker("swift-tools-version", selection: $swiftToolsVersion) {
                    ForEach(supportedSwiftToolsVersions, id: \.self) { version in
                        Text(version).tag(version)
                    }
                }
                .pickerStyle(.segmented)
                .disabled(!(packageResult?.source == .packageResolved))
            }
            HStack(spacing: 10) {
                Button {
                    importer = .packageDirectory
                    isImporterPresented = true
                } label: {
                    Label("", systemImage: "folder.badge.plus")
                }
                .buttonStyle(.toolbarDefault)

                Text("Package.swift | *.xcodeproj")
                    .foregroundStyle(.secondary)

                if let packageResult {
                    BashOpenView(path: .url(packageResult.selectedDirectory), type: .folder)
                }

                if isResolvingPackage {
                    ProgressView()
                        .controlSize(.small)
                }
            }
            if let packageResult {
                Text("Source: \(packageResult.source.rawValue)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(packageResult.packageFile.path)
                    .textSelection(.enabled)
                    .font(.system(.callout, design: .monospaced))
            } else {
                Text("Select a directory with Package.swift or *.xcodeproj.")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func handleImporterResult(_ result: Result<[URL], Error>) {
        let importerType = importer
        importer = nil
        isImporterPresented = false

        switch result {
        case .success(let selection):
            guard let directory = selection.first else {
                return
            }
            switch importerType {
            case .scipioDirectory:
                Task {
                    await selectScipioDirectory(directory)
                }
            case .packageDirectory:
                Task {
                    await resolvePackageDirectory(directory)
                }
            case .none:
                return
            }
        case .failure(let failure):
            appLogger.error(failure)
            alertHandler.handle(title: "File Import error", message: nil, error: failure)
        }
    }

    private func selectScipioDirectory(_ directory: URL) async {
        do {
            let executable = try await scipioService.validateScipioDirectory(directory)
            scipioDirectory = directory
            scipioExecutable = executable
        } catch {
            scipioDirectory = nil
            scipioExecutable = nil
            appLogger.error(error)
            alertHandler.handle(title: "Scipio directory error", message: nil, error: error)
        }
    }

    private func resolvePackageDirectory(_ directory: URL) async {
        isResolvingPackage = true
        defer {
            isResolvingPackage = false
        }
        do {
            let result = try await scipioService.resolvePackage(in: directory, minimumIOSVersion: minimumIOSVersion)
            packageResult = .init(
                selectedDirectory: result.selectedDirectory,
                packageFile: result.packageFile,
                source: result.source,
                packageSwiftContent: packageSwiftWithSelectedIOSVersion(result.packageSwiftContent, packageResult: result)
            )
        } catch {
            packageResult = nil
            appLogger.error(error)
            alertHandler.handle(title: "Package directory error", message: nil, error: error)
        }
    }

    private func runBuild() async {
        guard let scipioExecutable, let packageResult else {
            return
        }
        isRunning = true
        defer {
            isRunning = false
        }
        do {
            try await scipioService.runBuild(
                scipioExecutable: scipioExecutable,
                packageDirectory: packageResult.selectedDirectory,
                packageSwiftContent: packageResult.packageSwiftContent,
                options: options,
                packageResult: packageResult
            )
        } catch {
            appLogger.error(error)
            alertHandler.handle(title: "Scipio run error", message: nil, error: error)
        }
    }
    
    private func packageSwiftWithSelectedIOSVersion(_ source: String, packageResult: ScipioPackageResult) -> String {
        let iosPattern = #"\.iOS\(\.v\d+\)"#
        let toolsPattern = #"(?m)^//\s*swift-tools-version:\s*[0-9]+\.[0-9]+\s*$"#
        
        var result = source
        if let iosRegex = try? NSRegularExpression(pattern: iosPattern) {
            let range = NSRange(location: 0, length: result.utf16.count)
            result = iosRegex.stringByReplacingMatches(
                in: result,
                options: [],
                range: range,
                withTemplate: ".iOS(.v\(minimumIOSVersion))"
            )
        }

        if packageResult.source == .packageSwift {
            // Do not change original compiler.
            return result
        }
        
        if let toolsRegex = try? NSRegularExpression(pattern: toolsPattern) {
            let range = NSRange(location: 0, length: result.utf16.count)
            if toolsRegex.firstMatch(in: result, options: [], range: range) != nil {
                result = toolsRegex.stringByReplacingMatches(
                    in: result,
                    options: [],
                    range: range,
                    withTemplate: "// swift-tools-version: \(swiftToolsVersion)"
                )
            } else {
                result = "// swift-tools-version: \(swiftToolsVersion)\n\(result)"
            }
        }
        
        return result
    }

    private enum Importer {
        case scipioDirectory
        case packageDirectory
    }
}

#Preview {
    ScipioView()
        .frame(width: 720, height: 700)
        .withScipioService(ScipioServiceMockImpl())
        .withAppMocks()
}

private final class ScipioServiceMockImpl: ScipioServiceMock {
    override func resolvePackage(in directory: URL, minimumIOSVersion: Int) async throws -> ScipioPackageResult {
        .init(
            selectedDirectory: directory,
            packageFile: directory.appendingPathComponent("Package.resolved", isDirectory: false),
            source: .packageResolved,
            packageSwiftContent: """
            // swift-tools-version: 6.0
            import PackageDescription

            let package = Package(
                name: "MyAppDependencies",
                platforms: [.iOS(.v\(minimumIOSVersion))],
                products: [],
                dependencies: [
                    .package(url: "https://github.com/onevcat/APNGKit.git", revision: "f1807697d455b258cae7522b939372b4652437c1")
                ],
                targets: [
                    .target(name: "MyAppDependency", dependencies: [
                        .product(name: "APNGKit", package: "APNGKit")
                    ])
                ]
            )
            """
        )
    }
}
