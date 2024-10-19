
import SwiftUI

struct ProvisioningProfilesItemView: View {
    
    let profileID: ProvisioningProfiles.ID
    @Binding var provisioningProfilesSelected: ProvisioningProfiles.ID?
    @State private var profile: ProvisioningProfiles.Profile?
    @Environment(\.provisioningProfilesService) private var provisioningProfilesService
    @Environment(\.alertHandler) private var alertHandler
    @Environment(\.bashService) private var bashService
    @Environment(\.appLogger) private var appLogger
    
    var body: some View {
        Group {
            if let profile {
                HStack(spacing: 12) {
                    Spacer()
                    Button {
                        Task {
                            do {
                                try await bashService.rmFile(profile.id)
                                provisioningProfilesSelected = nil
                            } catch {
                                alertHandler.handle(title: "Delete error", message: nil, error: error)
                                appLogger.error(error)
                            }
                        }
                    } label: {
                        DeleteIconView()
                    }
                    .buttonStyle(BorderlessButtonStyle())
                    PasteboardCopyView(text: profile.id.path)
                    BashOpenView(path: .app(.init(name: "Finder"), args: ["-R", profile.id.path]), type: .folder)
                }
                .padding()
                ScrollView {
                    VStack(spacing: 24) {
                        HStack(alignment: .center) {
                            Text(profile.name)
                                .textSelection(.enabled)
                        }
                        VStack(alignment: .center, spacing: 4) {
                            keyValueView("App ID Name", profile.appIDName)
                            keyValueView("App ID", "\(profile.applicationIdentifier.dropFirst(profile.teamIdentifier.count + 1))")
                            keyValueView("Team", "\(profile.teamName) (\(profile.teamIdentifier))")
                            keyValueView("Platform", profile.platforms.joined(separator: ", "))
                            keyValueView("UUID", profile.uuid)
                            keyValueView("Creation Date", "\(profile.creationDate)")
                            expirationDateView(profile.expirationDate)
                        }
                        HStack {
                            Text("ENTITLEMENTS")
                                .fontWeight(.bold)
                            Spacer()
                        }
                        VStack(alignment: .center, spacing: 4) {
                            keyValueView("get-task-allow", "\(profile.taskAllow)")
                            if let apsEnvironment = profile.apsEnvironment {
                                keyValueView("aps-environment", apsEnvironment)
                            }
                            if let associatedDomains = profile.associatedDomains {
                                keyValueView("com.apple.developer.associated-domains", associatedDomains)
                            }
                            if let betaReportsActive = profile.betaReportsActive {
                                keyValueView("beta-reports-active", "\(betaReportsActive)")
                            }
                            if !profile.keychainAccessGroups.isEmpty {
                                HStack {
                                    keyValueView("keychain-access-groups") {
                                        VStack(alignment: .leading, spacing: 2) {
                                            ForEach(profile.keychainAccessGroups, id: \.self) { group in
                                                Text(group)
                                            }
                                        }
                                    }
                                }
                            }
                            if !profile.securityApplicationGroups.isEmpty {
                                HStack {
                                    keyValueView("com.apple.security.application-groups") {
                                        VStack(alignment: .leading, spacing: 2) {
                                            ForEach(profile.securityApplicationGroups, id: \.self) { group in
                                                Text(group)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        HStack {
                            Text("CERTIFICATES")
                                .fontWeight(.bold)
                            Spacer()
                        }
                        VStack(alignment: .center) {
                            ForEach(profile.signingIdentitySha1, id: \.self) { sha1 in
                                CertificateView(sha1: sha1)
                            }
                        }
                        if profile.provisionedDevices.isEmpty == false {
                            HStack {
                                Text("PROVISIONED DEVICES")
                                    .fontWeight(.bold)
                                Spacer()
                            }
                            VStack(alignment: .center) {
                                ForEach(profile.provisionedDevices, id: \.self) {
                                    keyValueView("Device ID", $0)
                                }
                            }
                        }
                    }
                }
                .padding([.leading, .trailing, .bottom])
            } else {
                ProgressView()
            }
        }
        .task(id: profileID) {
            do {
                profile = try await provisioningProfilesService.profile(profileID)
            } catch {
                alertHandler.handle(title: "Profile read error", message: nil, error: error)
                appLogger.error(error)
            }
        }
    }
    
    func keyValueView(_ key: String, _ value: String) -> some View {
        HStack {
            Text("\(key):")
                .fontWeight(.bold)
            Text(value).textSelection(.enabled)
        }
    }
    
    func keyValueView(_ key: String, @ViewBuilder _ value: () -> any View) -> some View {
        HStack {
            Text("\(key):")
                .fontWeight(.bold)
            AnyView(value().textSelection(.enabled))
        }
    }
    
    func expirationDateView(_ date: Date) -> some View {
        HStack {
            Text("Expiration Date:")
                .fontWeight(.bold)
            if date < Date() {
                Text("\(date)")
                    .foregroundStyle(.red)
            } else if date.timeIntervalSince1970 - Date().timeIntervalSince1970 < TimeInterval(3600 * 24 * 7) {
                Text("\(date)")
                    .foregroundStyle(.yellow)
            } else {
                Text("\(date)")
                    .foregroundStyle(.green)
            }
        }
    }
}

private struct CertificateView: View {
    
    let sha1: String
    @State private var hasInKeychain: Bool?
    @Environment(\.provisioningProfilesService) private var provisioningProfilesService
    
    var body: some View {
        HStack {
            Text("SHA-1:")
                .fontWeight(.bold)
            Text(sha1).textSelection(.enabled)
            if let hasInKeychain {
                if hasInKeychain {
                    Image(systemName: "checkmark.circle")
                        .foregroundColor(.green)
                } else {
                    Image(systemName: "xmark.circle")
                        .foregroundColor(.red)
                }
            } else {
                Image(systemName: "questionmark.circle")
                    .foregroundColor(.yellow)
            }
        }
        .task {
            hasInKeychain = await provisioningProfilesService.keychainHasCertificate(sha1: sha1)
        }
    }
}

#Preview {
    ProvisioningProfilesItemView(
        profileID: .init(id: URL(fileURLWithPath: "/")),
        provisioningProfilesSelected: .constant(nil)
    )
    .padding()
    .frame(width: 500, height: 600)
    .withAppMocks()
}
