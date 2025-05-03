
import SwiftUI

enum CoreSimulatorLogs { }

extension CoreSimulatorLogs {
    
    @MainActor
    protocol Interface: Sendable {
        
        nonisolated func logs() async -> [LogItem]
        nonisolated func open() async
        nonisolated func delete(_ log: LogItem) async throws
    }
}

extension CoreSimulatorLogs {
    
    final class Service: Interface {
        
        private let bashService: BashProvider.Type
        
        init(bashService: BashProvider.Type) {
            self.bashService = bashService
        }
        
        private let root = URL(
            fileURLWithPath: "/Users/\(NSUserName())/Library/Logs/CoreSimulator",
            isDirectory: true
        )
        
        func logs() async -> [LogItem] {
            let task = Task<[LogItem], Never>(priority: .high) { [self] in
                let fileManager = FileManager.default
                guard fileManager.fileExists(atPath: root.path) else {
                    return []
                }
                return ((try? FileManager.default.contentsOfDirectory(atPath: root.path)) ?? [])
                    .filter({ $0.count == 36 })
                    .map({ LogItem(udid: $0, path: root.appendingPathComponent($0, isDirectory: true)) })
            }
            return await task.value
        }
        
        func open() async {
            try? await bashService.open(root)
        }
        
        func delete(_ log: LogItem) async throws {
            try await bashService.rmDir(log.path)
        }
    }
}

extension CoreSimulatorLogs {
    
    fileprivate final class ServiceEmpty: ServiceMock { }
}

extension CoreSimulatorLogs {
    
    class ServiceMock: Interface {
        static let shared = ServiceMock()
        func logs() async -> [LogItem] { [] }
        func open() async { }
        func delete(_ log: LogItem) async throws { }
    }
}

extension CoreSimulatorLogs {
    
    struct LogItem: HashableIdentifiable {
        
        var id: String { udid }
        
        let udid: String
        let path: URL
    }
}

extension EnvironmentValues {
    
    @Entry var coreSimulatorLogsService: CoreSimulatorLogs.Interface = CoreSimulatorLogs.ServiceEmpty()
}

extension View {
    
    func withCoreSimulatorLogsService(_ coreSimulatorLogsService: CoreSimulatorLogs.Interface) -> some View {
        environment(\.coreSimulatorLogsService, coreSimulatorLogsService)
    }
}
