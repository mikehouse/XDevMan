
import SwiftUI

struct GitBranchListItemView: View {
    
    let branch: Branch
    @State private var isShowingPopover = false
    
    var body: some View {
        HStack {
            Text(branch.name)
            if branch.isProtected || branch.isCurrent {
                Image(systemName: "lock.shield")
                    .foregroundStyle(.green)
                    .popover(isPresented: $isShowingPopover, arrowEdge: .bottom) {
                        Text("Protected").padding(.all, 8)
                    }
                    .onHover { on in
                        isShowingPopover = on
                    }
            }
        }
    }
}

#Preview {
    GitBranchListItemView(branch: .init(name: "master"))
        .withAppMocks()
}
