import SwiftUI

struct DiagnosticReport: @MainActor HashableIdentifiable {
    
    var id: URL { path }
    
    let name: String
    let path: URL
    let createdAt: Date
    let source: Source
    
    enum Source: String, Hashable, Identifiable {
        
        var id: RawValue { rawValue }
        
        case reports = "Reports"
        case retired = "Retired"
    }
}

protocol DiagnosticReportsServiceInterface: Sendable {
    
    func reports() async -> [DiagnosticReport]
    func retiredReports() async -> [DiagnosticReport]
    func content(_ item: DiagnosticReport) async throws -> String
    func open() async throws
    func delete(_ item: DiagnosticReport) async throws
}

actor DiagnosticReportsService: DiagnosticReportsServiceInterface {
    
    private let bashService: BashProvider.Type
    private let root = URL(fileURLWithPath: "/Users/\(NSUserName())/Library/Logs/DiagnosticReports", isDirectory: true)
    
    init(bashService: BashProvider.Type) {
        self.bashService = bashService
    }
    
    func reports() -> [DiagnosticReport] {
        items(at: root, source: .reports)
    }
    
    func retiredReports() -> [DiagnosticReport] {
        items(at: root.appendingPathComponent("Retired", isDirectory: true), source: .retired)
    }
    
    func content(_ item: DiagnosticReport) throws -> String {
        try String(contentsOf: item.path)
    }
    
    func open() async throws {
        try await bashService.open(root)
    }
    
    func delete(_ item: DiagnosticReport) async throws {
        try await bashService.rmFile(item.path)
    }
    
    private func items(at path: URL, source: DiagnosticReport.Source) -> [DiagnosticReport] {
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: path.path) else {
            return []
        }
        return (try? fileManager.contentsOfDirectory(
            at: path,
            includingPropertiesForKeys: [.creationDateKey, .isRegularFileKey, .isHiddenKey],
            options: [.skipsHiddenFiles]
        ))?
        .filter({ (try? $0.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile) ?? false })
        .map({ fileURL -> DiagnosticReport in
            let createdAt = (try? fileURL.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast
            return DiagnosticReport(
                name: fileURL.lastPathComponent,
                path: fileURL,
                createdAt: createdAt,
                source: source
            )
        })
        .sorted(by: { $0.createdAt > $1.createdAt }) ?? []
    }
}

private final class DiagnosticReportsServiceEmpty: DiagnosticReportsServiceMock { }

class DiagnosticReportsServiceMock: DiagnosticReportsServiceInterface {
    
    static let shared = DiagnosticReportsServiceMock()
    
    func reports() async -> [DiagnosticReport] { [] }
    func retiredReports() async -> [DiagnosticReport] { [] }
    func content(_ item: DiagnosticReport) async throws -> String { "" }
    func open() async throws { }
    func delete(_ item: DiagnosticReport) async throws { }
    
    init() { }
}

extension EnvironmentValues {
    
    @Entry var diagnosticReportsService: DiagnosticReportsServiceInterface = DiagnosticReportsServiceEmpty()
}

extension View {
    
    func withDiagnosticReportsService(_ diagnosticReportsService: DiagnosticReportsServiceInterface) -> some View {
        environment(\.diagnosticReportsService, diagnosticReportsService)
    }
}
