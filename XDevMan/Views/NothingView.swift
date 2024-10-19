
import SwiftUI

struct NothingView: View {
    
    let text: String
    
    var body: some View {
        Text(text)
            .foregroundColor(.gray)
    }
}

#Preview {
    NothingView(text: "Nothing.")
}
