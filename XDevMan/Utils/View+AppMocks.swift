
import SwiftUI

extension View {
    
    func withAppMocks() -> some View {
        withBashService(BashProviderMock.self)
            .withGitService(GitProviderMock.self)
            .withRuntimesService(RuntimesProviderMock.self)
            .withDevicesService(DevicesProviderMock.self)
            .withAlertHandler(AlertHandlerMock.shared)
            .withDerivedDataService(DerivedDataServiceMock.shared)
            .withSwiftPMCachesService(SwiftPMCachesServiceMock.shared)
            .withDeviceSupportService(DeviceSupportServiceMock.shared)
            .withCarthageService(CarthageServiceMock.shared)
            .withPreviewsService(PreviewsServiceMock.shared)
            .withIBSupportService(IBSupportServiceMock.shared)
            .withXCArchiveService(XCArchivesServiceMock.shared)
            .withCoreSimulatorLogsService(CoreSimulatorLogs.ServiceMock.shared)
            .withProvisioningProfilesService(ProvisioningProfiles.ServiceMock.shared)
            .withKeychainService(KeychainServiceMock.shared)
            .withSimulatorAppsService(SimulatorAppsServiceMock.shared)
    }
}
