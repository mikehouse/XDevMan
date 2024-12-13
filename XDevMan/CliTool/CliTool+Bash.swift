
import SwiftUI

protocol BashProvider {
    
    static func ls(_ path: URL) async throws -> [String]
    static func rmFile(_ path: URL) async throws
    static func rmDir(_ path: URL) async throws
    static func open(_ path: URL) async throws
    static func open(_ path: URL, args: [String]) async throws
    static func open(_ app: CliTool.Bash.App) async throws
    static func open(_ app: CliTool.Bash.App, args: [String]) async throws
    static func size(_ path: URL) async throws -> String
    static func kill(_ app: CliTool.Bash.App) async throws
}

private struct BashProviderWrapper: BashProvider {
    
    static func ls(_ path: URL) async throws -> [String] {
        try await CliTool.Bash.ls(path)
    }
    
    static func rmFile(_ path: URL) async throws {
        try await CliTool.Bash.rmFile(path)
    }
    
    static func rmDir(_ path: URL) async throws {
        try await CliTool.Bash.rmDir(path)
    }
    
    static func open(_ path: URL) async throws {
        try await open(path, args: [])
    }
    
    static func open(_ path: URL, args: [String]) async throws {
        try await CliTool.Bash.open(path, args: args)
    }
    
    static func open(_ app: CliTool.Bash.App) async throws {
        try await open(app, args: [])
    }
    
    static func open(_ app: CliTool.Bash.App, args: [String]) async throws {
        try await CliTool.Bash.open(app, args: args)
    }
    
    static func size(_ path: URL) async throws -> String {
        try await CliTool.Bash.size(path)
    }
    
    static func kill(_ app: CliTool.Bash.App) async throws {
        try await CliTool.Bash.kill(app)
    }
}

class BashProviderMock: BashProvider {
    
    class func ls(_ path: URL) async throws -> [String] { [] }
    class func rmFile(_ path: URL) async throws { }
    class func rmDir(_ path: URL) async throws { }
    class func open(_ path: URL) async throws { }
    class func open(_ path: URL, args: [String]) async throws { }
    class func open(_ app: CliTool.Bash.App) async throws { }
    class func open(_ app: CliTool.Bash.App, args: [String]) async throws { }
    class func size(_ path: URL) async throws -> String { "0B" }
    class func kill(_ app: CliTool.Bash.App) async throws { }
}

extension EnvironmentValues {
    
    @Entry var bashService: BashProvider.Type = BashProviderWrapper.self
}

extension View {
    
    func withBashService(_ bashService: BashProvider.Type) -> some View {
        environment(\.bashService, bashService)
    }
}

extension CliTool {
    
    enum Bash {
        
        fileprivate static func ls(_ path: URL) async throws -> [String] {
            let output = try await CliTool.exec("/bin/ls", arguments: [path.path])
            return output.components(separatedBy: .newlines).filter({ !$0.isEmpty })
        }
        
        fileprivate static func rmFile(_ path: URL) async throws {
            do {
                try FileManager.default.trashItem(at: path, resultingItemURL: nil)
            } catch {
                throw CliToolError.fs(error)
            }
//            _ = try await CliTool.exec("/bin/rm", arguments: [path.path])
        }
        
        fileprivate static func rmDir(_ path: URL) async throws {
            do {
                try FileManager.default.trashItem(at: path, resultingItemURL: nil)
            } catch {
                throw CliToolError.fs(error)
            }
//            _ = try await CliTool.exec("/bin/rm", arguments: ["-fr", path.path])
        }
        
        fileprivate static func open(_ path: URL, args: [String]) async throws {
            _ = try await CliTool.exec("/usr/bin/open", arguments: [path.path] + args)
        }
        
        fileprivate static func open(_ app: App, args: [String]) async throws {
            _ = try await CliTool.exec("/usr/bin/open", arguments: ["-a", app.name] + args)
        }
        
        fileprivate static func size(_ path: URL) async throws -> String {
            let raw = try await CliTool.exec("/usr/bin/du", arguments: ["-sc", "--si", path.path])
            return raw.components(separatedBy: .newlines)[1]
                .components(separatedBy: .whitespaces).first(where: { !$0.isEmpty }) ?? ""
        }
        
        fileprivate static func kill(_ app: CliTool.Bash.App) async throws {
            _ = try await CliTool.exec("/usr/bin/killall", arguments: [app.name])
        }
        
        struct App {
            
            let name: String
        }
    }
}
