import Foundation
import SwiftUI

struct FastlaneLane: @MainActor HashableIdentifiable {
    
    var id: String { name }
    
    let name: String
    let inputs: [FastlaneLaneInput]
}

struct FastlaneLaneInput: @MainActor HashableIdentifiable {
    
    var id: String { name }
    
    let name: String
    let type: FastlaneLaneInputType
}

enum FastlaneLaneInputType: String, Sendable, Hashable {
    
    case bool = "Bool"
    case string = "String"
}

struct FastlaneScanResult: @MainActor HashableIdentifiable {
    
    var id: URL { selectedDirectory }
    
    let selectedDirectory: URL
    let fastlaneDirectory: URL
    let commandDirectory: URL
    let lanes: [FastlaneLane]
}

protocol FastlaneServiceInterface: Sendable {
    
    func scan(_ selectedDirectory: URL) async throws -> FastlaneScanResult
    func open(_ path: URL) async throws
    func runInTerminal(_ command: String) async throws
}

actor FastlaneService: FastlaneServiceInterface {
    
    private let bashService: BashProvider.Type
    
    init(bashService: BashProvider.Type) {
        self.bashService = bashService
    }
    
    func scan(_ selectedDirectory: URL) async throws -> FastlaneScanResult {
        let location = try resolveLocation(selectedDirectory)
        do {
            _ = try await bashService.ls(location.fastlaneDirectory)
        } catch {
            throw Errors.invalidDirectory
        }
        let readme: String
        let fastfile: String
        do {
            readme = try String(contentsOf: location.readme)
            fastfile = try String(contentsOf: location.fastfile)
        } catch {
            throw Errors.cannotReadFiles
        }
        let laneNames = parsePublicLanes(from: readme)
        guard laneNames.isEmpty == false else {
            throw Errors.noActionsFound
        }
        let parser = FastfileParser(source: fastfile)
        let lanes = laneNames.map({ lane in
            FastlaneLane(name: lane, inputs: parser.inputs(for: lane))
        })
        guard lanes.isEmpty == false else {
            throw Errors.noActionsFound
        }
        return FastlaneScanResult(
            selectedDirectory: location.selectedDirectory,
            fastlaneDirectory: location.fastlaneDirectory,
            commandDirectory: location.commandDirectory,
            lanes: lanes
        )
    }
    
    func open(_ path: URL) async throws {
        try await bashService.open(path)
    }
    
    func runInTerminal(_ command: String) async throws {
        try await bashService.runInTerminal(command)
    }
}

private extension FastlaneService {
    
    struct Location {
        let selectedDirectory: URL
        let fastlaneDirectory: URL
        let commandDirectory: URL
        let readme: URL
        let fastfile: URL
    }
    
    func resolveLocation(_ selectedDirectory: URL) throws -> Location {
        let fileManager = FileManager.default
        let rootFastlane = selectedDirectory.appendingPathComponent("fastlane", isDirectory: true)
        let rootReadme = rootFastlane.appendingPathComponent("README.md", isDirectory: false)
        let rootFastfile = rootFastlane.appendingPathComponent("Fastfile", isDirectory: false)
        if fileManager.fileExists(atPath: rootReadme.path), fileManager.fileExists(atPath: rootFastfile.path) {
            return .init(
                selectedDirectory: selectedDirectory,
                fastlaneDirectory: rootFastlane,
                commandDirectory: selectedDirectory,
                readme: rootReadme,
                fastfile: rootFastfile
            )
        }
        let directReadme = selectedDirectory.appendingPathComponent("README.md", isDirectory: false)
        let directFastfile = selectedDirectory.appendingPathComponent("Fastfile", isDirectory: false)
        if fileManager.fileExists(atPath: directReadme.path), fileManager.fileExists(atPath: directFastfile.path) {
            return .init(
                selectedDirectory: selectedDirectory,
                fastlaneDirectory: selectedDirectory,
                commandDirectory: selectedDirectory.deletingLastPathComponent(),
                readme: directReadme,
                fastfile: directFastfile
            )
        }
        throw Errors.invalidDirectory
    }
    
    func parsePublicLanes(from readme: String) -> [String] {
        let lines = readme.components(separatedBy: .newlines)
        guard let headerIndex = lines.firstIndex(where: { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == "# available actions" }) else {
            return []
        }
        var results: [String] = []
        var unique = Set<String>()
        for index in (headerIndex + 1)..<lines.count {
            let raw = lines[index].trimmingCharacters(in: .whitespacesAndNewlines)
            if raw == "----", results.isEmpty == false {
                break
            }
            guard raw.hasPrefix("### ") else {
                continue
            }
            let laneName = String(raw.dropFirst(4)).trimmingCharacters(in: .whitespacesAndNewlines)
            guard laneName.isEmpty == false else {
                continue
            }
            if unique.insert(laneName).inserted {
                results.append(laneName)
            }
        }
        return results
    }
}

private extension FastlaneService {
    
    enum Errors: LocalizedError {
        
        case invalidDirectory
        case cannotReadFiles
        case noActionsFound
        
        var errorDescription: String? {
            switch self {
            case .invalidDirectory:
                return "Unable to find fastlane files. Select a folder with fastlane"
            case .cannotReadFiles:
                return "Unable to read fastlane README.md or Fastfile."
            case .noActionsFound:
                return "No fastlane actions found."
            }
        }
    }
}

nonisolated private struct FastfileParser {
    
    private let definitions: [Definition]
    
    init(source: String) {
        let lines = source.components(separatedBy: .newlines)
        definitions = Self.parse(lines: lines, range: 0..<lines.count, platform: nil)
    }
    
    func inputs(for publicLane: String) -> [FastlaneLaneInput] {
        let tokens = publicLane.components(separatedBy: .whitespacesAndNewlines).filter({ $0.isEmpty == false })
        guard tokens.isEmpty == false else {
            return []
        }
        let laneName = tokens.last ?? ""
        let candidates = definitions.filter({ def in
            guard def.kind == .lane, def.name == laneName else {
                return false
            }
            return true
        })
        guard let lane = candidates.first else {
            return []
        }
        let resolved = collectOptions(for: lane, visited: [])
        return resolved.map({ .init(name: $0.name, type: $0.type) })
    }
}

nonisolated private extension FastfileParser {
    
    enum DefinitionKind: nonisolated Equatable {
        case lane
        case privateLane
        case function
    }
    
    struct Definition {
        let kind: DefinitionKind
        let name: String
        let platform: String?
        let optionVariable: String?
        let parameters: [String]
        let body: String
    }
    
    struct OptionItem {
        let name: String
        let type: FastlaneLaneInputType
    }
    
    static func parse(lines: [String], range: Range<Int>, platform: String?) -> [Definition] {
        var result: [Definition] = []
        var index = range.lowerBound
        while index < range.upperBound {
            let line = lines[index].trimmingCharacters(in: .whitespacesAndNewlines)
            if let platformName = parsePlatformStart(line),
               let end = blockEnd(lines: lines, startIndex: index),
               end < range.upperBound {
                result.append(contentsOf: parse(lines: lines, range: (index + 1)..<end, platform: platformName))
                index = end + 1
                continue
            }
            if let lane = parseLaneStart(line),
               let end = blockEnd(lines: lines, startIndex: index),
               end < range.upperBound {
                let body = lines[(index + 1)..<end].joined(separator: "\n")
                result.append(.init(
                    kind: .lane,
                    name: lane.name,
                    platform: platform,
                    optionVariable: lane.optionVariable,
                    parameters: [],
                    body: body
                ))
                index = end + 1
                continue
            }
            if let lane = parsePrivateLaneStart(line),
               let end = blockEnd(lines: lines, startIndex: index),
               end < range.upperBound {
                let body = lines[(index + 1)..<end].joined(separator: "\n")
                result.append(.init(
                    kind: .privateLane,
                    name: lane.name,
                    platform: platform,
                    optionVariable: lane.optionVariable,
                    parameters: [],
                    body: body
                ))
                index = end + 1
                continue
            }
            if let function = parseFunctionStart(line),
               let end = blockEnd(lines: lines, startIndex: index),
               end < range.upperBound {
                let body = lines[(index + 1)..<end].joined(separator: "\n")
                result.append(.init(
                    kind: .function,
                    name: function.name,
                    platform: platform,
                    optionVariable: nil,
                    parameters: function.parameters,
                    body: body
                ))
                index = end + 1
                continue
            }
            index += 1
        }
        return result
    }
    
    static func parsePlatformStart(_ line: String) -> String? {
        parseSymbol(line: line, prefix: "platform :", mustContainDo: true).symbol
    }
    
    static func parseLaneStart(_ line: String) -> (name: String, optionVariable: String?)? {
        let parsed = parseSymbol(line: line, prefix: "lane :", mustContainDo: true)
        guard let name = parsed.symbol else {
            return nil
        }
        return (name, parsed.optionVariable)
    }
    
    static func parsePrivateLaneStart(_ line: String) -> (name: String, optionVariable: String?)? {
        let parsed = parseSymbol(line: line, prefix: "private_lane :", mustContainDo: true)
        guard let name = parsed.symbol else {
            return nil
        }
        return (name, parsed.optionVariable)
    }
    
    static func parseFunctionStart(_ line: String) -> (name: String, parameters: [String])? {
        guard line.hasPrefix("def ") else {
            return nil
        }
        let rest = String(line.dropFirst(4))
        let name = readWord(rest)
        guard name.isEmpty == false else {
            return nil
        }
        let parameters: [String]
        if let open = rest.firstIndex(of: "("), let close = rest.firstIndex(of: ")"), close > open {
            let raw = rest[rest.index(after: open)..<close]
            parameters = raw
                .components(separatedBy: ",")
                .map({ $0.trimmingCharacters(in: .whitespacesAndNewlines) })
                .filter({ $0.isEmpty == false })
        } else {
            parameters = []
        }
        return (name, parameters)
    }
    
    static func parseSymbol(line: String, prefix: String, mustContainDo: Bool) -> (symbol: String?, optionVariable: String?) {
        guard line.hasPrefix(prefix) else {
            return (nil, nil)
        }
        if mustContainDo, line.contains(" do") == false, line.contains(" do|") == false {
            return (nil, nil)
        }
        let rest = String(line.dropFirst(prefix.count))
        let symbol = readWord(rest)
        guard symbol.isEmpty == false else {
            return (nil, nil)
        }
        let optionVariable: String?
        if let firstPipe = line.firstIndex(of: "|"),
           let secondPipe = line[line.index(after: firstPipe)...].firstIndex(of: "|") {
            let value = line[line.index(after: firstPipe)..<secondPipe]
                .trimmingCharacters(in: .whitespacesAndNewlines)
            optionVariable = value.isEmpty ? nil : value
        } else {
            optionVariable = nil
        }
        return (symbol, optionVariable)
    }
    
    static func readWord(_ string: String) -> String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "_"))
        let unicode = string.unicodeScalars
        let value = unicode.prefix(while: { allowed.contains($0) })
        return String(String.UnicodeScalarView(value))
    }
    
    static func blockEnd(lines: [String], startIndex: Int) -> Int? {
        var depth = 0
        for index in startIndex..<lines.count {
            let sanitized = sanitize(lines[index])
            depth += openTokenCount(in: sanitized)
            depth -= closeTokenCount(in: sanitized)
            if index == startIndex, depth <= 0 {
                depth = 1
            }
            if index > startIndex, depth <= 0 {
                return index
            }
        }
        return nil
    }
    
    static func sanitize(_ line: String) -> String {
        let raw = line.split(separator: "#", maxSplits: 1, omittingEmptySubsequences: false).first.map(String.init) ?? line
        return raw.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    static func openTokenCount(in line: String) -> Int {
        guard line.isEmpty == false else {
            return 0
        }
        let doCount = regexMatches("\\bdo\\b", in: line).count
        var count = doCount
        if let keyword = regexMatches("^(if|unless|case|begin|while|until|for|def|class|module)\\b", in: line).first?.first {
            // `while/until/for ... do` should increase depth only once.
            if (keyword == "while" || keyword == "until" || keyword == "for"), doCount > 0 {
                return count
            }
            count += 1
        }
        return count
    }
    
    static func closeTokenCount(in line: String) -> Int {
        regexMatches("\\bend\\b", in: line).count
    }
    
    static func regexMatches(_ pattern: String, in text: String) -> [[String]] {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return []
        }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        return regex.matches(in: text, options: [], range: range).map({ match in
            (0..<match.numberOfRanges).compactMap({ index in
                let groupRange = match.range(at: index)
                guard groupRange.location != NSNotFound,
                      let range = Range(groupRange, in: text) else {
                    return nil
                }
                return String(text[range])
            })
        })
    }
    
    func collectOptions(for definition: Definition, visited: Set<String>) -> [OptionItem] {
        guard let optionVariable = definition.optionVariable else {
            return []
        }
        var visited = visited
        visited.insert(definition.identity)
        var order: [String] = []
        var storage: [String: FastlaneLaneInputType] = [:]
        
        func upsert(_ name: String, _ type: FastlaneLaneInputType) {
            if storage[name] == nil {
                order.append(name)
                storage[name] = type
                return
            }
            if storage[name] == .string, type == .bool {
                storage[name] = .bool
            }
        }
        
        let directKeys = optionKeysUsedOrAssigned(in: definition.body, optionVariable: optionVariable)
        for key in directKeys {
            upsert(key, inferOptionType(in: definition.body, optionVariable: optionVariable, key: key))
        }
        
        let forwardedOptions = forwardedOptionCalls(in: definition.body, optionVariable: optionVariable)
        for callee in forwardedOptions {
            let laneTargets = laneDefinitions(named: callee, platform: definition.platform)
            if laneTargets.isEmpty == false {
                for target in laneTargets where visited.contains(target.identity) == false {
                    let nested = collectOptions(for: target, visited: visited)
                    for item in nested {
                        upsert(item.name, item.type)
                    }
                }
                continue
            }
            let privateTargets = privateLaneDefinitions(named: callee, platform: definition.platform)
            for target in privateTargets where visited.contains(target.identity) == false {
                let nested = collectOptions(for: target, visited: visited)
                for item in nested {
                    upsert(item.name, item.type)
                }
            }
        }
        
        let forwardedSingle = forwardedSingleOptionCalls(in: definition.body, optionVariable: optionVariable)
        for forwarded in forwardedSingle {
            let type = inferOptionTypeFromForwardedCall(function: forwarded.function, platform: definition.platform)
            upsert(forwarded.key, type)
        }
        
        return order.map({ .init(name: $0, type: storage[$0] ?? .string) })
    }
    
    func optionKeysUsedOrAssigned(in body: String, optionVariable: String) -> [String] {
        let assignPattern = "\\b\(NSRegularExpression.escapedPattern(for: optionVariable))\\s*\\[\\s*:(\\w+)\\s*\\]\\s*="
        let readPattern = "\\b\(NSRegularExpression.escapedPattern(for: optionVariable))\\s*\\[\\s*:(\\w+)\\s*\\](?!\\s*=)"
        var order: [String] = []
        var storage = Set<String>()
        for groups in Self.regexMatches(assignPattern, in: body) {
            guard groups.count > 1 else {
                continue
            }
            let key = groups[1]
            if storage.insert(key).inserted {
                order.append(key)
            }
        }
        for groups in Self.regexMatches(readPattern, in: body) {
            guard groups.count > 1 else {
                continue
            }
            let key = groups[1]
            if storage.insert(key).inserted {
                order.append(key)
            }
        }
        return order
    }
    
    func forwardedOptionCalls(in body: String, optionVariable: String) -> [String] {
        let pattern = "\\b(\\w+)\\s*\\(\\s*\(NSRegularExpression.escapedPattern(for: optionVariable))\\s*\\)"
        var order: [String] = []
        var storage = Set<String>()
        for groups in Self.regexMatches(pattern, in: body) {
            guard groups.count > 1 else {
                continue
            }
            let value = groups[1]
            if storage.insert(value).inserted {
                order.append(value)
            }
        }
        return order
    }
    
    func forwardedSingleOptionCalls(in body: String, optionVariable: String) -> [(function: String, key: String)] {
        let pattern = "\\b(\\w+)\\s*\\(\\s*\(NSRegularExpression.escapedPattern(for: optionVariable))\\s*\\[\\s*:(\\w+)\\s*\\]"
        var result: [(String, String)] = []
        var dedupe = Set<String>()
        for groups in Self.regexMatches(pattern, in: body) {
            guard groups.count > 2 else {
                continue
            }
            let function = groups[1]
            let key = groups[2]
            let token = "\(function):\(key)"
            if dedupe.insert(token).inserted {
                result.append((function, key))
            }
        }
        return result
    }
    
    func inferOptionType(in body: String, optionVariable: String, key: String) -> FastlaneLaneInputType {
        let optionAccess = "\(NSRegularExpression.escapedPattern(for: optionVariable))\\s*\\[\\s*:\(NSRegularExpression.escapedPattern(for: key))\\s*\\]"
        let boolAssignmentPattern = "\(optionAccess)\\s*=\\s*(true|false)\\b"
        if Self.regexMatches(boolAssignmentPattern, in: body).isEmpty == false {
            return .bool
        }
        let nilCheckPattern = "\(optionAccess)\\s*\\.nil\\?\\s*\\?\\s*(true|false)"
        if Self.regexMatches(nilCheckPattern, in: body).isEmpty == false {
            return .bool
        }
        let ifPattern = "\\b(if|unless)\\s+\(optionAccess)\\b"
        if Self.regexMatches(ifPattern, in: body).isEmpty == false {
            return .bool
        }
        let comparePattern = "\(optionAccess)\\s*==\\s*(true|false)"
        if Self.regexMatches(comparePattern, in: body).isEmpty == false {
            return .bool
        }
        return .string
    }
    
    func inferOptionTypeFromForwardedCall(function: String, platform: String?) -> FastlaneLaneInputType {
        let defs = definitions.filter({ $0.kind == .function && $0.name == function && ($0.platform == platform || $0.platform == nil) })
        guard let def = defs.first, let argument = def.parameters.first else {
            return .string
        }
        let argumentPattern = NSRegularExpression.escapedPattern(for: argument)
        if Self.regexMatches("\\b(if|unless)\\s+\(argumentPattern)\\b", in: def.body).isEmpty == false {
            return .bool
        }
        if Self.regexMatches("\(argumentPattern)\\s*==\\s*(true|false)", in: def.body).isEmpty == false {
            return .bool
        }
        return .string
    }
    
    func laneDefinitions(named name: String, platform: String?) -> [Definition] {
        let direct = definitions.filter({
            $0.name == name &&
            $0.kind == .lane &&
            $0.optionVariable != nil &&
            $0.platform == platform
        })
        if direct.isEmpty == false {
            return direct
        }
        return definitions.filter({
            $0.name == name &&
            $0.kind == .lane &&
            $0.optionVariable != nil
        })
    }
    
    func privateLaneDefinitions(named name: String, platform: String?) -> [Definition] {
        let direct = definitions.filter({
            $0.name == name &&
            $0.kind == .privateLane &&
            $0.optionVariable != nil &&
            $0.platform == platform
        })
        if direct.isEmpty == false {
            return direct
        }
        return definitions.filter({
            $0.name == name &&
            $0.kind == .privateLane &&
            $0.optionVariable != nil
        })
    }
}

nonisolated private extension FastfileParser.Definition {
    
    var identity: String {
        "\(kind)-\(platform ?? "none")-\(name)"
    }
}

private final class FastlaneServiceEmpty: FastlaneServiceMock { }

class FastlaneServiceMock: FastlaneServiceInterface {
    static let shared = FastlaneServiceMock()
    func scan(_ selectedDirectory: URL) async throws -> FastlaneScanResult {
        .init(selectedDirectory: selectedDirectory, fastlaneDirectory: selectedDirectory, commandDirectory: selectedDirectory, lanes: [])
    }
    func open(_ path: URL) async throws { }
    func runInTerminal(_ command: String) async throws { }
    
    init() { }
}

extension EnvironmentValues {
    
    @Entry var fastlaneService: FastlaneServiceInterface = FastlaneServiceEmpty()
}

extension View {
    
    func withFastlaneService(_ fastlaneService: FastlaneServiceInterface) -> some View {
        environment(\.fastlaneService, fastlaneService)
    }
}
