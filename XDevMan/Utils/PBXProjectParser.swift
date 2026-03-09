
import Foundation

nonisolated final class PBXProjectParser {
    
    struct XCRemoteSwiftPackageReference: Hashable {
        let package: String
        let repositoryURL: String

        func hash(into hasher: inout Hasher) {
            hasher.combine(repositoryURL)
        }

        static func == (lhs: XCRemoteSwiftPackageReference, rhs: XCRemoteSwiftPackageReference) -> Bool {
            return lhs.repositoryURL == rhs.repositoryURL
        }
    }
    
    struct XCSwiftPackageProductDependency: Hashable {
        let package: String?
        let productName: String
    }
    
    private let projectPath: String
    private let plist: [String: Any]
    
    init(path: String) throws {
        self.projectPath = path
        let data = try Data(contentsOf: URL(fileURLWithPath: path))
        guard let plist = try PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any] else {
            throw NSError(domain: "PBXProjectParser", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to parse plist"])
        }
        self.plist = plist
    }
    
    func parseRemoteSwiftPackageReferences() -> [XCRemoteSwiftPackageReference] {
        guard let objects = plist["objects"] as? [String: [String: Any]] else {
            return []
        }

        let references: Foundation.NSMutableOrderedSet = []
        
        for (packageID, obj) in objects {
            guard let isa = obj["isa"] as? String,
                  isa == "XCRemoteSwiftPackageReference",
                  let repositoryURL = obj["repositoryURL"] as? String else {
                continue
            }
            
            references.add(XCRemoteSwiftPackageReference(
                package: packageID,
                repositoryURL: repositoryURL
            ))
        }
        
        return references.array as! [XCRemoteSwiftPackageReference]
    }
    
    func parseSwiftPackageProductDependencies() -> [XCSwiftPackageProductDependency] {
        guard let objects = plist["objects"] as? [String: [String: Any]] else {
            return []
        }

        let dependencies: Foundation.NSMutableOrderedSet = []

        for (_, obj) in objects {
            guard let isa = obj["isa"] as? String,
                  isa == "XCSwiftPackageProductDependency",
                  let productName = obj["productName"] as? String else {
                continue
            }
            
            let package = obj["package"] as? String
            
            dependencies.add(XCSwiftPackageProductDependency(
                package: package,
                productName: productName
            ))
        }
        
        return dependencies.array as! [XCSwiftPackageProductDependency]
    }
    
    func parseMarketingVersion(for targetName: String) -> String? {
        guard let objects = plist["objects"] as? [String: [String: Any]] else {
            return nil
        }
        
        // Find the target with the specified name
        var targetID: String?
        for (id, obj) in objects {
            guard let isa = obj["isa"] as? String,
                  isa == "PBXNativeTarget",
                  let name = obj["name"] as? String,
                  name == targetName else {
                continue
            }
            targetID = id
            break
        }
        
        guard let targetID = targetID,
              let target = objects[targetID],
              let buildConfigurationListID = target["buildConfigurationList"] as? String,
              let buildConfigurationList = objects[buildConfigurationListID],
              let buildConfigurationIDs = buildConfigurationList["buildConfigurations"] as? [String] else {
            return nil
        }
        
        // Look for MARKETING_VERSION in any build configuration
        for configID in buildConfigurationIDs {
            guard let config = objects[configID],
                  let buildSettings = config["buildSettings"] as? [String: Any],
                  let marketingVersion = buildSettings["MARKETING_VERSION"] as? String else {
                continue
            }
            return marketingVersion
        }
        
        return nil
    }
}
