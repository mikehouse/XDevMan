//
//  SimulatorAppsListView.swift
//  XDevMan
//
//  Created by Mikhail Demidov on 03.05.2025.
//

import SwiftUI

struct SimulatorAppsListView: View {
    
    let device: DeviceSim
    let items: [SimAppItem]
    let onReload: () async -> Void
    
    var body: some View {
        ForEach(items) { item in
            SimulatorAppView(device: device, item: item, onReload: onReload)
        }
    }
}

struct SimulatorAppView: View {
    
    let device: DeviceSim
    let item: SimAppItem
    let onReload: () async -> Void
    @Environment(\.devicesService) private var devicesService
    @Environment(\.alertHandler) private var alertHandler
    @Environment(\.appLogger) private var appLogger
    @State private var image: Image?
    @State private var isUninstalling = false
    
    var body: some View {
        HStack {
            (image ?? Image("noImage"))
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 22, height: 22)
                .cornerRadius(6)
            Text(item.name).textSelection(.enabled)
            if let version = item.version {
                Text("(\(version))").textSelection(.enabled)
            }
            if let build = item.build {
                Text("(\(build))").textSelection(.enabled)
            }
            BashOpenView(path: .url(item.infoPlist), type: .button(title: "Info.plist", icon: nil, bordered: false, toolbar: false))
            PasteboardCopyView(text: item.infoPlist.path)
            BashOpenView(path: .url(item.path), type: .folder)
            Spacer()
            if let userDefaults = item.userDefaults {
                BashOpenView(
                    path: .url(userDefaults),
                    type: .button(title: "UserDefaults", icon: nil, bordered: false, toolbar: false))
                PasteboardCopyView(text: userDefaults.path)
                BashOpenView(path: .url(userDefaults.deletingLastPathComponent()), type: .folder)
            }
            if let userDefaultsShared = item.userDefaultsShared {
                Text("|")
                BashOpenView(
                    path: .url(userDefaultsShared),
                    type: .button(title: "Group", icon: nil, bordered: false, toolbar: false))
                PasteboardCopyView(text: userDefaultsShared.path)
                BashOpenView(path: .url(userDefaultsShared.deletingLastPathComponent()), type: .folder)
            }
            if item.userDefaults == nil, item.userDefaultsShared == nil, let sandbox = item.sandbox {
                BashOpenView(path: .url(sandbox), type: .folder)
            }
            if device.state == "Booted" {
                Button {
                    Task {
                        await uninstall()
                    }
                } label: {
                    if isUninstalling {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        DeleteIconView()
                    }
                }
                .buttonStyle(BorderlessButtonStyle())
            }
        }
        .task(id: item) {
            if let url = item.icon, let nsImage = NSImage(contentsOf: url) {
                image = Image(nsImage: nsImage)
            }
        }
    }
    
    private func uninstall() async {
        isUninstalling = true
        defer {
            isUninstalling = false
        }
        do {
            try await devicesService.uninstall(item.id, from: device)
            await onReload()
        } catch {
            alertHandler.handle(title: "Uninstall error for \(item.name)", message: nil, error: error)
            appLogger.error("Uninstall app error for \(item.name): \(error)")
        }
    }
}

#Preview {
    SimulatorAppsListView(device: .init(
        lastBootedAt: nil,
        dataPath: "/",
        dataPathSize: 1234566771,
        logPath: "/",
        udid: "C17547A2-F6BB-4AC2-9B2D-BCE8F958352C",
        isAvailable: true,
        availabilityError: nil,
        logPathSize: nil,
        deviceTypeIdentifier: "com.apple.CoreSimulator.SimDeviceType.iPhone-15",
        state: "Booted",
        name: "iPhone 15"
    ), items: [
        .init(
            id: "com.myapp",
            name: "My App",
            version: "1.2.3",
            build: "123",
            path: URL(fileURLWithPath: "/"),
            icon: nil,
            infoPlist: URL(fileURLWithPath: "/"),
            userDefaults: nil,
            userDefaultsShared: nil,
            sandbox: URL(fileURLWithPath: "/")
        ),
        .init(
            id: "com.myapp.amsd",
            name: "My App second",
            version: "7.9.3",
            build: "355",
            path: URL(fileURLWithPath: "/"),
            icon: nil,
            infoPlist: URL(fileURLWithPath: "/"),
            userDefaults: URL(fileURLWithPath: "/"),
            userDefaultsShared: URL(fileURLWithPath: "/"),
            sandbox: URL(fileURLWithPath: "/")
        )
    ], onReload: { })
    .padding()
    .withAppMocks()
}
