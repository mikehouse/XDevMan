
import SwiftUI

struct ContentView: View {

    let menu: MainMenu

    @State private var selectedMenu: MainMenuItem?
    // Simulators
    @State private var selectedRuntime: Runtime?
    @State private var reloadSimulators: UUID?
    // Git
    @State private var selectedBranch: Branch?
    @State private var selectedRepo: URL?
    @State private var deletedBranch: Branch?
    @State private var reloadBranches = true
    // Derived Data
    @State private var derivedDataSelection: DerivedData?
    @State private var derivedDataReload = UUID()
    // SwiftPM
    @State private var sourceSelected: SwiftPMListView.Source?
    @State private var deletedRepository: SwiftPMCachesRepository?
    // Devices Support
    @State private var selectedDeviceSupportOs: DeviceSupportOs?
    @State private var deletedDeviceSupportOsItem: DeviceSupportOsItem?
    // Cathage
    @State private var carthageListItemSelected: CarthageSource?
    @State private var deleteCarthageItemdItem: CarthageItem?
    @State private var deleteCarthageDerivedDataItem: CarthageDerivedDataItem?
    // CocoaPods
    @State private var selectedCocoaPodsVersion: CocoaPodsLibraryVersion?
    @State private var deletedCocoaPodsVersion: CocoaPodsLibraryVersion?
    // IB Support
    @State private var deletedIBSupportItem: IBSupportItem?
    @State private var seletedIBSupportItem: String?
    // Archives
    @State private var xcArchiveSelected: XCArchiveID?
    @State private var xcArchiveDeleted: XCArchiveID?
    // Issues
    @State private var devIssueSelected: DevIssuesType?
    // Provision Profiles
    @State private var provisioningProfilesSelected: ProvisioningProfiles.ID?
    // Fastlane
    @State private var selectedFastlaneLane: FastlaneLane?
    @State private var selectedFastlaneCommandDirectory: URL?

    var body: some View {
        NavigationSplitView {
            VStack {
                List(selection: $selectedMenu) {
                    ForEach(menu.sections) { section in
                        Section(header: Text("\(section.section.title)")) {
                            ForEach(section.items.map(\.item), id: \.self) { item in
                                SidebarMenuItemView(menu: item)
                            }
                        }
                    }
                }
                Spacer()
                AppInfoView()
            }
            .navigationSplitViewColumnWidth(min: 236, ideal: 236, max: 300)
        } content: {
            Group {
                switch selectedMenu {
                case .simulators, .previews:
                    SimulatorRuntimeListView(
                        runtimeSelected: $selectedRuntime,
                        reloadSimulators: $reloadSimulators,
                        previewsMode: selectedMenu == .previews
                    )
                        .id(selectedMenu)
                case .derivedData:
                    DerivedDataListView(
                        derivedDataSelection: $derivedDataSelection,
                        derivedDataReload: $derivedDataReload
                    )
                case .swiftPMCaches:
                    SwiftPMListView(
                        sourceSelected: $sourceSelected,
                        deletedRepository: $deletedRepository
                    )
                case .git:
                    GitBranchListView(
                        branch: $selectedBranch,
                        gitRepoPath: $selectedRepo,
                        reloadBranches: $reloadBranches,
                        deleted: $deletedBranch
                    )
                case .deviceSupport:
                    DeviceSupportOsListView(
                        deletedDeviceSupportOsItem: $deletedDeviceSupportOsItem,
                        selectedDeviceSupportOs: $selectedDeviceSupportOs
                    )
                case .carthage:
                    CarthageListView(
                        carthageListItemSelected: $carthageListItemSelected,
                        deleteCarthageItemdItem: $deleteCarthageItemdItem,
                        deleteCarthageDerivedDataItem: $deleteCarthageDerivedDataItem
                    )
                case .cocoaPods:
                    CocoaPodsListView(
                        selectedVersion: $selectedCocoaPodsVersion,
                        deletedVersion: $deletedCocoaPodsVersion
                    )
                case .ibSupport:
                    IBSupportListView(
                        seletedIBSupportItem: $seletedIBSupportItem,
                        deletedIBSupportItem: $deletedIBSupportItem
                    )
                case .xcArchives:
                    XCArchivesListView(
                        xcArchiveSelected: $xcArchiveSelected,
                        xcArchiveDeleted: $xcArchiveDeleted
                    )
                case .toolsIssues:
                    DevIssuesListView(
                        devIssueSelected: $devIssueSelected
                    )
                case .provisioningProfiles:
                    ProvisioningProfilesListView(
                        provisioningProfilesSelected: $provisioningProfilesSelected
                    )
                case .fastlane:
                    FastlaneListView(
                        selectedLane: $selectedFastlaneLane,
                        commandDirectory: $selectedFastlaneCommandDirectory
                    )
                case .scipio:
                    EmptyContentView()
                default:
                    NothingView(text: "No menu selected.")
                }
            }
            .modifier(ContentColumnWidthModifier(selectedMenu: $selectedMenu))
        } detail: {
            Group {
                switch selectedMenu {
                case .simulators, .previews:
                    if let selectedRuntime {
                        SimulatorListView(
                            runtime: selectedRuntime,
                            reloadSimulators: $reloadSimulators
                        )
                        .id(selectedMenu)
                    } else {
                        NothingView(text: "No runtime selected.")
                    }
                case .derivedData:
                    if let derivedDataSelection {
                        DerivedDataListAppView(
                            derivedData: derivedDataSelection,
                            derivedDataReload: $derivedDataReload
                        )
                    } else {
                        NothingView(text: "No IDE selected.")
                    }
                case .swiftPMCaches:
                    if sourceSelected != nil {
                        SwiftPMRepositoriesView(deletedRepository: $deletedRepository)
                    } else {
                        NothingView(text: "No SPM package selected.")
                    }
                case .git:
                    if let selectedRepo, let selectedBranch {
                        GitBranchView(
                            branch: selectedBranch,
                            path: selectedRepo,
                            deleted: $deletedBranch
                        )
                    } else {
                        NothingView(text: "No branch selected.")
                    }
                case .deviceSupport:
                    if let selectedDeviceSupportOs {
                        DeviceSupportListView(
                            os: selectedDeviceSupportOs,
                            deletedDeviceSupportOsItem: $deletedDeviceSupportOsItem
                        )
                    } else {
                        NothingView(text: "No OS selected.")
                    }
                case .carthage:
                    if let carthageListItemSelected {
                        switch carthageListItemSelected {
                        case .dependencies, .binaries:
                            CarthageItemListView(
                                item: carthageListItemSelected,
                                deleteCarthageItemdItem: $deleteCarthageItemdItem
                            )
                        case .derivedData:
                            CarthageDerivedDataListView(
                                item: carthageListItemSelected,
                                deleteCarthageDerivedDataItem: $deleteCarthageDerivedDataItem
                            )
                        }
                    } else {
                        NothingView(text: "No item selected.")
                    }
                case .cocoaPods:
                    if let selectedCocoaPodsVersion {
                        CocoaPodsPodspecView(
                            version: selectedCocoaPodsVersion,
                            selectedVersion: $selectedCocoaPodsVersion,
                            deletedVersion: $deletedCocoaPodsVersion
                        )
                    } else {
                        NothingView(text: "No library version selected.")
                    }
                case .ibSupport:
                    if seletedIBSupportItem != nil {
                        IBSupportItemListView(
                            deletedIBSupportItem: $deletedIBSupportItem
                        )
                    } else {
                        NothingView(text: "No item selected.")
                    }
                case .xcArchives:
                    if let xcArchiveSelected {
                        XCArchivesItemView(
                            archiveId: xcArchiveSelected,
                            xcArchiveDeleted: $xcArchiveDeleted
                        )
                    } else {
                        NothingView(text: "No archive selected.")
                    }
                case .toolsIssues:
                    if let devIssueSelected {
                        switch devIssueSelected {
                        case .simulators:
                            DevIssuesSimulatorsListView()
                        case .simulatorLogs:
                            DevIssuesCoreSimulatorLogsListView()
                        case .dyldCache:
                            SimulatorDyldCacheListView()
                        }
                    } else {
                        NothingView(text: "No issue type selected.")
                    }
                case .provisioningProfiles:
                    if let id = provisioningProfilesSelected {
                        ProvisioningProfilesItemView(
                            profileID: id,
                            provisioningProfilesSelected: $provisioningProfilesSelected
                        )
                    } else {
                        NothingView(text: "No profile selected.")
                    }
                case .fastlane:
                    if let selectedFastlaneLane, let selectedFastlaneCommandDirectory {
                        FastlaneLaneView(
                            lane: selectedFastlaneLane,
                            commandDirectory: selectedFastlaneCommandDirectory
                        )
                    } else {
                        NothingView(text: "No lane has selected.")
                    }
                case .scipio:
                    ScipioView()
                default:
                    NothingView(text: "Nothing")
                }
            }
            .navigationSplitViewColumnWidth(min: 540, ideal: 540, max: nil)
        }
    }
}

private struct ContentColumnWidthModifier: ViewModifier {

    @Binding var selectedMenu: MainMenuItem?

    func body(content: Content) -> some View {
        switch selectedMenu {
        case .scipio:
            content
                .navigationSplitViewColumnWidth(0)

        default:
            content
                .navigationSplitViewColumnWidth(min: 300, ideal: 300, max: 360)
        }
    }
}

#Preview {
    ContentView(menu: .init(sections: [
            .init(section: .system, items: [
            .init(item: .simulators),
            .init(item: .derivedData),
            .init(item: .swiftPMCaches),
            .init(item: .scipio),
            .init(item: .carthage),
            .init(item: .cocoaPods),
            .init(item: .deviceSupport),
            .init(item: .xcArchives),
            .init(item: .previews),
            .init(item: .provisioningProfiles),
            .init(item: .ibSupport),
            .init(item: .toolsIssues),
            .init(item: .fastlane),
        ]),
        .init(section: .project, items: [.init(item: .git)])
    ]))
    .withAppMocks()
    .frame(height: 600)
}
