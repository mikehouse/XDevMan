
import SwiftUI

private let byteCounter: ByteCountFormatter = {
    let bc = ByteCountFormatter()
    bc.allowedUnits = [.useGB]
    return bc
}()

struct ByteSizeView: View {
    
    let title: String?
    let size: Int
    
    var body: some View {
        if let title {
            Text("\(title): \(byteCounter.string(fromByteCount: Int64(size)))")
        } else {
            Text("\(byteCounter.string(fromByteCount: Int64(size)))")
        }
    }
}

#Preview {
    ByteSizeView(title: "Data", size: 12313244)
        .padding()
}
