
import SwiftUI

struct BaseErrorView: View {
    
    let error: Error
    
    var body: some View {
        Group {
            if let error = error as? CliToolError {
                switch error {
                case .decode(let error), .run(let error), .fs(let error):
                    Text(error.localizedDescription)
                        .foregroundColor(.gray)
                case .exec(let error):
                    Text(error)
                        .foregroundColor(.gray)
                }
            } else {
                Text(error.localizedDescription)
                    .foregroundColor(.gray)
            }
        }
    }
}

#Preview {
    BaseErrorView(error: CliToolError.exec("wrong command."))
        .frame(width: 300, height: 200)
}
