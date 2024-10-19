
import SwiftUI

struct MainMenu {
    
    let sections: [Section]
    
    struct Section: HashableIdentifiable {
        
        var id: MainMenuSection { section }
        
        let section: MainMenuSection
        let items: [Item]
        
        struct Item: HashableIdentifiable {
            
            var id: MainMenuItem { item }
            
            let item: MainMenuItem
        }
    }
}

enum MainMenuSection: String, Identifiable, Hashable {
    
    var id: String { rawValue }
    
    case system
    case project
    
    var title: String {
        switch self {
        case .system:
            return "System"
        case .project:
            return "Project"
        }
    }
}

enum MainMenuItem: String, Identifiable, Hashable {
    
    var id: RawValue { rawValue }
    
    case simulators
    case derivedData
    case toolsIssues
    case git
    case swiftPMCaches
    case deviceSupport
    case carthage
    case previews
    case ibSupport
    case xcArchives
    case provisioningProfiles
    case scipio
    case fastlane
    case spmGraph
    case ipaAnalyser
    
    var title: String {
        switch self {
        case .ipaAnalyser:
            return "IPA Analyser"
        case .spmGraph:
            return "SwiftPM Graph"
        case .fastlane:
            return "Fastlane"
        case .scipio:
            return "Scipio"
        case .simulators:
            return "Simulators"
        case .derivedData:
            return "Derived Data"
        case .toolsIssues:
            return "Issues"
        case .git:
            return "Git"
        case .swiftPMCaches:
            return "SwiftPM"
        case .deviceSupport:
            return "Device Support"
        case .carthage:
            return "Carthage"
        case .previews:
            return "SwiftUI Previews"
        case .ibSupport:
            return "IB Support"
        case .xcArchives:
            return "Archives"
        case .provisioningProfiles:
            return "Provisioning Profiles"
        }
    }
    
    var icon: ImageResource {
        switch self {
        case .ipaAnalyser:
            return .ipa
        case .spmGraph:
            return .spmGraph
        case .fastlane:
            return .fastlane
        case .scipio:
            return .scipio
        case .simulators:
            return .simulator
        case .derivedData:
            return .derivedData
        case .toolsIssues:
            return .issues
        case .git:
            return .git
        case .swiftPMCaches:
            return .spm
        case .deviceSupport:
            return .deviceSupport
        case .carthage:
            return .carthage
        case .previews:
            return .swiftuiPreviews
        case .ibSupport:
            return .ibSupport
        case .xcArchives:
            return .archives
        case .provisioningProfiles:
            return .provisioningProfiles
        }
    }
}
