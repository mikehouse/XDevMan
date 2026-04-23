
import SwiftUI

@main
struct XDevMan: App {

    @State private var isErrorAlertPresented = false
    @State private var alertErrorTitle = ""
    @State private var alertError: Error?
    @State private var loggerDelegate = AppLogsWindowViewLoggerDelegate()
    @Environment(\.bashService) private var bashService
    @Environment(\.gitService) private var gitService
    @Environment(\.devicesService) private var devicesService

    var body: some Scene {
        Window("XDevMan", id: Windows.main.rawValue) {
            ContentView(menu:
                    .init(sections: [
                        .init(section: .system, items: [
                            .init(item: .simulators),
                            .init(item: .previews),
                            .init(item: .derivedData),
                            .init(item: .swiftPMCaches),
                            .init(item: .spmGraph),
                            .init(item: .scipio),
                            .init(item: .carthage),
                            .init(item: .cocoaPods),
                            .init(item: .deviceSupport),
                            .init(item: .xcArchives),
                            .init(item: .provisioningProfiles),
                            .init(item: .ibSupport),
                            .init(item: .toolsIssues),
                            .init(item: .diagnosticReports),
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
            .withCocoaPodsService(CocoaPodsService(bashService: bashService))
            .withIBSupportService(IBSupportService(bashService: bashService))
            .withXCArchiveService(XCArchivesService(bashService: bashService))
            .withCoreSimulatorLogsService(CoreSimulatorLogs.Service(bashService: bashService))
            .withProvisioningProfilesService(ProvisioningProfiles.Service(bashService: bashService, keyhain: KeychainService(), ))
            .withSimulatorAppsService(SimulatorAppsService(devicesProvider: devicesService))
            .withFastlaneService(FastlaneService(bashService: bashService))
            .withDiagnosticReportsService(DiagnosticReportsService(bashService: bashService))
            .withScipioService(ScipioService(bashService: bashService))
            .withSwiftPMService(SwiftPMService(bashService: bashService))
            .withSwiftPMGraphService(SwiftPMGraphService())
            .withAppLogger(AppLogger.runtimeLogger(loggerDelegate))
            .task {

            }
        }

        Window("XDevMan: App logs", id: Windows.appLogs.rawValue) {
            AppLogsWindowView(loggerDelegate: loggerDelegate)
        }
        .defaultPosition(.center)
        .defaultSize(width: 480, height: 240)
    }
}

enum Windows: String {

    case main
    case appLogs
}
