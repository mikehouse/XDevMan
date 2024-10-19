
import SwiftUI

@MainActor
protocol AlertHandlerInterface {
    
    func handle(title: String, message: String?, error: Error)
}

final class AlertHandler: AlertHandlerInterface {
    
    private let handler: (String, String?, Error) -> Void
    
    init(handler: @escaping (String, String?, Error) -> Void) {
        self.handler = handler
    }
    
    func handle(title: String, message: String?, error: Error) {
        handler(title, message, error)
    }
}

private struct AlertHandlerEmpty: AlertHandlerInterface {
    func handle(title: String, message: String?, error: Error) { }
}

class AlertHandlerMock: AlertHandlerInterface {
    static let shared = AlertHandlerMock()
    func handle(title: String, message: String?, error: Error) { }
}

extension EnvironmentValues {
    
    @Entry var alertHandler: AlertHandlerInterface = AlertHandlerEmpty()
}

extension View {
    
    func withAlertHandler(_ alertHandler: AlertHandlerInterface) -> some View {
        environment(\.alertHandler, alertHandler)
    }
}
