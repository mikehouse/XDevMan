
import SwiftUI

enum DevIssuesType: String, Identifiable, Hashable, CaseIterable {
    
    var id: RawValue { rawValue }
    
    case simulators
    case simulatorLogs
    case dyldCache
    
    var title: String {
        switch self {
        case .simulators:
            return "Simulators"
        case .simulatorLogs:
            return "Logs CoreSimulator"
        case .dyldCache:
            return "Dyld Cache"
        }
    }
}

struct DevIssuesListView: View {
    
    @Binding var devIssueSelected: DevIssuesType?
    @State private var devIssues: [DevIssuesType] = DevIssuesType.allCases
    
    var body: some View {
        Group {
            List(devIssues, id: \.self, selection: $devIssueSelected) { issue in
                DevIssuesListItemView(issue: issue)
                    .modifier(ListItemViewPaddingModifier())
            }
        }
        .navigationTitle("Dev Issues")
        .onDisappear {
            devIssueSelected = nil
        }
    }
}

#Preview {
    DevIssuesListView(
        devIssueSelected: .constant(nil)
    )
    .padding()
    .frame(width: 300, height: 300)
    .withAppMocks()
}
