//
//  SimulatorDyldCacheListView.swift
//  XDevMan
//
//  Created by Mikhail Demidov on 16.12.2024.
//

import SwiftUI

struct SimulatorDyldCacheListView: View {
    
    @Environment(\.runtimesService) private var runtimesService 
    @Environment(\.bashService) private var bashService
    @Environment(\.appLogger) private var appLogger
    @Environment(\.alertHandler) private var alertHandler
    @State private var items: [SimulatorDyldCacheListItemView.Item]?
    @State private var deletedItem: SimulatorDyldCacheListItemView.Item?
    @State private var error: Error?
	
    var body: some View {
        if let items {
            if items.isEmpty {
                NothingView(text: "No issues found.")
            } else {
                List(items) { item in
                    SimulatorDyldCacheListItemView(item: item, deleted: $deletedItem)
                        .modifier(ListItemViewPaddingModifier())
                }
                .onChange(of: deletedItem, {
                    Task {
                        do {
                            try await findMissedDyld()
                        } catch {
                            appLogger.error(error)
                            alertHandler.handle(title: "Dyld find error", message: nil, error: error)
                            self.items = items.filter({ $0 != deletedItem })
                        }
                    }
                })
            }
        } else if let error {
            BaseErrorView(error: error)
        } else {
            ProgressView()
                .controlSize(.small)
                .task {
                    do {
                        try await findMissedDyld()
                    } catch {
                        appLogger.error(error)
                        self.error = error
                    }
                }
        }
    }
    
    private func findMissedDyld() async throws {
        let runtimes = try await runtimesService.list()
        let root = URL(fileURLWithPath: "/Users/\(NSUserName())/Library/Developer/CoreSimulator/Caches/dyld", isDirectory: true)
        let fileManager = FileManager.default
        
        items = try fileManager.contentsOfDirectory(atPath: root.path)
            .compactMap({ name -> URL? in 
                let path = root.appendingPathComponent(name)
                var isDir: ObjCBool = false
                guard fileManager.fileExists(atPath: path.path, isDirectory: &isDir), isDir.boolValue else {
                    return nil
                }
                return path
            })
            .compactMap({ url -> [URL] in 
                try fileManager.contentsOfDirectory(atPath: url.path)
                    .compactMap({ name -> URL? in 
                        guard name.hasPrefix("com.apple.CoreSimulator.SimRuntime") else {
                            return nil
                        }
                        let path = url.appendingPathComponent(name)
                        var isDir: ObjCBool = false
                        guard fileManager.fileExists(atPath: path.path, isDirectory: &isDir), isDir.boolValue else {
                            return nil
                        }
                        return path
                    })
            })
            .flatMap({ $0 })
            .map({ url -> SimulatorDyldCacheListItemView.Item in
                let components = url.lastPathComponent.components(separatedBy: ".")
                return .init(
                    dyldURL: url, 
                    dyldRuntimeId: components.dropLast().joined(separator: "."), 
                    dyldRuntimeBuild: components.last!)
            })
            .filter { item -> Bool in
                runtimes.filter({ 
                    $0.runtimeIdentifier == item.dyldRuntimeId && $0.build == item.dyldRuntimeBuild 
                }).isEmpty
            }
    }
}
