
import SwiftUI

struct ProvisioningProfilesListItemView: View {
    
    let profileID: ProvisioningProfiles.ID
    @State private var profile: ProvisioningProfiles.Profile?
    @Environment(\.provisioningProfilesService) private var provisioningProfilesService
    @Environment(\.appLogger) private var appLogger
    
    var body: some View {
        Group {
            if let profile {
                Text(profile.applicationIdentifier.dropFirst(profile.teamIdentifier.count + 1))
            } else {
                Text(profileID.id.lastPathComponent.dropLast(16))
                    .task {
                        do {
                            profile = try await provisioningProfilesService.profile(profileID)
                        } catch {
                            appLogger.error(error)
                        }
                    }
            }
        }
    }
}

#Preview {
    ProvisioningProfilesListItemView(
        profileID: .init(id: URL(fileURLWithPath: "/"))
    )
    .padding()
    .frame(width: 300, height: 64)
    .withAppMocks()
}
