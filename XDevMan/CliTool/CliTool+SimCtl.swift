
import SwiftUI

typealias Runtime = CliTool.SimCtl.List.Runtimes.Runtime
typealias RuntimeInternal = CliTool.SimCtl.Runtime.Runtime
typealias DevicesSim = CliTool.SimCtl.List.Devices
typealias DeviceSim = DevicesSim.Device
typealias SimApp = CliTool.SimCtl.SimApp
typealias SupportedDeviceType = Runtime.SupportedDeviceType

protocol RuntimesProvider {
    
    static func runtimes() async throws -> CliTool.SimCtl.List.Runtimes
    static func list() async throws -> [RuntimeInternal]
    static func delete(_ runtime: Runtime) async throws
    static func create(_ device: SupportedDeviceType, runtime: Runtime, name: String?) async throws
    static func create(_ device: DeviceSim, runtime: Runtime, name: String?) async throws
    static func isBeta(_ runtime: Runtime) async throws -> Bool
    static func dyldCache(_ runtime: Runtime) async throws -> URL?
}

class RuntimesProviderMock: RuntimesProvider {
    
    class func list() async throws -> [RuntimeInternal] { [] }
    class func create(_ device: SupportedDeviceType, runtime: Runtime, name: String?) async throws { }
    static func create(_ device: DeviceSim, runtime: Runtime, name: String?) async throws { }
    class func delete(_ runtime: Runtime) async throws { }
    class func runtimes() async throws -> CliTool.SimCtl.List.Runtimes { .init(runtimes: []) }
    class func isBeta(_ runtime: Runtime) async throws -> Bool { false }
    class func dyldCache(_ runtime: Runtime) async throws -> URL? { nil }
}

protocol DevicesProvider {
    
    static func devices() async throws -> CliTool.SimCtl.List.Devices
    static func delete(_ device: DeviceSim) async throws
    static func erase(_ device: DeviceSim) async throws
    static func boot(_ device: DeviceSim) async throws
    static func shutdown(_ device: DeviceSim) async throws
    static func apps(_ device: DeviceSim) async throws -> [SimApp]
}

class DevicesProviderMock: DevicesProvider {
    
    class func devices() async throws -> CliTool.SimCtl.List.Devices { fatalError() }
    class func delete(_ device: DeviceSim) async throws { }
    class func erase(_ device: DeviceSim) async throws { }
    class func boot(_ device: DeviceSim) async throws { }
    class func shutdown(_ device: DeviceSim) async throws { }
    class func apps(_ device: DeviceSim) async throws -> [SimApp] { [] }
}

extension EnvironmentValues {
    
    @Entry var runtimesService: RuntimesProvider.Type = RuntimesProviderWrapper.self
    @Entry var devicesService: DevicesProvider.Type = DevicesProviderWrapper.self
}

extension View {
    
    func withRuntimesService(_ runtimesService: RuntimesProvider.Type) -> some View {
        environment(\.runtimesService, runtimesService)
    }
    
    func withDevicesService(_ devicesService: DevicesProvider.Type) -> some View {
        environment(\.devicesService, devicesService)
    }
}

private struct RuntimesProviderWrapper: RuntimesProvider {
    
    static func runtimes() async throws -> CliTool.SimCtl.List.Runtimes {
        try await CliTool.SimCtl.List.runtimes()
    }
    
    static func list() async throws -> [RuntimeInternal] {
        try await CliTool.SimCtl.Runtime.list()
    }
    
    static func delete(_ runtime: Runtime) async throws {
        try await CliTool.SimCtl.Runtime.delete(runtime)
    }
    
    static func create(_ device: SupportedDeviceType, runtime: Runtime, name: String?) async throws {
        try await CliTool.SimCtl.create(device, runtime: runtime, name: name)
    }
    
    static func create(_ device: DeviceSim, runtime: Runtime, name: String?) async throws {
        try await CliTool.SimCtl.create(device, runtime: runtime, name: name)
    }
    
    static func isBeta(_ runtime: Runtime) async throws -> Bool {
        let task = Task<Bool, Error>(priority: .high) {
            let fileManager = FileManager.default
            let os = runtime.name.components(separatedBy: .whitespaces)[0]
            let licence = URL(fileURLWithPath: runtime.runtimeRoot, isDirectory: true)
                .appendingPathComponent("System/Library/ProductDocuments/SoftwareLicenseAgreements/\(os).bundle/en.lproj/License.html", isDirectory: false)
            guard fileManager.fileExists(atPath: licence.path) else {
                return false
            }
            let content = try String.init(contentsOf: licence, encoding: .utf8)
            return content.contains("BETA SOFTWARE")
        }
        do {
            return try await task.value
        } catch {
            throw CliToolError.fs(error)
        }
    }
    
    static func dyldCache(_ runtime: Runtime) async throws -> URL? {
        let task = Task<URL?, Error>(priority: .high) {
            let cacheDir = try await URL(fileURLWithPath: "/Users/\(NSUserName())/Library/Developer/CoreSimulator/Caches/dyld", isDirectory: true)
                .appendingPathComponent(EnvironmentValues().bashService.osInfo().build)
                .appendingPathComponent("\(runtime.identifier).\(runtime.buildversion)")
            if FileManager.default.fileExists(atPath: cacheDir.path) {
                return cacheDir
            } else {
                return nil
            }            
        }
        do {
            return try await task.value
        } catch {
            throw CliToolError.fs(error)
        }
    }
}

private struct DevicesProviderWrapper: DevicesProvider {
    
    static func delete(_ device: DeviceSim) async throws {
        try await CliTool.SimCtl.delete(device)
    }
    
    static func erase(_ device: DeviceSim) async throws {
        try await CliTool.SimCtl.erase(device)
    }
    
    static func boot(_ device: DeviceSim) async throws {
        try await CliTool.SimCtl.boot(device)
    }
    
    static func shutdown(_ device: DeviceSim) async throws {
        try await CliTool.SimCtl.shutdown(device)
    }
    
    static func devices() async throws -> CliTool.SimCtl.List.Devices {
        try await CliTool.SimCtl.List.devices()
    }

    static func apps(_ device: DeviceSim) async throws -> [SimApp] {
        try await CliTool.SimCtl.apps(device)
    }
}

extension CliTool {
    
    static func xcodeVersion() async throws -> String {
        let binary = URL(fileURLWithPath: CliTool.SimCtl.executable, isDirectory: false)
            .deletingLastPathComponent()
            .appendingPathComponent("xcodebuild", isDirectory: false)
        let output = try await CliTool.exec(binary.path, arguments: ["-version"])
        return output.components(separatedBy: .newlines)[0]
    }
    
    static func simulatorApp() -> String {
        guard CliTool.SimCtl.executable != "/usr/bin/xcrun" else {
            return "Simulator"
        }
        return URL(fileURLWithPath: CliTool.SimCtl.executable, isDirectory: false)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Applications/Simulator.app", isDirectory: true)
            .path
    }
    
    struct SimCtl {

        static func setPreviewsMode(_ enabled: Bool) {
            guard previewsMode != enabled else {
                return
            }
            let args = ["--set", "previews"]
            for arg in args {
                if self.args.contains(arg) {
                    if enabled {
                        continue
                    } else {
                        self.args.removeAll(where: { $0 == arg })
                    }
                } else {
                    if enabled {
                        self.args.append(arg)
                    } else {
                        continue
                    }
                }
            }
            previewsMode = enabled
        }
        
        nonisolated(unsafe) fileprivate static var args: [String] = ["simctl"]
        nonisolated(unsafe) fileprivate static var executable = "/usr/bin/xcrun"
        nonisolated(unsafe) fileprivate static var previewsMode = false

        static func setExecutable(_ executable: URL) async throws {
            let output = try await CliTool.exec(executable.path, arguments: ["--version"])
            assert(output.contains("PROGRAM:simctl  PROJECT:CoreSimulator"))
            self.executable = executable.path
            self.args = []
            self.setPreviewsMode(previewsMode)
        }
        
        static var simulatorsRootPath: URL {
            if previewsMode {
                return URL(fileURLWithPath: "/Users/\(NSUserName())/Library/Developer/Xcode/UserData/Previews/Simulator Devices", isDirectory: true)
            } else {
                return URL(fileURLWithPath: "/Users/\(NSUserName())/Library/Developer/CoreSimulator/Devices", isDirectory: true)
            }
        }
        
        static func delete(_ device: DeviceSim) async throws {
            _ = try await CliTool.exec(SimCtl.executable, arguments: args + ["delete", device.udid])
        }
        
        static func erase(_ device: DeviceSim) async throws {
            _ = try await CliTool.exec(SimCtl.executable, arguments: args + ["erase", device.udid])
        }
        
        static func boot(_ device: DeviceSim) async throws {
            _ = try await CliTool.exec(SimCtl.executable, arguments: args + ["boot", device.udid])
            _ = try await CliTool.exec(SimCtl.executable, arguments: args + ["bootstatus", device.udid])
        }
        
        static func shutdown(_ device: DeviceSim) async throws {
            _ = try await CliTool.exec(SimCtl.executable, arguments: args + ["shutdown", device.udid])
            if !previewsMode, try await Self.List.devices().devices.values.flatMap({ $0 }).filter({ $0.state == "Booted" }).isEmpty {
                try await EnvironmentValues().bashService.kill(.init(name: "Simulator"))
            }
        }
        
        static func create(_ device: DeviceSim, runtime: CliTool.SimCtl.List.Runtimes.Runtime, name: String?) async throws {
            _ = try await CliTool.exec(SimCtl.executable, arguments: args + ["create", "\(name ?? device.name)", device.deviceTypeIdentifier!, runtime.identifier])
        }
        
        static func create(_ device: SupportedDeviceType, runtime: CliTool.SimCtl.List.Runtimes.Runtime, name: String?) async throws {
            _ = try await CliTool.exec(SimCtl.executable, arguments: args + ["create", "\(name ?? device.name)", device.identifier, runtime.identifier])
        }

        static func apps(_ device: DeviceSim) async throws -> [SimApp] {
            let rawDictionary = try await CliTool.exec(SimCtl.executable, arguments: args + ["listapps", device.udid])
            do {
                let json = convertNestedNSDictionaryOutputToJSON(rawDictionary) ?? rawDictionary
                let object = try JSONDecoder().decode([String: Self.SimApp].self, from: json.data(using: .utf8)!)
                return Array(object.values)
            } catch {
                throw CliToolError.decode(error)
            }
        }

        struct SimApp: Decodable {

            let ApplicationType: String
            let Bundle: String
            let CFBundleDisplayName: String
            let CFBundleExecutable: String
            let CFBundleIdentifier: String
            let CFBundleName: String
            let CFBundleVersion: String
            let DataContainer: String?
            let GroupContainers: [String: String]
            let Path: String
        }
        
        struct Runtime {
            
            fileprivate static var args: [String] { SimCtl.args + ["runtime"] }
            
            static func delete(_ runtime: CliTool.SimCtl.List.Runtimes.Runtime) async throws {
                _ = try await CliTool.exec(SimCtl.executable, arguments: args + ["delete", runtime.id])
            }
            
            static func list() async throws -> [Self.Runtime] {
                if SimCtl.previewsMode, !FileManager.default.fileExists(atPath: SimCtl.simulatorsRootPath.path) {
                    return []
                }
                let json = try await CliTool.exec(SimCtl.executable, arguments: args + ["list"] + Format.json)
                do {
                    let object = try JSONDecoder().decode([String: Self.Runtime].self, from: json.data(using: .utf8)!)
                    return Array(object.values)
                } catch {
                    throw CliToolError.decode(error)
                }
            }
            
            struct Runtime: Decodable {
                
                let build: String
                let deletable: Bool
                let identifier: String
                let kind: String
                let lastUsedAt: String?
                let mountPath: String?
                let path: String
                let platformIdentifier: String
                let runtimeBundlePath: String?
                let runtimeIdentifier: String
                let signatureState: String
                let sizeBytes: Int
                let state: String
                let version: String
            }
        }
        
        struct List {
            
            fileprivate static var args: [String] { SimCtl.args + ["list"] }
            
            static func devices() async throws -> Devices {
                if SimCtl.previewsMode, !FileManager.default.fileExists(atPath: SimCtl.simulatorsRootPath.path) {
                    return Devices(devices: [:])
                }
                let json = try await CliTool.exec(SimCtl.executable, arguments: args + ["devices"] + Format.json)
                do {
                    return try JSONDecoder().decode(Devices.self, from: json.data(using: .utf8)!)
                } catch {
                    throw CliToolError.decode(error)
                }
            }
            
            static func runtimes() async throws -> Runtimes {
                if SimCtl.previewsMode, !FileManager.default.fileExists(atPath: SimCtl.simulatorsRootPath.path) {
                    return Runtimes(runtimes: [])
                }
                let json = try await CliTool.exec(SimCtl.executable, arguments: args + ["runtimes"] + Format.json)
                do {
                    let runtimes = try JSONDecoder().decode(Runtimes.self, from: json.data(using: .utf8)!)
                    return runtimes
                } catch {
                    throw CliToolError.decode(error)
                }
            }
            
            struct Devices: Decodable {
                
                let devices: [String: [Device]]
                
                struct Device: Decodable, HashableIdentifiable {
                    
                    var id: String { "\(udid)+\(state)+\(dataPathSize)" }
                    
                    let lastBootedAt: String?
                    let dataPath: String
                    let dataPathSize: Int
                    let logPath: String
                    let udid: String
                    let isAvailable: Bool
                    let availabilityError: String?
                    let logPathSize: Int?
                    let deviceTypeIdentifier: String?
                    let state: String
                    let name: String
                }
            }
            
            struct Runtimes: Decodable {
                
                let runtimes: [Runtime]
                
                struct Runtime: Decodable, HashableIdentifiable {
                    
                    var id: String { buildversion }
                    
                    let bundlePath: String
                    let buildversion: String
                    let platform: String
                    let runtimeRoot: String
                    let identifier: String
                    let version: String
                    let isInternal: Bool
                    let isAvailable: Bool
                    let name: String
                    let supportedDeviceTypes: [SupportedDeviceType]
                    
                    struct SupportedDeviceType: Decodable {
                        
                        let bundlePath: String
                        let name: String
                        let identifier: String
                        let productFamily: String
                    }
                }
            }
        }
        
        fileprivate enum Format {
            
            static let json: [String] = ["-j"]
        }
    }
}

// Clause 4 Sonnet
func convertNestedNSDictionaryOutputToJSON(_ consoleOutput: String) -> String? {
    let parser = NSDictionaryParser(consoleOutput)
    return parser.parse()
}

private class NSDictionaryParser {
    private let input: String
    private var position: String.Index

    init(_ input: String) {
        self.input = input.trimmingCharacters(in: .whitespacesAndNewlines)
        self.position = self.input.startIndex
    }

    func parse() -> String? {
        guard let result = parseValue() else { return nil }

        // Convert to JSON data and back to ensure proper formatting
        if let jsonData = try? JSONSerialization.data(withJSONObject: result, options: [.prettyPrinted, .sortedKeys]),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            return jsonString
        }

        return nil
    }

    private func parseValue() -> Any? {
        skipWhitespace()

        guard position < input.endIndex else { return nil }

        let char = input[position]

        if char == "{" {
            return parseDictionary()
        } else if char == "(" {
            return parseArray()
        } else if char == "\"" {
            return parseQuotedString()
        } else {
            return parseUnquotedValue()
        }
    }

    private func parseDictionary() -> [String: Any]? {
        guard position < input.endIndex && input[position] == "{" else { return nil }

        position = input.index(after: position) // skip '{'
        skipWhitespace()

        var dict: [String: Any] = [:]

        while position < input.endIndex && input[position] != "}" {
            skipWhitespace()

            // Parse key
            guard let key = parseKey() else { break }

            skipWhitespace()

            // Expect '='
            guard position < input.endIndex && input[position] == "=" else { break }
            position = input.index(after: position)

            skipWhitespace()

            // Parse value
            guard let value = parseValue() else { break }

            dict[key] = value

            skipWhitespace()

            // Skip semicolon if present
            if position < input.endIndex && input[position] == ";" {
                position = input.index(after: position)
            }

            skipWhitespace()
        }

        // Skip closing '}'
        if position < input.endIndex && input[position] == "}" {
            position = input.index(after: position)
        }

        return dict
    }

    private func parseArray() -> [Any]? {
        guard position < input.endIndex && input[position] == "(" else { return nil }

        position = input.index(after: position) // skip '('
        skipWhitespace()

        var array: [Any] = []

        while position < input.endIndex && input[position] != ")" {
            skipWhitespace()

            guard let value = parseValue() else { break }
            array.append(value)

            skipWhitespace()

            // Skip comma if present
            if position < input.endIndex && input[position] == "," {
                position = input.index(after: position)
            }

            skipWhitespace()
        }

        // Skip closing ')'
        if position < input.endIndex && input[position] == ")" {
            position = input.index(after: position)
        }

        return array
    }

    private func parseKey() -> String? {
        skipWhitespace()

        if position < input.endIndex && input[position] == "\"" {
            return parseQuotedString()
        } else {
            return parseUnquotedKey()
        }
    }

    private func parseQuotedString() -> String? {
        guard position < input.endIndex && input[position] == "\"" else { return nil }

        position = input.index(after: position) // skip opening quote
        let start = position

        while position < input.endIndex {
            let char = input[position]
            if char == "\"" {
                let result = String(input[start..<position])
                position = input.index(after: position) // skip closing quote
                return result
            } else if char == "\\" {
                // Handle escaped characters - for simplicity, just move past them
                position = input.index(after: position)
                if position < input.endIndex {
                    position = input.index(after: position)
                }
            } else {
                position = input.index(after: position)
            }
        }

        return nil
    }

    private func parseUnquotedKey() -> String? {
        skipWhitespace()
        let start = position

        while position < input.endIndex {
            let char = input[position]
            if char.isWhitespace || char == "=" {
                break
            }
            position = input.index(after: position)
        }

        guard start < position else { return nil }
        return String(input[start..<position])
    }

    private func parseUnquotedValue() -> Any? {
        skipWhitespace()
        let start = position

        while position < input.endIndex {
            let char = input[position]
            if char == ";" || char == "}" || char == ")" || char == "," {
                break
            }
            position = input.index(after: position)
        }

        guard start < position else { return nil }
        let valueString = String(input[start..<position]).trimmingCharacters(in: .whitespacesAndNewlines)

        // Try to parse as number
        if valueString.lowercased() == "true" {
            return true
        } else if valueString.lowercased() == "false" {
            return false
        } else {
            return valueString
        }
    }

    private func skipWhitespace() {
        while position < input.endIndex && input[position].isWhitespace {
            position = input.index(after: position)
        }
    }
}
