import SwiftUI

struct FastlaneLaneView: View {
    
    let lane: FastlaneLane
    let commandDirectory: URL
    @Environment(\.fastlaneService) private var fastlaneService
    @Environment(\.alertHandler) private var alertHandler
    @Environment(\.appLogger) private var appLogger
    @State private var useBundleExec = true
    @State private var boolValues: [String: Bool] = [:]
    @State private var stringValues: [String: String] = [:]
    @State private var isRunning = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Toggle("bundle exec", isOn: $useBundleExec)
                ForEach(lane.inputs) { input in
                    switch input.type {
                    case .bool:
                        Toggle(input.name, isOn: binding(for: input.name))
                    case .string:
                        HStack(spacing: 10) {
                            Text(input.name)
                            TextField(
                                input.name,
                                text: stringBinding(for: input.name),
                                prompt: Text("\(input.type.rawValue) value")
                            )
                            .textFieldStyle(.roundedBorder)
                        }
                    }
                }
                HStack(spacing: 10) {
                    Button {
                        Task {
                            await runCommand()
                        }
                    } label: {
                        Text("Run in Terminal")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isRunning)
                    if isRunning {
                        ProgressView()
                            .controlSize(.mini)
                    }
                }
                Divider()
                Text(laneCommand)
                    .font(.system(.body, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Spacer()
            }
        }
        .padding()
        .navigationTitle(lane.name)
        .task(id: lane) {
            boolValues = Dictionary(uniqueKeysWithValues: lane.inputs.filter({ $0.type == .bool }).map({ ($0.name, false) }))
            stringValues = Dictionary(uniqueKeysWithValues: lane.inputs.filter({ $0.type == .string }).map({ ($0.name, "") }))
            useBundleExec = true
        }
    }
    
    private var terminalCommand: String {
        "cd \(shellQuoted(commandDirectory.path)) && \(laneCommand)"
    }
    
    private var laneCommand: String {
        var parts: [String] = []
        if useBundleExec {
            parts.append("bundle exec")
        }
        parts.append("fastlane")
        parts.append(lane.name)
        for input in lane.inputs {
            switch input.type {
            case .bool:
                parts.append("\(input.name):\((boolValues[input.name] ?? false) ? "true" : "false")")
            case .string:
                let value = stringValues[input.name]?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                if value.isEmpty == false {
                    parts.append("\(input.name):\(shellQuoted(value))")
                }
            }
        }
        return parts.joined(separator: " ")
    }
    
    private func shellQuoted(_ value: String) -> String {
        "'\(value.replacingOccurrences(of: "'", with: "'\\''"))'"
    }
    
    private func binding(for key: String) -> Binding<Bool> {
        .init(get: {
            boolValues[key] ?? false
        }, set: {
            boolValues[key] = $0
        })
    }
    
    private func stringBinding(for key: String) -> Binding<String> {
        .init(get: {
            stringValues[key] ?? ""
        }, set: {
            stringValues[key] = $0
        })
    }
    
    private func runCommand() async {
        isRunning = true
        defer {
            isRunning = false
        }
        do {
            try await fastlaneService.runInTerminal(terminalCommand)
        } catch {
            alertHandler.handle(title: "Fastlane run error", message: nil, error: error)
            appLogger.error(error)
        }
    }
}

#Preview {
    FastlaneLaneView(lane: .init(name: "ios crowdin_upload", inputs: [
        .init(name: "verbose", type: .bool),
        .init(name: "slack", type: .bool),
        .init(name: "comment", type: .string)
    ]), commandDirectory: URL(fileURLWithPath: "/Users/demo/project"))
    .frame(width: 520, height: 360)
    .withAppMocks()
}
