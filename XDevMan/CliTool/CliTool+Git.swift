
import SwiftUI

typealias Branch = CliTool.Git.Branch
typealias Commit = CliTool.Git.Commit

protocol GitProvider: Sendable {
    
    @discardableResult
    static func status() async throws -> String
    static func branches(_ path: URL) async throws -> [Branch]
    static func delete(_ path: URL, branch: Branch) async throws
    static func commits(_ path: URL, branch: Branch?, last: UInt) async throws -> [Commit]
    static func tagAtHead(_ path: URL) async throws -> String?
    static func remote(_ path: URL) async throws -> URL?
}

private struct GitProviderWrapper: GitProvider {
    
    static func status() async throws -> String {
        try await CliTool.Git.status()
    }
    
    static func branches(_ path: URL) async throws -> [Branch] {
        try await CliTool.Git.branches(path)
    }
    
    static func delete(_ path: URL, branch: Branch) async throws {
        try await CliTool.Git.delete(path, branch: branch)
    }
    
    static func commits(_ path: URL, branch: Branch?, last: UInt) async throws -> [Commit] {
        try await CliTool.Git.commits(path, branch: branch, last: last)
    }
    
    static func tagAtHead(_ path: URL) async throws -> String? {
        try await CliTool.Git.tagAtHead(path)
    }
    
    static func remote(_ path: URL) async throws -> URL? {
        try await CliTool.Git.remote(path)
    }
}

class GitProviderMock: GitProvider {
    
    class func delete(_ path: URL, branch: Branch) async throws { }
    class func commits(_ path: URL, branch: Branch?, last: UInt) async throws -> [Commit] { [] }
    class func status() async throws -> String { "" }
    class func branches(_ path: URL) async throws -> [Branch] { [] }
    class func tagAtHead(_ path: URL) async throws -> String? { nil }
    static func remote(_ path: URL) async throws -> URL? { nil }
    
    init() { }
}

extension EnvironmentValues {
    
    @Entry var gitService: GitProvider.Type = GitProviderWrapper.self
}

extension View {
    
    func withGitService(_ gitService: GitProvider.Type) -> some View {
        environment(\.gitService, gitService)
    }
}

extension CliTool {
    
    struct Git {
        
        fileprivate static let executable = "/usr/bin/git"
        
        fileprivate static func remote(_ path: URL) async throws -> URL? {
            let raw = try await CliTool.exec(Git.executable, arguments: ["-C", path.path, "config", "--get", "remote.origin.url"])
            guard raw.isEmpty == false else {
                return nil
            }
            guard let string = raw.components(separatedBy: .newlines).first,
                string.isEmpty == false else {
                return nil
            }
            if string.hasPrefix("http") {
                return URL(string: string)
            }
            guard string.hasPrefix("git@") else {
                return nil
            }
            let url = string
                .replacingOccurrences(of: ":", with: "/")
                .replacingOccurrences(of: "git@", with: "https://")
            return URL(string: url)
        }
        
        fileprivate static func status() async throws -> String {
            try await CliTool.exec(Git.executable, arguments: ["status", "-sb"])
        }
        
        fileprivate static func tagAtHead(_ path: URL) async throws -> String? {
            let raw = try await CliTool.exec(Git.executable, arguments: ["-C", path.path, "tag", "--points-at", "HEAD"])
            return raw.isEmpty ? nil : raw.components(separatedBy: .newlines).first
        }
        
        fileprivate static func commits(_ path: URL, branch: Branch?, last: UInt = 5) async throws -> [Commit] {
            let raw = try await CliTool.exec(Git.executable, arguments: ["-C", path.path, "log", branch?.nameFixed ?? "HEAD", "-\(last)"])
            return parse(log: raw)
        }
        
        fileprivate static func branches(_ path: URL) async throws -> [Branch] {
            let output = try await CliTool.exec(Git.executable, arguments: ["-C", path.path, "branch"])
            return output
                .components(separatedBy: .newlines)
                .filter({ !$0.isEmpty })
                .map({ $0.replacingOccurrences(of: " ", with: "") })
                .map(Branch.init(name:))
        }
        
        fileprivate static func delete(_ path: URL, branch: Branch) async throws {
            _ = try await CliTool.exec(Git.executable, arguments: ["-C", path.path, "branch", "-D", branch.nameFixed])
        }
        
        struct Branch: @MainActor HashableIdentifiable {
            
            var id: String { name }
            var isProtected: Bool { Self.protected.contains(name) || isCurrent }
            var isCurrent: Bool { name.hasPrefix("*") }
            fileprivate var nameFixed: String { isCurrent ? String(name.dropFirst()) : name  }
            
            let name: String
            
            private static let protected: [String] = [
                "main", "master", "dev", "develop", "development"
            ]
            
        }
        
        static func parse(log: String) -> [Commit] {
            var commits: [Commit] = []
            let lines = log.components(separatedBy: .newlines).filter({ $0.hasPrefix("Merge:") == false })
            let commitIndexes = lines
                .enumerated()
                .filter({ $0.element.hasPrefix("commit") })
                .map({ $0.offset })
            for (index, position) in commitIndexes.enumerated() {
                var commit = Commit()
                commit.commit = lines[position]
                commit.hash = lines[position].components(separatedBy: .whitespaces)[1]
                if lines[position].contains("tag: ") {
                    commit.tag = String(lines[position].components(separatedBy: "tag: ")[1].dropLast())
                }
                for (idx, line) in lines.enumerated() where idx > position {
                    if commit.author.isEmpty {
                        commit.author = line
                    } else if commit.date.isEmpty {
                        commit.date = line
                    } else {
                        if line.isEmpty {
                            continue
                        }
                        if index != commitIndexes.count - 1 {
                            if commitIndexes[index + 1] == idx {
                                break
                            } else {
                                commit.message += line + "\n"
                            }
                        } else {
                            commit.message += line + "\n"
                        }
                    }
                }
                commits.append(commit)
            }
            return commits
        }
        
        struct Commit: @MainActor HashableIdentifiable {
            
            var id: String { commit }
            
            
            fileprivate(set) var commit: String = ""
            fileprivate(set) var hash: String = ""
            fileprivate(set) var tag: String = ""
            fileprivate(set) var author: String = ""
            fileprivate(set) var date: String = ""
            fileprivate(set) var message: String = ""
            
            init(commit: String, hash: String, tag: String, author: String, date: String, message: String) {
                self.commit = commit
                self.hash = hash
                self.tag = tag
                self.author = author
                self.date = date
                self.message = message
            }
            
            init() {}
        }
    }
}
