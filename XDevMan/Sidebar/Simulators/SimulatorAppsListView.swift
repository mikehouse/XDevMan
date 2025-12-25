//
//  SimulatorAppsListView.swift
//  XDevMan
//
//  Created by Mikhail Demidov on 03.05.2025.
//

import SwiftUI

struct SimulatorAppsListView: View {
    
    let items: [SimAppItem]
    
    var body: some View {
        ForEach(items) { item in
            SimulatorAppView(item: item)
        }
    }
}

struct SimulatorAppView: View {
    
    let item: SimAppItem
    @State private var image: Image?
    
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
                    type: .button(title: "Defaults", icon: nil, bordered: false, toolbar: false))
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
        }
        .task(id: item) {
            if let url = item.icon, let nsImage = NSImage(contentsOf: url) {
                image = Image(nsImage: nsImage)
            }
        }
    }
}

#Preview {
    SimulatorAppsListView(items: [
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
    ])
    .padding()
}
