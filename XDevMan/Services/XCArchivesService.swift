
import SwiftUI

struct XCArchives: HashableIdentifiable {
    
    var id: String { "\(date)+\(archives.count)" }
    
    let date: String
    let archives: [XCArchiveID]
}

struct XCArchiveID: HashableIdentifiable {
    
    var id: URL { path }
    
    let path: URL
    let name: String
    let date: Date
}

struct XCArchive: HashableIdentifiable {
    
    var id: URL { path }
    
    let path: URL
    let signingIdentity: String
    let creationDate: Date
    let name: String
    let scheme: String
    let displayName: String
    let bundleName: String
    let executable: String
    let primaryIcon: URL?
    let bundleIdentifier: String
    let shortVersion: String
    let version: String
    let platform: String
    let platformVersion: String
    let xcodeVersion: String
    let minimumOSVersion: String
    let region: String
    let team: String
    let xcodeBuild: String
    let architectures: [String]
    let supportedPlatforms: [String]
    let queriesSchemes: [String]
    let urlSchemes: [String]
    let backgroundModes: [String]
    let bonjourServices: [String]
    let appFonts: [String]
    let supportedInterfaceOrientations: [String]
    let allowsArbitraryLoads: Bool
    let exceptionDomains: [String]
    let cameraUsageDescription: String?
    let faceIDUsageDescription: String?
    let microphoneUsageDescription: String?
    let photoLibraryAddUsageDescription: String?
    let photoLibraryUsageDescription: String?
    let userTrackingUsageDescription: String?
    let bluetoothAlwaysUsageDescription: String?
    let bluetoothPeripheralUsageDescription: String?
    let documentsFolderUsageDescription: String?
    let localNetworkUsageDescription: String?
    let userInterfaceStyle: String?
}

enum XCArchiveError: Error {
    
    case notFound(String)
    case cli(CliToolError)
}

protocol XCArchivesServiceInterface: Sendable {
  
    nonisolated func archives() async -> [XCArchives]
    nonisolated func archive(_ id: XCArchiveID) async throws -> XCArchive
    nonisolated func size(_ id: XCArchiveID) async throws -> String
    nonisolated func size() async -> String?
    nonisolated func open() async -> Bool
    nonisolated func open(_ id: XCArchiveID) async throws
    nonisolated func delete(_ id: XCArchiveID) async throws
}

final class XCArchivesService: XCArchivesServiceInterface {
    
    private let root = URL(
        fileURLWithPath: "/Users/\(NSUserName())/Library/Developer/Xcode/Archives",
        isDirectory: true
    )
    
    private let bashService: BashProvider.Type
    
    init(bashService: BashProvider.Type) {
        self.bashService = bashService
    }
    
    func delete(_ id: XCArchiveID) async throws {
        let task = Task<Void, Error>.detached { [self] in
            try await bashService.rmDir(id.path)
            let path = id.path.deletingLastPathComponent()
            let archives = ((try? FileManager.default.contentsOfDirectory(atPath: path.path)) ?? [])
                .filter({ $0 != ".DS_Store" })
            guard archives.isEmpty else {
                return
            }
            try? await bashService.rmDir(path)
        }
        do {
            return try await task.value
        } catch {
            throw XCArchiveError.cli(error as? CliToolError ?? CliToolError.fs(error))
        }
    }
    
    func open() async -> Bool {
        await Task<Bool, Never>.detached { [self] in
            var url = root
            while FileManager.default.fileExists(atPath: url.path) == false {
                url = url.deletingLastPathComponent()
            }
            return (try? await bashService.open(url)) != nil
        }.value
    }
    
    func open(_ id: XCArchiveID) async throws {
        try await bashService.open(id.path.appendingPathComponent("Products", isDirectory: true))
    }
    
    func size(_ id: XCArchiveID) async throws -> String {
        try await bashService.size(id.path)
    }
    
    func size() async -> String? {
        await Task<String?, Never>.detached { [self] in
            guard FileManager.default.fileExists(atPath: root.path) else {
                return nil
            }
            return try? await bashService.size(root)
        }.value
    }
    
    func archive(_ id: XCArchiveID) async throws -> XCArchive {
        let task = Task<XCArchive, Error>.detached {
            let fileManager = FileManager.default
            let plist = id.path.appendingPathComponent("Info.plist", isDirectory: false)
            guard let dict = NSDictionary(contentsOf: plist) else {
                throw XCArchiveError.notFound("\(plist.path)/Info.plist")
            }
            guard let props = dict["ApplicationProperties"] as? [String: Any] else {
                throw XCArchiveError.notFound("ApplicationProperties in \(id.path.path)/Info.plist")
            }
            guard let creationDate = dict["CreationDate"] as? Date,
                  let name = dict["Name"] as? String,
                  let appPath = props["ApplicationPath"] as? String,
                  let sign = props["SigningIdentity"] as? String,
                  let team = props["Team"] as? String,
                  let architectures = props["Architectures"] as? [String],
                  let scheme = dict["SchemeName"] as? String else {
                throw XCArchiveError.notFound("Properties in \(id.path.path)/Info.plist")
            }
            let app = id.path.appendingPathComponent("Products", isDirectory: true)
                .appendingPathComponent(appPath, isDirectory: true)
            var appPlistPath = app.appendingPathComponent("Info.plist", isDirectory: false)
            let appPlistMacOSPath = app.appendingPathComponent("Contents/Info.plist", isDirectory: false)
            let appPlist = NSDictionary(contentsOf: appPlistPath)
            if appPlist == nil {
                appPlistPath = appPlistMacOSPath
            }
            guard let appPlist = appPlist ?? NSDictionary(contentsOf: appPlistPath) else {
                throw XCArchiveError.notFound("\(appPlistPath.path) and \(appPlistMacOSPath.path)")
            }
            guard let region = appPlist["CFBundleDevelopmentRegion"] as? String,
                  let bundleId = appPlist["CFBundleIdentifier"] as? String,
                  let bundleName = appPlist["CFBundleName"] as? String,
                  let executable = appPlist["CFBundleExecutable"] as? String,
                  let shortVersion = appPlist["CFBundleShortVersionString"] as? String,
                  let version = appPlist["CFBundleVersion"] as? String,
                  let platformName = appPlist["DTPlatformName"] as? String,
                  let platformVersion = appPlist["DTPlatformVersion"] as? String,
                  let xcodeVersion = appPlist["DTXcode"] as? String,
                  let minimumOSVersion = (appPlist["MinimumOSVersion"] as? String ?? appPlist["LSMinimumSystemVersion"] as? String),
                  let xcodeBuild = appPlist["DTXcodeBuild"] as? String,
                  let supportedPlatforms = appPlist["CFBundleSupportedPlatforms"] as? [String],
                  let displayName = (appPlist["CFBundleDisplayName"] as? String ?? appPlist["CFBundleName"] as? String) else {
                throw XCArchiveError.notFound("Properties in \(appPlistPath.path)")
            }
            var icon: URL?
            if let icons = appPlist["CFBundleIcons"] as? [String: Any],
               let primary = icons["CFBundlePrimaryIcon"] as? [String: Any],
               let iconName = primary["CFBundleIconName"] as? String {
                icon = ((try? fileManager.contentsOfDirectory(atPath: app.path)) ?? [])
                    .first(where: { $0.hasPrefix(iconName) && $0.hasSuffix(".png") })
                    .map({ app.appendingPathComponent($0, isDirectory: false) })
            } else if let iconName = appPlist["CFBundleIconName"] as? String {
                icon = app.appendingPathComponent("Contents/Resources/\(iconName).icns", isDirectory: false)
            }
            var urlSchemes: [String] = []
            if let urlTypes = appPlist["CFBundleURLTypes"] as? [Any] {
                for urlType in urlTypes {
                    guard let urlType = urlType as? [String: Any] else {
                        continue
                    }
                    guard let schemes = urlType["CFBundleURLSchemes"] as? [String] else {
                        continue
                    }
                    urlSchemes += schemes
                }
            }
            let queriesSchemes = appPlist["LSApplicationQueriesSchemes"] as? [String] ?? []
            let backgroundModes = appPlist["UIBackgroundModes"] as? [String] ?? []
            let bonjourServices = appPlist["NSBonjourServices"] as? [String] ?? []
            let appFonts = appPlist["UIAppFonts"] as? [String] ?? []
            let supportedInterfaceOrientations = appPlist["UISupportedInterfaceOrientations"] as? [String] ?? []
            var allowsArbitraryLoads = false
            var exceptionDomains: [String] = []
            if let appTransportSecurity = appPlist["NSAppTransportSecurity"] as? [String: Any] {
                allowsArbitraryLoads = appTransportSecurity["NSAllowsArbitraryLoads"] as? Bool ?? allowsArbitraryLoads
                if let domains = appTransportSecurity["NSExceptionDomains"] as? [String: Any] {
                    exceptionDomains = Array(domains.keys)
                }
            }
            let cameraUsageDescription = appPlist["NSCameraUsageDescription"] as? String
            let faceIDUsageDescription = appPlist["NSFaceIDUsageDescription"] as? String
            let microphoneUsageDescription = appPlist["NSMicrophoneUsageDescription"] as? String
            let photoLibraryAddUsageDescription = appPlist["NSPhotoLibraryAddUsageDescription"] as? String
            let photoLibraryUsageDescription = appPlist["NSPhotoLibraryUsageDescription"] as? String
            let userTrackingUsageDescription = appPlist["NSUserTrackingUsageDescription"] as? String
            let bluetoothAlwaysUsageDescription = appPlist["NSBluetoothAlwaysUsageDescription"] as? String
            let bluetoothPeripheralUsageDescription = appPlist["NSBluetoothPeripheralUsageDescription"] as? String
            let documentsFolderUsageDescription = appPlist["NSDocumentsFolderUsageDescription"] as? String
            let localNetworkUsageDescription = appPlist["NSLocalNetworkUsageDescription"] as? String
            let userInterfaceStyle = appPlist["UIUserInterfaceStyle"] as? String
            return XCArchive(
                path: id.path,
                signingIdentity: sign,
                creationDate:creationDate,
                name: name,
                scheme: scheme,
                displayName: displayName,
                bundleName: bundleName,
                executable: executable,
                primaryIcon: icon,
                bundleIdentifier: bundleId,
                shortVersion: shortVersion,
                version: version,
                platform: platformName,
                platformVersion: platformVersion,
                xcodeVersion: xcodeVersion,
                minimumOSVersion: minimumOSVersion,
                region: region,
                team: team,
                xcodeBuild: xcodeBuild,
                architectures: architectures,
                supportedPlatforms: supportedPlatforms,
                queriesSchemes: queriesSchemes,
                urlSchemes: urlSchemes,
                backgroundModes: backgroundModes,
                bonjourServices: bonjourServices,
                appFonts: appFonts,
                supportedInterfaceOrientations: supportedInterfaceOrientations,
                allowsArbitraryLoads: allowsArbitraryLoads,
                exceptionDomains: exceptionDomains,
                cameraUsageDescription: cameraUsageDescription,
                faceIDUsageDescription: faceIDUsageDescription,
                microphoneUsageDescription: microphoneUsageDescription,
                photoLibraryAddUsageDescription: photoLibraryAddUsageDescription,
                photoLibraryUsageDescription: photoLibraryUsageDescription,
                userTrackingUsageDescription: userTrackingUsageDescription,
                bluetoothAlwaysUsageDescription: bluetoothAlwaysUsageDescription,
                bluetoothPeripheralUsageDescription: bluetoothPeripheralUsageDescription,
                documentsFolderUsageDescription: documentsFolderUsageDescription,
                localNetworkUsageDescription: localNetworkUsageDescription,
                userInterfaceStyle: userInterfaceStyle
            )
        }
        do {
            return try await task.value
        } catch {
            throw (error as? XCArchiveError)
                ?? (error as? CliToolError).map({ XCArchiveError.cli($0) })
                ?? .cli(CliToolError.fs(error))
        }
    }
    
    func archives() async -> [XCArchives] {
        let task = Task<[XCArchives], Never>.detached { [self] in
            let fileManager = FileManager.default
            guard fileManager.fileExists(atPath: root.path) else {
                return []
            }
            return ((try? fileManager.contentsOfDirectory(atPath: root.path)) ?? [])
                .filter({ $0 != ".DS_Store" })
                .compactMap({ date -> XCArchives? in
                    let path = root.appendingPathComponent(date, isDirectory: true)
                    let archives = ((try? fileManager.contentsOfDirectory(atPath: path.path)) ?? [])
                        .filter({ $0 != ".DS_Store" })
                        .compactMap({ archive -> XCArchiveID? in
                            // archive = "MyApp 15.08.2024, 08.08.xcarchive"
                            // or archive = "MyApp 2024-07-02 15.56.38.xcarchive"
                            let path = path.appendingPathComponent(archive, isDirectory: true)
                            let components = archive.components(separatedBy: " ")
                            var name = components[0]
                            var nameIdx = 0
                            while nameIdx < components.count {
                                let next = components[nameIdx + 1]
                                let digits = next.dropLast(next.count - 2)
                                if Int(digits) != nil {
                                    break // Archive Date started, name parsed correctly.
                                }
                                // Seems part of name, have to add it to first part of name.
                                name = "\(name) \(next)"
                                nameIdx += 1
                            }
                            var date: Date?
                            if let attributes = try? fileManager.attributesOfItem(atPath: path.path) {
                                // Fast path.
                                date = attributes[.creationDate] as? Date
                            } else {
                                // Slow path from parsing Info.plist.
                                let plist = path.appendingPathComponent("Info.plist", isDirectory: false)
                                if let dict = NSDictionary(contentsOf: plist) {
                                    date = dict["CreationDate"] as? Date
                                }
                            }
                            guard let date else {
                                return nil
                            }
                            return XCArchiveID(
                                path: path,
                                name: name,
                                date: date
                            )
                        })
                        .sorted(by: { $0.date > $1.date })
                    guard archives.isEmpty == false else {
                        return nil
                    }
                    return XCArchives(
                        date: date,
                        archives: archives
                    )
                })
                .sorted(by: { $0.archives[0].date > $1.archives[0].date })
        }
        return await task.value
    }
}

private final class XCArchivesServiceEmpty: XCArchivesServiceMock, @unchecked Sendable { }

class XCArchivesServiceMock: XCArchivesServiceInterface, @unchecked Sendable {
    static let shared = XCArchivesServiceMock()
    func archives() async -> [XCArchives] { [] }
    func archive(_ id: XCArchiveID) async throws -> XCArchive {
        XCArchive(
            path: id.path,
            signingIdentity: "Apple Development: Ivan Ivanov (P3N7473VFF)",
            creationDate: Date(),
            name: "MyAwesomeApp",
            scheme: "MyAwesomeApp",
            displayName: "My Awesome App",
            bundleName: "MyAwesomeApp",
            executable: "executable",
            primaryIcon: nil,
            bundleIdentifier: "com.apple.com.MyAwesomeApp",
            shortVersion: "1.21.0",
            version: "1234",
            platform: "iphoneos",
            platformVersion: "18.1",
            xcodeVersion: "1610",
            minimumOSVersion: "15.0",
            region: "en",
            team: "3VV6F45H9V",
            xcodeBuild: "16B5001e",
            architectures: ["arm64"],
            supportedPlatforms: ["MacOSX"],
            queriesSchemes: ["itms-apps"],
            urlSchemes: ["cdr"],
            backgroundModes: ["remote-notification"],
            bonjourServices: ["_googlecast._tcp"],
            appFonts: ["UniSansBold.otf"],
            supportedInterfaceOrientations: ["UIInterfaceOrientationPortrait"],
            allowsArbitraryLoads: false,
            exceptionDomains: ["abc.com"],
            cameraUsageDescription: "cameraUsageDescription",
            faceIDUsageDescription: "faceIDUsageDescription",
            microphoneUsageDescription: "microphoneUsageDescription",
            photoLibraryAddUsageDescription: "photoLibraryAddUsageDescription",
            photoLibraryUsageDescription: "photoLibraryUsageDescription",
            userTrackingUsageDescription: "userTrackingUsageDescription",
            bluetoothAlwaysUsageDescription: "bluetoothAlwaysUsageDescription",
            bluetoothPeripheralUsageDescription: "bluetoothPeripheralUsageDescription",
            documentsFolderUsageDescription: "documentsFolderUsageDescription",
            localNetworkUsageDescription: "localNetworkUsageDescription",
            userInterfaceStyle: "Light"
        )
    }
    func size(_ id: XCArchiveID) async throws -> String { "" }
    func size() async -> String? { nil }
    func open() async -> Bool { false }
    func open(_ id: XCArchiveID) async throws { }
    func delete(_ id: XCArchiveID) async throws { }
}

extension EnvironmentValues {
    
    @Entry var xcAchivesService: XCArchivesServiceInterface = XCArchivesServiceEmpty()
}

extension View {
    
    func withXCArchiveService(_ xcAchivesService: XCArchivesServiceInterface) -> some View {
        environment(\.xcAchivesService, xcAchivesService)
    }
}
