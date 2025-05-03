
import SwiftUI

struct IBSupportItem: HashableIdentifiable {
    
    var id: String { udid }
    
    let name: String
    let path: URL
    let udid: String
    let runtime: String
    let deviceType: String
}

@MainActor
protocol IBSupportServiceInterface: Sendable {
    
    nonisolated func simulatorDevices() async -> [IBSupportItem]
    @discardableResult nonisolated func open() async -> Bool
    nonisolated func open(_ item: IBSupportItem) async throws
    nonisolated func delete(_ item: IBSupportItem) async throws
    nonisolated func size() async -> String?
    nonisolated func size(_ item: IBSupportItem) async throws -> String
}

final class IBSupportService: IBSupportServiceInterface {
    
    private let root = URL(
        fileURLWithPath: "/Users/\(NSUserName())/Library/Developer/Xcode/UserData/IB Support/Simulator Devices",
        isDirectory: true
    )
    
    private let bashService: BashProvider.Type
    
    init(bashService: BashProvider.Type) {
        self.bashService = bashService
    }
    
    func simulatorDevices() async -> [IBSupportItem] {
        let task = Task<[IBSupportItem], Never>(priority: .high) { [self] in
            let fileManager = FileManager.default
            guard fileManager.fileExists(atPath: root.path) else {
                return []
            }
            return ((try? FileManager.default.contentsOfDirectory(atPath: root.path)) ?? [])
                .filter({ $0 != ".DS_Store" })
                .filter({ $0.count == 36 })
                .compactMap({ name -> IBSupportItem? in
                    let path = root.appendingPathComponent(name, isDirectory: true)
                    let plist = path.appendingPathComponent("device.plist", isDirectory: false)
                    guard fileManager.fileExists(atPath: plist.path) else {
                        return nil
                    }
                    guard let dict = NSDictionary(contentsOf: plist) else {
                        return nil
                    }
                    guard let name = dict["name"] as? String,
                          let udid = dict["UDID"] as? String,
                          let runtime = dict["runtime"] as? String,
                          let deviceType = dict["deviceType"] as? String else {
                        return nil
                    }
                    return IBSupportItem(name: name, path: path, udid: udid, runtime: runtime, deviceType: deviceType)
                })
        }
        return await task.value
    }
    
    func open() async -> Bool {
        await Task<Bool, Never>(priority: .high) { [root, bashService] in
            var url = root.deletingLastPathComponent()
            while FileManager.default.fileExists(atPath: url.path) == false {
                url = url.deletingLastPathComponent()
            }
            return (try? await bashService.open(url)) != nil
        }.value
    }
    
    func open(_ item: IBSupportItem) async throws {
        try await bashService.open(item.path)
    }
    
    func delete(_ item: IBSupportItem) async throws {
        try await bashService.rmDir(item.path)
    }
    
    func size() async -> String? {
        await Task<String?, Never>(priority: .high) { [root, bashService] in
            guard FileManager.default.fileExists(atPath: root.path) else {
                return nil
            }
            return try? await bashService.size(root)
        }.value
    }
    
    func size(_ item: IBSupportItem) async throws -> String {
        try await bashService.size(item.path)
    }
}

private final class IBSupportServiceEmpty: IBSupportServiceMock { }

class IBSupportServiceMock: IBSupportServiceInterface {
    static let shared = IBSupportServiceMock()
    func simulatorDevices() async -> [IBSupportItem] { [] }
    func open() async -> Bool { false }
    func open(_ item: IBSupportItem) async throws { }
    func delete(_ item: IBSupportItem) async throws { }
    func size() async -> String? { nil }
    func size(_ item: IBSupportItem) async throws -> String { "" }
}

extension EnvironmentValues {
    
    @Entry var ibSupportService: IBSupportServiceInterface = IBSupportServiceEmpty()
}

extension View {
    
    func withIBSupportService(_ ibSupportService: IBSupportServiceInterface) -> some View {
        environment(\.ibSupportService, ibSupportService)
    }
}
