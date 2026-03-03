import SwiftUI

@Observable
final class AppLogsWindowViewLoggerDelegate: AppLoggerDelegate {

    private(set) var events: [AppLoggerEvent] = []

    func logEvent(_ event: AppLoggerEvent) {
        events.append(event)
    }
}

struct AppLogsWindowView: View {

    let loggerDelegate: AppLogsWindowViewLoggerDelegate
    @State private var reversed = true
    @State private var logsText = ""

    var body: some View {
        GeometryReader { _ in
            VStack {
                HStack {
                    Toggle("Reversed", isOn: $reversed)
                        .toggleStyle(.switch)
                    Spacer()
                }
                Divider()
                TextEditor(text: $logsText)
                    .font(.system(.body, design: .monospaced))
            }
            .padding()
            .onChange(of: loggerDelegate.events) {
                if reversed {
                    logsText = loggerDelegate.events.reversed().map(\.log).joined(separator: "\n")
                } else {
                    logsText = loggerDelegate.events.map(\.log).joined(separator: "\n")
                }
            }
        }
    }
}
