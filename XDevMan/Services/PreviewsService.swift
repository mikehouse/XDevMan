
import SwiftUI

struct PreviewsItem: HashableIdentifiable {
    
    var id: String { udid }
    
    let name: String
    let path: URL
    let udid: String
    let runtime: String
}

@MainActor
protocol PreviewsServiceInterface: Sendable {
    
    nonisolated func simulatorDevices() async -> [PreviewsItem]
    @discardableResult nonisolated func open() async -> Bool
    nonisolated func open(_ item: PreviewsItem) async throws
    nonisolated func delete(_ item: PreviewsItem) async throws
    nonisolated func size() async -> String?
    nonisolated func size(_ item: PreviewsItem) async throws -> String
}

final class PreviewsService: PreviewsServiceInterface {
    
    private let root = URL(
        fileURLWithPath: "/Users/\(NSUserName())/Library/Developer/Xcode/UserData/Previews/Simulator Devices",
        isDirectory: true
    )
    
    private let bashService: BashProvider.Type
    
    init(bashService: BashProvider.Type) {
        self.bashService = bashService
    }
    
    func simulatorDevices() async -> [PreviewsItem] {
        let task = Task<[PreviewsItem], Never>(priority: .high) { [self] in
            let fileManager = FileManager.default
            guard fileManager.fileExists(atPath: root.path) else {
                return []
            }
            return ((try? FileManager.default.contentsOfDirectory(atPath: root.path)) ?? [])
                .filter({ $0 != ".DS_Store" })
                .filter({ $0.count == 36 })
                .compactMap({ name -> PreviewsItem? in
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
                          let runtime = dict["runtime"] as? String else {
                        return nil
                    }
                    return PreviewsItem(name: name, path: path, udid: udid, runtime: runtime)
                })
        }
        return await task.value
    }
    
    func open() async -> Bool {
        await Task<Bool, Never>(priority: .high) { [self] in
            var url = root.deletingLastPathComponent()
            while FileManager.default.fileExists(atPath: url.path) == false {
                url = url.deletingLastPathComponent()
            }
            return (try? await bashService.open(url)) != nil
        }.value
    }
    
    func open(_ item: PreviewsItem) async throws {
        try await bashService.open(item.path)
    }
    
    func delete(_ item: PreviewsItem) async throws {
        try await bashService.rmDir(item.path)
    }
    
    func size() async -> String? {
        await Task<String?, Never>(priority: .high) { [self] in
            guard FileManager.default.fileExists(atPath: root.path) else {
                return nil
            }
            return try? await bashService.size(root)
        }.value
    }
    
    func size(_ item: PreviewsItem) async throws -> String {
        try await bashService.size(item.path)
    }
}

private final class PreviewsServiceEmpty: PreviewsServiceMock { }

class PreviewsServiceMock: PreviewsServiceInterface {
    static let shared = PreviewsServiceMock()
    func simulatorDevices() async -> [PreviewsItem] { [] }
    func open() async -> Bool { false }
    func open(_ item: PreviewsItem) async throws { }
    func delete(_ item: PreviewsItem) async throws { }
    func size() async -> String? { nil }
    func size(_ item: PreviewsItem) async throws -> String { "" }
}

extension EnvironmentValues {
    
    @Entry var previewsService: PreviewsServiceInterface = PreviewsServiceEmpty()
}

extension View {
    
    func withPreviewsService(_ previewsService: PreviewsServiceInterface) -> some View {
        environment(\.previewsService, previewsService)
    }
}
