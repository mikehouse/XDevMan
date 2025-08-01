
import SwiftUI

@main
struct XDevMan: App {

    @State private var isErrorAlertPresented = false
    @State private var alertErrorTitle = ""
    @State private var alertError: Error?
    @Environment(\.bashService) private var bashService
    @Environment(\.gitService) private var gitService

    var body: some Scene {
        Window("XDevMan", id: Windows.main.rawValue) {
            ContentView(menu:
                    .init(sections: [
                        .init(section: .system, items: [
                            .init(item: .simulators),
                            .init(item: .previews),
                            .init(item: .derivedData),
                            .init(item: .swiftPMCaches),
                            .init(item: .carthage),
                            .init(item: .deviceSupport),
                            .init(item: .xcArchives),
                            .init(item: .provisioningProfiles),
                            .init(item: .ibSupport),
                            .init(item: .toolsIssues),
                        ]),
                        .init(section: .project, items: [
                            .init(item: .git)
                        ])
                    ])
            )
            .alert(Text(alertErrorTitle), isPresented: $isErrorAlertPresented, actions: {
                Button("Ok", role: .cancel) {}
            }, message: {
                if let alertError {
                    BaseErrorView(error: alertError)
                } else {
                    Text("Unknown Error.")
                }
            })
            .withAlertHandler(AlertHandler { title, _, error in
                self.alertErrorTitle = title
                self.alertError = error
                self.isErrorAlertPresented = true
            })
            .withDerivedDataService(DerivedDataService(bash: bashService))
            .withSwiftPMCachesService(SwiftPMCachesService(bashService: bashService))
            .withDeviceSupportService(DeviceSupportService(bashService: bashService))
            .withCarthageService(CarthageService(bashService: bashService))
            .withIBSupportService(IBSupportService(bashService: bashService))
            .withXCArchiveService(XCArchivesService(bashService: bashService))
            .withCoreSimulatorLogsService(CoreSimulatorLogs.Service(bashService: bashService))
            .withProvisioningProfilesService(ProvisioningProfiles.Service(bashService: bashService, keyhain: KeychainService()))
            .withSimulatorAppsService(SimulatorAppsService())
            .task {

            }
        }
    }
}

enum Windows: String {

    case main
}
