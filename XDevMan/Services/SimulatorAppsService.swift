//
//  SimulatorAppsService.swift
//  XDevMan
//
//  Created by Mikhail Demidov on 03.05.2025.
//

import SwiftUI

@MainActor
protocol SimulatorAppsServiceInterface {
    
    func apps(for sim: DeviceSim) async -> [SimAppItem]
    func apps(for sim: PreviewsItem) async -> [SimAppItem]
}

struct SimAppItem: HashableIdentifiable {
    
    let id: String    
    let name: String
    let version: String?
    let build: String?
    let path: URL
    let icon: URL?
    let infoPlist: URL
    let userDefaults: URL?
    let userDefaultsShared: URL?
    let sandbox: URL
}

final class SimulatorAppsService: SimulatorAppsServiceInterface {

    func apps(for sim: PreviewsItem) async -> [SimAppItem] {
        let sim = DeviceSim(
            lastBootedAt: nil, dataPath: sim.dataPath.path, dataPathSize: 0,
            logPath: "", udid: sim.udid, isAvailable: true, availabilityError: nil, logPathSize: nil,
            deviceTypeIdentifier: sim.runtime, state: "Booted", name: sim.name
        )
        return await apps(for: sim)
    }
    
    func apps(for sim: DeviceSim) async -> [SimAppItem] {
        await Task<[SimAppItem], Never>(priority: .high) {
            let fileManager = FileManager.default
            let appsDir = URL(fileURLWithPath: sim.dataPath)
                .appendingPathComponent("Containers")
                .appendingPathComponent("Bundle")
                .appendingPathComponent("Application")
            guard fileManager.fileExists(atPath: appsDir.path) else {
                return []
            }
            struct App {
                let id: String
                let icon: URL?
                let name: String
                let path: URL
                let version: String?
                let build: String?
                let infoPlist: URL
            }
            let apps = ((try? fileManager.contentsOfDirectory(atPath: appsDir.path)) ?? [])
                .filter({ $0.count == 36 })
                .compactMap({ path -> App? in
                    let path = appsDir.appendingPathComponent(path, isDirectory: true)
                    guard let bundleName = try? fileManager.contentsOfDirectory(atPath: path.path)
                            .first(where: { $0.hasSuffix(".app") }) else {
                        return nil
                    }
                    guard !bundleName.hasSuffix("UITests-Runner.app") else {
                        return nil
                    }
                    let bundle = path.appendingPathComponent(bundleName, isDirectory: true)
                    let plist = bundle.appendingPathComponent("Info.plist", isDirectory: false)
                    guard let dict = NSDictionary(contentsOf: plist) else {
                        return nil
                    }             
                    guard let bundleId = dict["CFBundleIdentifier"] as? String,
                      let version = dict["CFBundleShortVersionString"] as? String,
                      let build = dict["CFBundleVersion"] as? String,
                      let displayName = (dict["CFBundleDisplayName"] as? String ?? dict["CFBundleName"] as? String) else {
                        return nil
                    }
                    var icon: URL?
                    if let icons = dict["CFBundleIcons"] as? [String: Any],
                       let primary = icons["CFBundlePrimaryIcon"] as? [String: Any],
                       let iconName = primary["CFBundleIconName"] as? String {
                        icon = ((try? fileManager.contentsOfDirectory(atPath: bundle.path)) ?? [])
                            .first(where: { $0.hasPrefix(iconName) && $0.hasSuffix(".png") })
                            .map({ bundle.appendingPathComponent($0, isDirectory: false) })
                    }
                    return App(
                        id: bundleId,
                        icon: icon, 
                        name: displayName,
                        path: path, version: version, 
                        build: build, 
                        infoPlist: plist
                    )
                })
            guard !apps.isEmpty else {
                return []
            }
            let sandboxesRoot = URL(fileURLWithPath: sim.dataPath)
                .appendingPathComponent("Containers", isDirectory: true)
                .appendingPathComponent("Data", isDirectory: true)
                .appendingPathComponent("Application", isDirectory: true)
            guard fileManager.fileExists(atPath: appsDir.path) else {
                return []
            }
            return ((try? fileManager.contentsOfDirectory(atPath: sandboxesRoot.path)) ?? [])
                .filter({ $0.count == 36 })
                .compactMap({ path -> SimAppItem? in
                    let sandboxRoot = sandboxesRoot.appendingPathComponent(path, isDirectory: true)
                    let metadata = sandboxRoot.appendingPathComponent(".com.apple.mobile_container_manager.metadata.plist", isDirectory: false)
                    guard fileManager.fileExists(atPath: metadata.path) else {
                        return nil
                    }
                    guard let dict = NSDictionary(contentsOf: metadata) else {
                        return nil
                    }
                    guard let bundleId = dict["MCMMetadataIdentifier"] as? String,
                          let app = apps.first(where: { $0.id == bundleId }) else {
                        return nil
                    }
                    let userDefaults = sandboxRoot.appendingPathComponent("Library", isDirectory: true)
                        .appendingPathComponent("Preferences", isDirectory: true)
                        .appendingPathComponent("\(bundleId).plist", isDirectory: false)
                    let sharedRoot = URL(fileURLWithPath: sim.dataPath)
                        .appendingPathComponent("Containers", isDirectory: true)
                        .appendingPathComponent("Shared", isDirectory: true)
                        .appendingPathComponent("AppGroup", isDirectory: true)
                    let userDefaultsShared = ((try? fileManager.contentsOfDirectory(atPath: sharedRoot.path)) ?? [])
                        .filter({ $0.count == 36 })
                        .compactMap({ path -> URL? in
                            let path = sharedRoot.appendingPathComponent(path, isDirectory: true)
                            let metadata = path.appendingPathComponent(".com.apple.mobile_container_manager.metadata.plist", isDirectory: false)
                            guard fileManager.fileExists(atPath: metadata.path) else {
                                return nil
                            }
                            guard let dict = NSDictionary(contentsOf: metadata) else {
                                return nil
                            }
                            guard dict["MCMMetadataIdentifier"] as? String == "group.\(bundleId)" else {
                                return nil
                            }
                            let plist = path.appendingPathComponent("Library", isDirectory: true)
                                .appendingPathComponent("Preferences", isDirectory: true)
                                .appendingPathComponent("group.\(bundleId).plist", isDirectory: false)
                            return fileManager.fileExists(atPath: plist.path) ? plist : nil
                        }).first
                    return SimAppItem(
                        id: app.id,
                        name: app.name,
                        version: app.version,
                        build: app.build,
                        path: app.path,
                        icon: app.icon,
                        infoPlist: app.infoPlist,
                        userDefaults: fileManager.fileExists(atPath: userDefaults.path) ? userDefaults : nil,
                        userDefaultsShared: userDefaultsShared,
                        sandbox: sandboxRoot
                    )
            }).sorted(by: { $0.name < $1.name })
        }.value
    }
}

class SimulatorAppsServiceMock: SimulatorAppsServiceInterface {
    static let shared = SimulatorAppsServiceMock()
    
    func apps(for sim: DeviceSim) async -> [SimAppItem] { [] }
    func apps(for sim: PreviewsItem) async -> [SimAppItem] { [] }
}

private final class SimulatorAppsServiceEmpty: SimulatorAppsServiceMock {}

extension EnvironmentValues {
    
    @Entry var simulatorAppsService: SimulatorAppsServiceInterface = SimulatorAppsServiceEmpty()
}

extension View {
    
    func withSimulatorAppsService(_ simulatorAppsService: SimulatorAppsServiceInterface) -> some View {
        environment(\.simulatorAppsService, simulatorAppsService)
    }
}
