
import SwiftUI

struct DerivedDataListView: View {
    
    @Binding var derivedDataSelection: DerivedData?
    @Binding var derivedDataReload: UUID
    @State private var derivedData: [DerivedData]?
    @State private var navigationTitle = "Derived Data"
    @Environment(\.derivedDataService) private var derivedDataService
    
    var body: some View {
        Group {
            if let derivedData {
                if derivedData.isEmpty {
                    NothingView(text: "No derived data found.")
                } else {
                    List(derivedData, id: \.self, selection: $derivedDataSelection) { derivedData in
                        DerivedDataListItemView(derivedData: derivedData)
                            .modifier(ListItemViewPaddingModifier())
                    }
                }
            } else {
                ProgressView()
            }
        }
        .navigationTitle(navigationTitle)
        .task(id: derivedDataReload) {
            derivedData = await derivedDataService.findDerivedData()
            derivedDataSelection = derivedData?
                .first(where: { $0.ideName == derivedDataSelection?.ideName })
        }
        .onChange(of: derivedDataSelection) {
            if let derivedData = derivedDataSelection {
                navigationTitle = derivedData.ideName
            } else {
                navigationTitle = "Derived Data"
            }
        }
        .onDisappear {
            derivedDataSelection = nil
        }
    }
}

#Preview {
    DerivedDataListView(
        derivedDataSelection: .constant(nil),
        derivedDataReload: .constant(.init())
    )
    .frame(width: 300, height: 200)
    .withDerivedDataService(DerivedDataServiceMockImpl())
    .withAppMocks()
}

private class DerivedDataServiceMockImpl: DerivedDataServiceMock {
    
    override func findDerivedData() async -> [DerivedData] {
        [.init(
            ideName: "Xcode",
            path: URL(fileURLWithPath: "/"),
            apps: []
        ),
         .init(
             ideName: "AppCode",
             path: URL(fileURLWithPath: "/"),
             apps: []
         )
        ]
    }
}
