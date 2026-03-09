//
//  AppInfoView.swift
//  XDevMan
//
//  Created by Mikhail Demidov on 07.10.2024.
//

import SwiftUI

struct AppInfoView: View {

    @Environment(\.appLogger) private var appLogger
    @Environment(\.openWindow) private var openWindow
    @State private var appVersion: String?
    @State private var isNewVersionAvailable = false

    var body: some View {
        Group {
            VStack(spacing: 12) {
                if let appVersion {
                    HStack(alignment: .center, spacing: 8) {
                        Text(appVersion)
                            .font(.callout)
                            .foregroundStyle(.tertiary)
                        Button {
                            if isNewVersionAvailable {
                                if let url = URL(string: "https://github.com/mikehouse/XDevMan/releases") {
                                    NSWorkspace.shared.open(url)
                                }
                            } else {
                                if let url = URL(string: "https://github.com/mikehouse/XDevMan") {
                                    NSWorkspace.shared.open(url)
                                }
                            }
                        } label: {
                            Image(systemName: "link")
                                .resizable()
                                .frame(width: 13, height: 13)
                                .fontWeight(.bold)
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.borderless)
                        if isNewVersionAvailable {
                            Circle()
                                .foregroundStyle(.green)
                                .frame(width: 12)
                        }
                    }
                }
                Button {
                    openWindow(id: Windows.appLogs.rawValue)
                } label: {
                    Text("App logs")
                }
            }
            .padding()
        }
        .task {
            guard let dict = Bundle.main.infoDictionary else {
                return
            }
            guard let version = dict["CFBundleShortVersionString"] as? String,
                  let build = dict["CFBundleVersion"] as? String else {
                return
            }
            appVersion = "version \(version) (build \(build))"
            isNewVersionAvailable = await Task<Bool, Never>.detached {
                let urls = [
                    URL(string: "https://raw.githubusercontent.com/mikehouse/XDevMan/refs/heads/main/XDevMan.xcodeproj/project.pbxproj"),
                    URL(string: "https://gitlab.com/mikehouse1/XDevMan/-/raw/main/XDevMan.xcodeproj/project.pbxproj")
                ].compactMap({ $0 })
                for url in urls {
                    do {
                        let (data, response) = try await URLSession.shared.data(from: url)
                        let code = ((response as? HTTPURLResponse)?.statusCode ?? 0)
                        guard (200..<400).contains(code) else {
                            continue
                        }
                        let fileURL = FileManager.default.temporaryDirectory
                            .appendingPathComponent("\(UUID().uuidString).project.pbxproj")
                        try data.write(to: fileURL, options: .atomicWrite)
                        let remoteVersion: String? = try PBXProjectParser(path: fileURL.path).parseMarketingVersion(for: "XDevMan")
                        guard let remoteVersion = remoteVersion else {
                            continue
                        }
                        return version != remoteVersion
                    } catch {
                        await appLogger.error(error)
                    }
                }
                return false
            }.value
        }
    }
}

#Preview {
    AppInfoView()
        .frame(width: 300, height: 100)
}
