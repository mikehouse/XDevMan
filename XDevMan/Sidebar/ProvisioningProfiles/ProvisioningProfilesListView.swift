
import SwiftUI

struct ProvisioningProfilesListView: View {
    
    @Binding var provisioningProfilesSelected: ProvisioningProfiles.ID?
    @Environment(\.provisioningProfilesService) private var provisioningProfilesService
    @State private var ids: [ProvisioningProfiles.ID]?
    
    var body: some View {
        Group {
            if let ids {
                if ids.isEmpty {
                    NothingView(text: "No mobile profiles found.")
                } else {
                    List(ids, id: \.self, selection: $provisioningProfilesSelected) { id in
                        ProvisioningProfilesListItemView(profileID: id)
                            .modifier(ListItemViewPaddingModifier())
                    }
                }
            } else {
                ProgressView()
                    .task {
                        await reloadIds()
                    }
            }
        }
        .navigationTitle("Provisioning Profiles")
        .toolbar {
            ToolbarItem(id: "profiles-open") {
                BashOpenView(
                    path: .custom({ await provisioningProfilesService.open() }),
                    type: .toolbarFolder
                )
            }
        }
        .onChange(of: provisioningProfilesSelected) {
            if provisioningProfilesSelected == nil {
                Task { await reloadIds() }
            }
        }
        .onDisappear {
            provisioningProfilesSelected = nil
        }
    }
    
    private func reloadIds() async {
        ids = await provisioningProfilesService.ids()
    }
}

#Preview {
    ProvisioningProfilesListView(
        provisioningProfilesSelected: .constant(nil)
    )
    .padding()
    .frame(width: 300, height: 400)
    .withAppMocks()
}
