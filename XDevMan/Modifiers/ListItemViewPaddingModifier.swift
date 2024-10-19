
import SwiftUI

struct ListItemViewPaddingModifier: ViewModifier {
    
    func body(content: Content) -> some View {
        content.padding([.bottom, .top], 6)
    }
}
