
import SwiftUI

struct ToolbarDefaultButtonStyle: PrimitiveButtonStyle {
    
    func makeBody(configuration: Configuration) -> some View {
        if #available(macOS 26.0, *) {
            Button(configuration)
                .buttonStyle(.bordered)
        } else {
            Button(configuration)
                .buttonStyle(.borderless)
        }
    }
}

extension PrimitiveButtonStyle where Self == ToolbarDefaultButtonStyle {

    static var toolbarDefault: ToolbarDefaultButtonStyle { Self() }
}
