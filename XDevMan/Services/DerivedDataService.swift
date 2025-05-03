
import SwiftUI
import Foundation

typealias DerivedData = DerivedDataService.DerivedData
typealias DerivedDataApp = DerivedDataService.DerivedData.App

@MainActor
protocol DerivedDataServiceInterface: Sendable {
    
    nonisolated func findDerivedData() async -> [DerivedData]
    nonisolated func delete(_ app: DerivedDataApp, for ide: String) async throws
}

final class DerivedDataService: DerivedDataServiceInterface {
    
    let bash: BashProvider.Type
    
    init(bash: BashProvider.Type) {
        self.bash = bash
    }
}

extension DerivedDataService {
    
    enum Error: Swift.Error {
        case deleteError(DerivedDataApp, Swift.Error)
    }
    
    struct DerivedData: HashableIdentifiable {
        
        var id: String { "\(ideName) \(apps.count)" }
        
        let ideName: String
        let path: URL
        let apps: [App]
        
        struct App: HashableIdentifiable {
            
            var id: URL { path }
            
            let name: String
            let path: URL
        }
    }
    
    func delete(_ app: DerivedDataApp, for ide: String) async throws {
        let task = Task<Void, Swift.Error>(priority: .high) { [self] in
            switch ide {
            case "Fleet" where !app.name.hasSuffix("Caches"):
                try await bash.rmDir(app.path.deletingLastPathComponent())
            default:
                try await bash.rmDir(app.path)
            }
        }
        do {
            try await task.value
        } catch {
            throw Error.deleteError(app, error)
        }
    }
    
    func findDerivedData() async -> [DerivedData] {
        let task = Task<[DerivedData], Never>(priority: .high) {
            let fileManager = FileManager.default
            let xcode = DerivedData(
                ideName: "Xcode",
                path: URL(fileURLWithPath: "/Users/\(NSUserName())/Library/Developer/Xcode/DerivedData", isDirectory: true), apps: []
            )
            let jbChaches = URL(fileURLWithPath: "/Users/\(NSUserName())/Library/Caches/JetBrains", isDirectory: true)
            let list: [DerivedData] = ((try? fileManager.contentsOfDirectory(atPath: jbChaches.path)) ?? []).filter { name in
                name.hasPrefix("AppCode") || name == "Fleet"
            }
                .map { ide in
                    DerivedData(
                        ideName: ide,
                        path: jbChaches.appending(path: ide).appending(path: ide == "Fleet" ? "backend" : "DerivedData"), apps: []
                    )
                }
                .filter({ fileManager.fileExists(atPath: $0.path.path) })
            + [xcode]
            let derDataList: [DerivedData] = list.map { derivedData in
                let apps = ((try? fileManager.contentsOfDirectory(atPath: derivedData.path.path)) ?? [])
                var appsList: [DerivedDataApp] = []
                switch derivedData.ideName {
                case _ where derivedData.ideName.hasPrefix("AppCode"), "Xcode":
                    appsList = apps.filter({ app in
                        guard app.count > 29 else {
                            return false
                        }
                        return app.dropFirst(app.count - 29).hasPrefix("-")
                    })
                    .map({ app in
                        DerivedDataApp(
                            name: String(app.dropLast(29)),
                            path: derivedData.path.appending(path: app)
                        )
                    })
                    appsList += [
                        DerivedDataApp(
                            name: "ModuleCache*",
                            path: derivedData.path.appending(path: "ModuleCache.noindex")
                        ),
                        DerivedDataApp(
                            name: "SDKStatCaches*",
                            path: derivedData.path.appending(path: "SDKStatCaches.noindex")
                        ),
                        DerivedDataApp(
                            name: "SymbolCache*",
                            path: derivedData.path.appending(path: "SymbolCache.noindex")
                        )
                    ]
                    appsList = appsList.filter({ fileManager.fileExists(atPath: $0.path.path) })
                case "Fleet":
                    let perApp: [[DerivedDataApp]] = apps.filter({ app in
                        guard app.count > 21 else {
                            return false
                        }
                        return app.dropFirst(app.count - 21).hasPrefix(".")
                    })
                        .map({ app in
                            let dr = derivedData.path.appending(path: app).appending(path: "DerivedData")
                            guard fileManager.fileExists(atPath: dr.path) else {
                                return []
                            }
                            guard let realdDR = ((try? fileManager.contentsOfDirectory(atPath: dr.path)) ?? [])
                                .filter({ $0.count > 29 && $0.dropFirst($0.count - 29).hasPrefix("-") }).first else {
                                return []
                            }
                            let name = String(realdDR.dropLast(29))
                            let appDerivedData = derivedData.path.appending(path: app).appending(path: "DerivedData")
                            return [
                                DerivedDataApp(
                                    name: name,
                                    path: appDerivedData.appending(path: realdDR)
                                ),
                                DerivedDataApp(
                                    name: "\(name)+ModuleCaches",
                                    path: appDerivedData.appending(path: "ModuleCache.noindex")
                                ),
                                DerivedDataApp(
                                    name: "\(name)+SDKStatCaches",
                                    path: appDerivedData.appending(path: "SDKStatCaches.noindex")
                                ),
                                DerivedDataApp(
                                    name: "\(name)+SymbolCaches",
                                    path: appDerivedData.appending(path: "SymbolCache.noindex")
                                )
                            ]
                        })
                    appsList = perApp.flatMap({ $0 }).filter({ fileManager.fileExists(atPath: $0.path.path) })
                default:
                    break
                }
                return .init(
                    ideName: derivedData.ideName,
                    path: derivedData.path,
                    apps: appsList
                )
            }
            return derDataList
        }
        return await task.value
    }
}

private final class DerivedDataServiceEmpty: DerivedDataServiceMock { }

class DerivedDataServiceMock: DerivedDataServiceInterface {
    static let shared = DerivedDataServiceMock()
    func findDerivedData() async -> [DerivedData] { [] }
    func delete(_ app: DerivedDataApp, for ide: String) async throws { }
}


extension EnvironmentValues {
    
    @Entry var derivedDataService: DerivedDataServiceInterface = DerivedDataServiceEmpty()
}

extension View {
    
    func withDerivedDataService(_ derivedDataService: DerivedDataServiceInterface) -> some View {
        environment(\.derivedDataService, derivedDataService)
    }
}
