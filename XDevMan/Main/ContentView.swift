
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
    // SwiftUI Previews
    @State private var deletedPreviewsItem: PreviewsItem?
    @State private var seletedPreviewsItem: String?
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
            .frame(minWidth: 236)
        } content: {
            Group {
                switch selectedMenu {
                case .simulators:
                    SimulatorRuntimeListView(
                        runtimeSelected: $selectedRuntime,
                        reloadSimulators: $reloadSimulators
                    )
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
                case .previews:
                    PreviewsListView(
                        seletedPreviewsItem: $seletedPreviewsItem,
                        deletedPreviewsItem: $deletedPreviewsItem
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
                default:
                    NothingView(text: "No menu selected.")
                }
            }
            .frame(minWidth: 300)
        } detail: {
            Group {
                switch selectedMenu {
                case .simulators:
                    if let selectedRuntime {
                            SimulatorListView(
                                runtime: selectedRuntime,
                                reloadSimulators: $reloadSimulators
                            )
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
                case .previews:
                    if seletedPreviewsItem != nil {
                        PreviewsItemListView(
                            deletedPreviewsItem: $deletedPreviewsItem
                        )
                    } else {
                        NothingView(text: "No item selected.")
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
                default:
                    NothingView(text: "Nothing")
                }
            }
            .frame(minWidth: 540)
        }
    }
}

#Preview {
    ContentView(menu: .init(sections: [
        .init(section: .system, items: [
            .init(item: .simulators),
            .init(item: .derivedData),
            .init(item: .swiftPMCaches),
            .init(item: .carthage),
            .init(item: .deviceSupport),
            .init(item: .xcArchives),
            .init(item: .previews),
            .init(item: .provisioningProfiles),
            .init(item: .ibSupport),
            .init(item: .toolsIssues),
        ]),
        .init(section: .project, items: [.init(item: .git)])
    ]))
    .withAppMocks()
    .frame(height: 600)
}
