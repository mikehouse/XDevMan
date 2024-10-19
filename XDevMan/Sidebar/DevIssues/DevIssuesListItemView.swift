
import SwiftUI

struct DevIssuesListItemView: View {
    
    let issue: DevIssuesType
    
    var body: some View {
        HStack {
            Image(.simulator)
                .resizable()
                .frame(width: 24, height: 24)
            Text(issue.title)
            Spacer()
        }
    }
}

#Preview {
    DevIssuesListItemView(
        issue: .simulators
    )
    .padding()
    .frame(width: 300, height: 100)
    .withAppMocks()
}
