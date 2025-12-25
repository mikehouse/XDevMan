
import SwiftUI

struct DerivedDataListAppView: View {
    
    let derivedData: DerivedData
    @Binding var derivedDataReload: UUID
    @State private var appDeleted: DerivedDataApp?
    @Environment(\.bashService) private var bashService
    
    var body: some View {
        Group {
            if derivedData.apps.isEmpty {
                NothingView(text: "No Apps found.")
            } else {
                List(derivedData.apps) { app in
                    DerivedDataListAppItemView(app: app, ide: derivedData.ideName, appDeleted: $appDeleted)
                        .padding([.bottom], 10)
                        .padding([.top], app == derivedData.apps[0] ? 2 : 10)
                }
            }
        }
        .toolbar {
            ToolbarItem(id: "derived-data-open") {
                BashOpenView(
                    path: .url(derivedData.path),
                    type: .button(title: "DerivedData", icon: Image(systemName: "folder"), bordered: false, toolbar: true))
            }
        }
        .onChange(of: appDeleted) {
            if appDeleted != nil {
                derivedDataReload = UUID()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.willBecomeActiveNotification)) { _ in
            derivedDataReload = UUID()
        }
    }
}

#Preview {
    DerivedDataListAppView(derivedData: .init(
        ideName: "Xcode",
        path: URL(fileURLWithPath: "/"),
        apps: [
            .init(name: "MyApp1", path: URL(fileURLWithPath: "/")),
            .init(name: "MyApp2", path: URL(fileURLWithPath: "/")),
            .init(name: "MyApp3", path: URL(fileURLWithPath: "/")),
        ]), derivedDataReload: .constant(.init())
    )
    .frame(width: 400, height: 200)
    .withAppMocks()
}
