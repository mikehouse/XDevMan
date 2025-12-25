
import SwiftUI

struct XCodeImporter: View {
    
    let onResult: (Bool) -> Void
    @State private var showXcodeSelection = false
    @State private var xcodeVersion: String = "Xcode ??"
    @Environment(\.alertHandler) private var alertHandler
    @Environment(\.appLogger) private var appLogger
    
    var body: some View {
        Group {
            Button {
                showXcodeSelection = true
            } label: {
                VStack {
                    Image(systemName: "gearshape")
                        .foregroundStyle(.cyan)
                    Text(xcodeVersion)
                        .foregroundStyle(.cyan)
                }
                
            }
           .buttonStyle(.toolbarDefault)
        }
        .xCodeImporter(isPresented: $showXcodeSelection) { (result: Result<Void, Error>) in
            switch result {
            case .success:
                updateXcodeVersion()
                onResult(true)
            case .failure(let failure):
                alertHandler.handle(title: "Select error", message: nil, error: failure)
                appLogger.error(failure)
                onResult(false)
            }
        }
        .task {
            updateXcodeVersion()
        }
    }
    
    private func updateXcodeVersion(abortIfNotDefault: Bool = false) {
        Task {
            do {
                xcodeVersion = try await CliTool.xcodeVersion()
            } catch {
                appLogger.error(error)
            }
        }
    }
}

extension View {
    
    fileprivate func xCodeImporter(
        isPresented: Binding<Bool>,
        on onResult: @escaping (Result<Void, Error>) -> Void) -> some View {
        fileImporter(
            isPresented: isPresented,
            allowedContentTypes: [.package],
            allowsMultipleSelection: false) { (result: Result<[URL], any Error>) in
                switch result {
                case .success(let success):
                    guard let app = success.first else {
                        return
                    }
                    let tool = app.appendingPathComponent("Contents/Developer/usr/bin/simctl", isDirectory: false)
                    Task {
                        do {
                            try await CliTool.SimCtl.setExecutable(tool)
                            onResult(.success(Void()))
                        } catch {
                            onResult(.failure(error))
                        }
                    }
                case .failure(let failure):
                    onResult(.failure(failure))
                }
            }
    }
}
