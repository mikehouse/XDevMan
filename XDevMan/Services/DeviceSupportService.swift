
import SwiftUI

struct DeviceSupportOs: @MainActor HashableIdentifiable {
    
    var id: String { "\(name)+\(items.count)" }
    
    let name: String
    let path: URL
    let items: [DeviceSupportOsItem]
}

struct DeviceSupportOsItem: @MainActor HashableIdentifiable {
    
    var id: String { name }
    
    let name: String
    let path: URL
    
    var displayName: String? {
        guard let model = name.components(separatedBy: .whitespaces).first else {
            return nil
        }
        let device = Device.mapToDevice(identifier: model)
        switch device {
        case .unknown:
            return nil
        default:
            return "\(device.description)\(name.dropFirst(model.count))"
        }
    }
}

@MainActor
protocol DeviceSupportServiceInterface: Sendable {
    
    func osList() async -> [DeviceSupportOs]
}

final class DeviceSupportService: DeviceSupportServiceInterface {
    
    private let bashService: BashProvider.Type
    private let root = URL(fileURLWithPath: "/Users/\(NSUserName())/Library/Developer/Xcode", isDirectory: true)
    
    init(bashService: BashProvider.Type) {
        self.bashService = bashService
    }
    
    func osList() async -> [DeviceSupportOs] {
        let task = Task<[DeviceSupportOs], Never> { [self] in
            let fileManager = FileManager.default
            guard fileManager.fileExists(atPath: root.path) else {
                return []
            }
            let list = ((try? fileManager.contentsOfDirectory(atPath: root.path)) ?? [])
                .filter({ $0.hasSuffix("OS DeviceSupport") })
                .sorted()
            return list.compactMap { item in
                let path = root.appendingPathComponent(item, isDirectory: true)
                guard ((try? fileManager.contentsOfDirectory(atPath: path.path)) ?? [])
                    .filter({ $0 != ".DS_Store" }).isEmpty == false else {
                        return nil
                    }
                let list = ((try? fileManager.contentsOfDirectory(atPath: path.path)) ?? [])
                    .filter({ $0.hasSuffix(")") })
                    .sorted()
                let items = list.map { item in
                    DeviceSupportOsItem(
                        name: item,
                        path: path.appendingPathComponent(item, isDirectory: true)
                    )
                }
                return DeviceSupportOs(
                    name: String(item.dropLast(" DeviceSupport".count)),
                    path: path,
                    items: items
                )
            }
        }
        return await task.value
    }
}

private final class DeviceSupportServiceEmpty: DeviceSupportServiceMock { }

class DeviceSupportServiceMock: DeviceSupportServiceInterface {
    static let shared = DeviceSupportServiceMock()
    init() { }
    func osList() async -> [DeviceSupportOs] { [] }
}

extension EnvironmentValues {
    
    @Entry var deviceSupportService: DeviceSupportServiceInterface = DeviceSupportServiceEmpty()
}

extension View {
    
    func withDeviceSupportService(_ deviceSupportService: DeviceSupportServiceInterface) -> some View {
        environment(\.deviceSupportService, deviceSupportService)
    }
}
