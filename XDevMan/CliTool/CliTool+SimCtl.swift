
import SwiftUI

typealias Runtime = CliTool.SimCtl.List.Runtimes.Runtime
typealias RuntimeInternal = CliTool.SimCtl.Runtime.Runtime
typealias DevicesSim = CliTool.SimCtl.List.Devices
typealias DeviceSim = DevicesSim.Device
typealias SupportedDeviceType = Runtime.SupportedDeviceType

protocol RuntimesProvider {
    
    static func runtimes() async throws -> CliTool.SimCtl.List.Runtimes
    static func list() async throws -> [RuntimeInternal]
    static func delete(_ runtime: Runtime) async throws
    static func create(_ device: SupportedDeviceType, runtime: Runtime, name: String?) async throws
    static func create(_ device: DeviceSim, runtime: Runtime, name: String?) async throws
    static func isBeta(_ runtime: Runtime) async throws -> Bool
}

class RuntimesProviderMock: RuntimesProvider {
    
    class func list() async throws -> [RuntimeInternal] { [] }
    class func create(_ device: SupportedDeviceType, runtime: Runtime, name: String?) async throws { }
    static func create(_ device: DeviceSim, runtime: Runtime, name: String?) async throws { }
    class func delete(_ runtime: Runtime) async throws { }
    class func runtimes() async throws -> CliTool.SimCtl.List.Runtimes { .init(runtimes: []) }
    class func isBeta(_ runtime: Runtime) async throws -> Bool { false }
}

protocol DevicesProvider {
    
    static func devices() async throws -> CliTool.SimCtl.List.Devices
    static func delete(_ device: DeviceSim) async throws
    static func boot(_ device: DeviceSim) async throws
    static func shutdown(_ device: DeviceSim) async throws
}

class DevicesProviderMock: DevicesProvider {
    
    class func devices() async throws -> CliTool.SimCtl.List.Devices { fatalError() }
    class func delete(_ device: DeviceSim) async throws { }
    class func boot(_ device: DeviceSim) async throws { }
    class func shutdown(_ device: DeviceSim) async throws { }
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
        let task = Task<Bool, Error>.detached {
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
}

private struct DevicesProviderWrapper: DevicesProvider {
    
    static func delete(_ device: DeviceSim) async throws {
        try await CliTool.SimCtl.delete(device)
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
        
        nonisolated(unsafe) fileprivate static var args: [String] = ["simctl"]
        nonisolated(unsafe) fileprivate static var executable = "/usr/bin/xcrun"
        
        static func setExecutable(_ executable: URL) async throws {
            let output = try await CliTool.exec(executable.path, arguments: ["--version"])
            assert(output.contains("PROGRAM:simctl  PROJECT:CoreSimulator"))
            self.executable = executable.path
            self.args = []
        }
        
        static func delete(_ device: DeviceSim) async throws {
            _ = try await CliTool.exec(SimCtl.executable, arguments: args + ["delete", device.udid])
        }
        
        static func boot(_ device: DeviceSim) async throws {
            _ = try await CliTool.exec(SimCtl.executable, arguments: args + ["boot", device.udid])
            _ = try await CliTool.exec(SimCtl.executable, arguments: args + ["bootstatus", device.udid])
        }
        
        static func shutdown(_ device: DeviceSim) async throws {
            _ = try await CliTool.exec(SimCtl.executable, arguments: args + ["shutdown", device.udid])
            if try await Self.List.devices().devices.values.flatMap({ $0 }).filter({ $0.state == "Booted" }).isEmpty {
                try await EnvironmentValues().bashService.kill(.init(name: "Simulator"))
            }
        }
        
        static func create(_ device: DeviceSim, runtime: CliTool.SimCtl.List.Runtimes.Runtime, name: String?) async throws {
            _ = try await CliTool.exec(SimCtl.executable, arguments: args + ["create", "\(name ?? device.name)", device.deviceTypeIdentifier!, runtime.identifier])
        }
        
        static func create(_ device: SupportedDeviceType, runtime: CliTool.SimCtl.List.Runtimes.Runtime, name: String?) async throws {
            _ = try await CliTool.exec(SimCtl.executable, arguments: args + ["create", "\(name ?? device.name)", device.identifier, runtime.identifier])
        }
        
        struct Runtime {
            
            fileprivate static var args: [String] { SimCtl.args + ["runtime"] }
            
            static func delete(_ runtime: CliTool.SimCtl.List.Runtimes.Runtime) async throws {
                _ = try await CliTool.exec(SimCtl.executable, arguments: args + ["delete", runtime.id])
            }
            
            static func list() async throws -> [Self.Runtime] {
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
                let json = try await CliTool.exec(SimCtl.executable, arguments: args + ["devices"] + Format.json)
                do {
                    return try JSONDecoder().decode(Devices.self, from: json.data(using: .utf8)!)
                } catch {
                    throw CliToolError.decode(error)
                }
            }
            
            static func runtimes() async throws -> Runtimes {
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
