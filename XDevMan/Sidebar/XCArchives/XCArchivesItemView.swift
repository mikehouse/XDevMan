
import SwiftUI

struct XCArchivesItemView: View {
    
    let archiveId: XCArchiveID
    @Binding var xcArchiveDeleted: XCArchiveID?
    @Environment(\.xcAchivesService) private var xcAchivesService
    @Environment(\.alertHandler) private var alertHandler
    @Environment(\.bashService) private var bashService
    @Environment(\.appLogger) private var appLogger
    @State private var archive: XCArchive?
    @State private var size: String?
    @State private var notArchive = false
    @State private var isDeleting = false
    
    var body: some View {
        Group {
            if let archive {
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            AsTitle("Display Name: ")
                            AsValue(archive.displayName)
                        }
                        HStack {
                            AsTitle("Bundle Identifier: ")
                            AsValue(archive.bundleIdentifier)
                        }
                        HStack {
                            AsTitle("Development Region: ")
                            AsValue(archive.region)
                        }
                        HStack {
                            AsTitle("Executable: ")
                            AsValue(archive.executable)
                        }
                        HStack {
                            AsTitle("Created: ")
                            AsValue("\(archive.creationDate)")
                        }
                        HStack {
                            AsTitle("Build SDK: ")
                            HStack {
                                AsValue(archive.platform)
                                AsValue(archive.platformVersion)
                            }
                        }
                        HStack {
                            AsTitle("XCode: ")
                            HStack {
                                AsValue("\(archive.xcodeVersion.dropLast(archive.xcodeVersion.count - 2)).\(archive.xcodeVersion.dropFirst(2))")
                                AsValue("(\(archive.xcodeBuild))")
                            }
                        }
                        HStack {
                            AsTitle("Minimum OS: ")
                            AsValue(archive.minimumOSVersion)
                        }
                        HStack {
                            AsTitle("Signing Identity: ")
                            AsValue(archive.signingIdentity)
                        }
                        HStack {
                            AsTitle("Development Team: ")
                            AsValue(archive.team)
                        }
                        HStack {
                            AsTitle("Architectures: ")
                            AsValue(archive.architectures.joined(separator: ", "))
                        }
                        HStack {
                            AsTitle("Supported Platforms: ")
                            AsValue(archive.supportedPlatforms.joined(separator: ", "))
                        }
                        HStack {
                            AsTitle("Allows Arbitrary Loads: ")
                            AsValue("\(archive.allowsArbitraryLoads)")
                        }
                        if !archive.exceptionDomains.isEmpty {
                            HStack {
                                AsTitle("Exception Domains: ")
                                VStack(alignment: .leading, spacing: 2) {
                                    ForEach(archive.exceptionDomains, id: \.self) { domain in
                                        AsValue(domain)
                                    }
                                }
                            }
                        }
                        if !archive.urlSchemes.isEmpty {
                            HStack {
                                AsTitle("URL Schemes: ")
                                VStack(alignment: .leading, spacing: 2) {
                                    ForEach(archive.urlSchemes, id: \.self) { scheme in
                                        AsValue(scheme)
                                    }
                                }
                            }
                        }
                        if !archive.queriesSchemes.isEmpty {
                            HStack {
                                AsTitle("Queries Schemes: ")
                                VStack(alignment: .leading, spacing: 2) {
                                    ForEach(archive.queriesSchemes, id: \.self) { scheme in
                                        AsValue(scheme)
                                    }
                                }
                            }
                        }
                        if !archive.backgroundModes.isEmpty {
                            HStack {
                                AsTitle("Background Modes: ")
                                VStack(alignment: .leading, spacing: 2) {
                                    ForEach(archive.backgroundModes, id: \.self) { mode in
                                        AsValue(mode)
                                    }
                                }
                            }
                        }
                        if !archive.bonjourServices.isEmpty {
                            HStack {
                                AsTitle("Bonjour Services: ")
                                VStack(alignment: .leading, spacing: 2) {
                                    ForEach(archive.bonjourServices, id: \.self) { service in
                                        AsValue(service)
                                    }
                                }
                            }
                        }
                        if !archive.appFonts.isEmpty {
                            HStack {
                                AsTitle("App Fonts: ")
                                VStack(alignment: .leading, spacing: 2) {
                                    ForEach(archive.appFonts, id: \.self) { font in
                                        AsValue(font)
                                    }
                                }
                            }
                        }
                        if !archive.supportedInterfaceOrientations.isEmpty {
                            HStack {
                                AsTitle("Supported Interface Orientations: ")
                                VStack(alignment: .leading, spacing: 2) {
                                    ForEach(archive.supportedInterfaceOrientations, id: \.self) { o in
                                        AsValue(o)
                                    }
                                }
                            }                            
                        }
                        if let cameraUsageDescription = archive.cameraUsageDescription {
                            HStack {
                                AsTitle("Camera Usage Description: ")
                                AsValue(cameraUsageDescription)
                            }
                        }
                        if let faceIDUsageDescription = archive.faceIDUsageDescription {
                            HStack {
                                AsTitle("FaceID Usage Description: ")
                                AsValue(faceIDUsageDescription)
                            }
                        }
                        if let microphoneUsageDescription = archive.microphoneUsageDescription {
                            HStack {
                                AsTitle("Microphone Usage Description: ")
                                AsValue(microphoneUsageDescription)
                            }
                        }
                        if let photoLibraryAddUsageDescription = archive.photoLibraryAddUsageDescription {
                            HStack {
                                AsTitle("PhotoLibrary Add Usage Description: ")
                                AsValue(photoLibraryAddUsageDescription)
                            }
                        }
                        if let photoLibraryUsageDescription = archive.photoLibraryUsageDescription {
                            HStack {
                                AsTitle("Photo Library Usage Description: ")
                                AsValue(photoLibraryUsageDescription)
                            }
                        }
                        if let userTrackingUsageDescription = archive.userTrackingUsageDescription {
                            HStack {
                                AsTitle("User Tracking Usage Description: ")
                                AsValue(userTrackingUsageDescription)
                            }
                        }
                        if let bluetoothAlwaysUsageDescription = archive.bluetoothAlwaysUsageDescription {
                            HStack {
                                AsTitle("Bluetooth Always Usage Description: ")
                                AsValue(bluetoothAlwaysUsageDescription)
                            }
                        }
                        if let bluetoothPeripheralUsageDescription = archive.bluetoothPeripheralUsageDescription {
                            HStack {
                                AsTitle("Bluetooth Always Usage Description: ")
                                AsValue(bluetoothPeripheralUsageDescription)
                            }
                        }
                        if let documentsFolderUsageDescription = archive.documentsFolderUsageDescription {
                            HStack {
                                AsTitle("Documents Folder Usage Description: ")
                                AsValue(documentsFolderUsageDescription)
                            }
                        }
                        if let localNetworkUsageDescription = archive.localNetworkUsageDescription {
                            HStack {
                                AsTitle("Local Network Usage Description: ")
                                AsValue(localNetworkUsageDescription)
                            }
                        }
                        if let userInterfaceStyle = archive.userInterfaceStyle {
                            HStack {
                                AsTitle("User Interface Style: ")
                                AsValue(userInterfaceStyle)
                            }
                        }
                        if let size {
                            HStack {
                                AsTitle("Size: ")
                                AsValue(size)
                            }
                        }
                        HStack(spacing: 16) {
                            if isDeleting {
                                ProgressView()
                                    .controlSize(.mini)
                            } else {
                                Button {
                                    Task {
                                        do {
                                            isDeleting = true
                                            try await xcAchivesService.delete(archiveId)
                                            xcArchiveDeleted = archiveId
                                        } catch {
                                            isDeleting = false
                                            alertHandler.handle(title: "Delete error for \(archiveId.name)", message: nil, error: error)
                                            appLogger.error(error)
                                        }
                                    }
                                } label: {
                                    DeleteIconView()
                                }
                                .buttonStyle(BorderlessButtonStyle())
                            }
                            BashOpenView(
                                path: .custom({ try await xcAchivesService.open(archiveId) }),
                                type: .folder
                            )
                            BashOpenView(path: .url(archive.infoPlist), type: .button(title: "Info.plist", icon: nil, bordered: false, toolbar: false))
                            PasteboardCopyView(text: archive.infoPlist.path)
                            Spacer()
                        }
                        .padding([.top], 4)
                        Spacer()
                    }
                    Spacer()
                }
                .padding()
            } else {
                if notArchive {
                    NothingView(text: "Not iOS/tvOS/watchOS/macOS archive.")
                } else {
                    ProgressView()
                        .controlSize(.small)
                }
            }
        }
        .task(id: archiveId) {
            Task {
                do {
                    archive = try await xcAchivesService.archive(archiveId)
                } catch {
                    notArchive = true
                    appLogger.error(error)
                }
            }
            Task {
                do {
                    size = try await bashService.size(archiveId.path)
                } catch {
                    appLogger.error(error)
                }
            }
        }
    }
    
    private func AsTitle(_ title: String) -> some View {
        Text(title)
            .fixedSize()
            .foregroundStyle(.brown)
    }
    
    private func AsValue(_ title: String) -> some View {
        Text(title)
            .lineLimit(nil)
            .textSelection(.enabled)
            .foregroundStyle(.teal)
    }
}

#Preview {
    XCArchivesItemView(
        archiveId: .init(
            path: URL(fileURLWithPath: "/"),
            name: "App",
            date: Date()
        ),
        xcArchiveDeleted: .constant(nil)
    )
    .frame(width: 540, height: 400)
    .withAppMocks()
}
