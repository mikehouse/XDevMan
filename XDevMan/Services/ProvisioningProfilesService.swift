
import SwiftUI
import CryptoKit

enum ProvisioningProfiles {}

extension ProvisioningProfiles {
    
    struct ID: HashableIdentifiable {
        
        let id: URL
    }
    
    struct Profile: HashableIdentifiable {
        
        let id: ID.ID
        let appIDName: String
        let name: String
        let applicationIdentifier: String
        let creationDate: Date
        let expirationDate: Date
        let platforms: [String]
        let developerCertificates: [Data]
        let provisionedDevices: [String]
        let teamIdentifier: String
        let teamName: String
        let uuid: String
        let signingIdentitySha256: [String]
        let signingIdentitySha1: [String]
        let apsEnvironment: String?
        let securityApplicationGroups: [String]
        let keychainAccessGroups: [String]
        let associatedDomains: String?
        let taskAllow: Bool
        let betaReportsActive: Bool?
    }
}


extension ProvisioningProfiles {
    
    enum Error: Swift.Error {
        
        case dataDecodeError(String)
        case urlMalformedError(String)
        case dictionaryDecodeError(URL)
        case dictionaryMissedKeys([String])
    }
}

extension ProvisioningProfiles {
    
    @MainActor
    protocol Interface: Sendable {
        
        nonisolated func ids() async -> [ID]
        nonisolated func open() async
        nonisolated func delete(_ id: ID) async throws
        nonisolated func profile(_ id: ID) async throws -> Profile
        nonisolated func keychainHasCertificate(sha1: String) async -> Bool?
    }
}


extension ProvisioningProfiles {
    
    final class Service: Interface {
        
        private let bashService: BashProvider.Type
        private let keyhain: KeychainServiceInterface
        
        init(bashService: BashProvider.Type, keyhain: KeychainServiceInterface) {
            self.bashService = bashService
            self.keyhain = keyhain
        }
        
        private let root = URL(
            fileURLWithPath: "/Users/\(NSUserName())/Library/MobileDevice/Provisioning Profiles",
            isDirectory: true
        )
        
        func ids() async -> [ID] {
            await Task<[ID], Never>.detached { [self] in
                let fileManager = FileManager.default
                return ((try? fileManager.contentsOfDirectory(atPath: root.path)) ?? [])
                    .filter({ $0.hasSuffix(".mobileprovision") })
                    .map({ root.appendingPathComponent($0, isDirectory: false) })
                    .map({ url -> (URL, Date) in
                        (url, (try? fileManager.attributesOfItem(atPath: url.path)[.creationDate] as? Date) ?? Date())
                    })
                    .sorted(by: { $0.1 > $1.1 })
                    .map({ ID(id: $0.0) })
            }.value
        }
        
        func open() async {
            try? await bashService.open(root)
        }
        
        func delete(_ id: ID) async throws {
            try await bashService.rmFile(id.id)
        }
        
        func profile(_ id: ID) async throws -> Profile {
            let task = Task<Profile, Swift.Error>.detached {
                let xml = try await CliTool.exec("/usr/bin/security", arguments: [
                    "cms", "-D", "-i", "\(id.id.path)"
                ])
                guard let data = xml.data(using: .utf8) else {
                    throw Error.dataDecodeError(xml)
                }
                guard let url = URL(string: "data:text/xml;base64,\(data.base64EncodedString())") else {
                    throw Error.urlMalformedError("data:text/xml;base64,\(data.base64EncodedString())")
                }
                guard let dict = NSDictionary(contentsOf: url) else {
                    throw Error.dictionaryDecodeError(url)
                }
                guard let name = dict["Name"] as? String,
                      let developerCertificates = dict["DeveloperCertificates"] as? [Data],
                      let platforms = dict["Platform"] as? [String],
                      let creationDate = dict["CreationDate"] as? Date,
                      let teamName = dict["TeamName"] as? String,
                      let appIDName = dict["AppIDName"] as? String,
                      let uuid = dict["UUID"] as? String,
                      let expirationDate = dict["ExpirationDate"] as? Date,
                      let entitlements = dict["Entitlements"] as? [String: Any],
                      let applicationIdentifier = entitlements["application-identifier"] as? String,
                      let keychainAccessGroups = entitlements["keychain-access-groups"] as? [String],
                      let taskAllow = entitlements["get-task-allow"] as? Bool,
                      let teamIdentifier = entitlements["com.apple.developer.team-identifier"] as? String else {
                    throw Error.dictionaryMissedKeys(Array((dict as? [String: Any] ?? [:]).keys))
                }
                let securityApplicationGroups = (entitlements["com.apple.security.application-groups"] as? [String]) ?? []
                let betaReportsActive = entitlements["beta-reports-active"] as? Bool
                let apsEnvironment = entitlements["aps-environment"] as? String
                let associatedDomains = entitlements["com.apple.developer.associated-domains"] as? String
                let provisionedDevices = dict["ProvisionedDevices"] as? [String] ?? []
                let signingIdentitySha256 = developerCertificates.map({ cert in
                    var hasher = SHA256()
                    hasher.update(data: cert)
                    return hasher.finalize().map { String(format: "%02hhX", $0) }.joined()
                })
                let signingIdentitySha1 = developerCertificates.map({ cert in
                    var hasher = Insecure.SHA1()
                    hasher.update(data: cert)
                    return hasher.finalize().map { String(format: "%02hhX", $0) }.joined()
                })
                return Profile(
                    id: id.id,
                    appIDName: appIDName,
                    name: name,
                    applicationIdentifier: applicationIdentifier,
                    creationDate: creationDate,
                    expirationDate: expirationDate,
                    platforms: platforms,
                    developerCertificates: developerCertificates,
                    provisionedDevices: provisionedDevices,
                    teamIdentifier: teamIdentifier,
                    teamName: teamName,
                    uuid: uuid,
                    signingIdentitySha256: signingIdentitySha256,
                    signingIdentitySha1: signingIdentitySha1,
                    apsEnvironment: apsEnvironment,
                    securityApplicationGroups: securityApplicationGroups,
                    keychainAccessGroups: keychainAccessGroups,
                    associatedDomains: associatedDomains,
                    taskAllow: taskAllow,
                    betaReportsActive: betaReportsActive
                )
            }
            do {
                return try await task.value
            } catch {
                throw CliToolError.fs(error)
            }
        }
        
        func keychainHasCertificate(sha1: String) async -> Bool? {
            await keyhain.hasCertificate(sha1: sha1)
        }
    }
}

extension ProvisioningProfiles {
    
    fileprivate final class EmptyService: ServiceMock { }
}

extension ProvisioningProfiles {
    
    class ServiceMock: Interface {
        static let shared = ServiceMock()
        func ids() async -> [ID] { [] }
        func open() async { }
        func delete(_ id: ID) async throws { }
        func profile(_ id: ID) async throws -> Profile {
            .init(
                id: URL(fileURLWithPath: "/"),
                appIDName: "XC aaa bbb ccc AppName",
                name: "iOS Team Provisioning Profile: com.aaa.bbb.AppName",
                applicationIdentifier: "4HUHB9J47M.com.aaa.bbb.AppName",
                creationDate: Date(),
                expirationDate: Date(),
                platforms: ["iOS", "xrOS", "visionOS"],
                developerCertificates: [
                    Data.init(base64Encoded: "MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAyjhUpstWqsgkOUjpjO7sX7h/JpG8NFN6znxjgGF3ZF6lByO2Of5QLRVWWHAtfsRuwUqFPi/w3oQaoVfJr3sY/2r6FRJJFQgZrKrbKjLtlmNoUhU9jIrsv2sYleADrAF9lwVnzg6FlTdq7Qm2rmfN") ?? Data()
                ],
                provisionedDevices: [
                    "00008101-00024C983A",
                    "0e1c629eeac9f4a3ba613a4ec6aa444",
                    "e474199a80e6d315beec13a1e6bda55e",
                    "7d4be31b6311249184a0ce317d0509fc",
                    "b1495776bd90c10cf95dc045175b1dd25",
                    "7701bdc4a99b733024efcb8417f3972e6"
                ],
                teamIdentifier: "4HUHB9J47M",
                teamName: "Ivan Inanov",
                uuid: "ce518a63-c831-4a55-8d9b-481b1010dfcf",
                signingIdentitySha256: ["CE057691D730F89CA25E916F7335F4C8A15713DCD273A658C024023F8EB809C2"],
                signingIdentitySha1: ["FF6797793A3CD798DC5B2ABEF56F73EDC9F83A64"],
                apsEnvironment: "production",
                securityApplicationGroups: ["a.b.c", "d.b.e"],
                keychainAccessGroups: ["3VV6F4ABNM.*", "a.b.n"],
                associatedDomains: "*",
                taskAllow: true,
                betaReportsActive: true
            )
        }
        func keychainHasCertificate(sha1: String) async -> Bool? { nil }
    }
}

extension EnvironmentValues {
    
    @Entry var provisioningProfilesService: ProvisioningProfiles.Interface = ProvisioningProfiles.EmptyService()
}

extension View {
    
    func withProvisioningProfilesService(_ provisioningProfilesService: ProvisioningProfiles.Interface) -> some View {
        environment(\.provisioningProfilesService, provisioningProfilesService)
    }
}
