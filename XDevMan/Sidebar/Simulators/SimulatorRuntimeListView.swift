
import SwiftUI

struct SimulatorRuntimeListView: View {
    
    @Binding var runtimeSelected: Runtime?
    @Binding var reloadSimulators: UUID?
    let previewsMode: Bool
    @State private var runtimes: [Runtime]?
    @State private var runtimesIsBeta: [Runtime.ID: Bool] = [:]
    @State private var runtimesInternal: [RuntimeInternal] = []
    @State private var navigationTitle: String = "Simulator runtimes"
    @State private var isAlertPresented = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var alertOkAction: (() -> Void)?
    @State private var alertDesruptionAction: (() -> Void)?
    @State private var alertCancelAction: (() -> Void)?
    @State private var toolbarButtonDisabled = false
    @State private var showAddSimulatorWindow = false
    @Environment(\.runtimesService) private var runtimesService
    @Environment(\.alertHandler) private var alertHandler
    @Environment(\.appLogger) private var appLogger
    
    var body: some View {
        Group {
            if let runtimes {
                if runtimes.isEmpty {
                    Text("Runtimes not found.")
                        .foregroundColor(.gray)
                } else {
                    List(runtimes, id: \.self, selection: $runtimeSelected) { runtime in
                        SimulatorRuntimeListItemView(
                            runtime: runtime,
                            isBeta: runtimesIsBeta[runtime.id] == true,
                            size: self.runtimesInternal.first(where: {
                                $0.runtimeIdentifier == runtime.identifier
                                && $0.build == runtime.buildversion
                            })?.sizeBytes
                        )
                        .modifier(ListItemViewPaddingModifier())
                    }
                    .navigationTitle(navigationTitle)
                    .onChange(of: runtimeSelected) {
                        if let runtime = runtimeSelected {
                            navigationTitle = "\(runtime.name)\(runtimesIsBeta[runtime.id] == true ? " beta" : "")"
                            runtimeSelected = runtime
                        } else {
                            runtimeSelected = nil
                            navigationTitle = "Simulator runtimes"
                        }
                    }
                    .toolbar {
                        if let runtime = runtimeSelected {
                            ToolbarItem(id: "simulators-create-sim") {
                                Button {
                                    showAddSimulatorWindow = true
                                } label: {
                                    VStack {
                                        Image(systemName: "plus.circle")
                                        Text("Create sim")
                                    }
                                }
                                .buttonStyle(.toolbarDefault)
                                .disabled(toolbarButtonDisabled)
                            }
                            ToolbarItem(id: "simulators-runtime-open") {
                                BashOpenView(
                                    path: .url(URL(filePath: runtime.runtimeRoot)),
                                    type: .button(title: "Runtime dir", icon: Image(systemName: "folder"), bordered: false, toolbar: true)
                                )
                                .disabled(toolbarButtonDisabled)
                            }
                            ToolbarItem(id: "simulators-runtime-delete") {
                                Button {
                                    self.alertTitle = "Delete \(runtime.name) (\(runtime.id)) runtime ?"
                                    self.alertMessage = "Not recoverable action. To install it back please see Apple documentation (click \"Add runtime\" button to see more)."
                                    self.alertCancelAction = {}
                                    self.alertDesruptionAction = {
                                        Task {
                                            do {
                                                toolbarButtonDisabled = true
                                                try await runtimesService.delete(runtime)
                                                await updateRuntimes(deleting: true)
                                                toolbarButtonDisabled = false
                                            } catch {
                                                toolbarButtonDisabled = false
                                                alertHandler.handle(title: "Runtime \(runtime.name) delete error.", message: nil, error: error)
                                                appLogger.error(error)
                                            }
                                        }
                                    }
                                    self.alertOkAction = nil
                                    self.isAlertPresented = true
                                } label: {
                                    VStack {
                                        Image(systemName: "trash")
                                        Text("Delete runtime")
                                    }
                                }
                                .buttonStyle(.toolbarDefault)
                                .disabled(toolbarButtonDisabled)
                            }
                        }
                        ToolbarItem(id: "simulators-add-runtime") {
                            Button {
                                if let url = URL(string: "https://developer.apple.com/documentation/safari-developer-tools/adding-additional-simulators") {
                                    NSWorkspace.shared.open(url)
                                }
                            } label: {
                                VStack {
                                    Image(systemName: "plus.app")
                                    Text("Add runtime")
                                }
                                
                            }
                            .buttonStyle(.toolbarDefault)
                            .disabled(toolbarButtonDisabled)
                        }
                        ToolbarItem(id: "simulators-xcode-import") {
                            XCodeImporter {
                                if $0 {
                                    Task { await updateRuntimes(deleting: false) }
                                }
                            }
                        }
                    }
                    .sheet(isPresented: $showAddSimulatorWindow, content: {
                        if let runtime = runtimeSelected {
                            RuntimeCreateNewSimulatorView(
                                runtime: runtime) { device, name in
                                    showAddSimulatorWindow = false
                                    Task {
                                        do {
                                            try await self.runtimesService.create(device, runtime: runtime, name: name)
                                            reloadSimulators = UUID()
                                        } catch {
                                            alertHandler.handle(
                                                title: "Add simulator \"\(name)\" for runtime \(runtime.name)", message: nil, error: error)
                                            appLogger.error(error)
                                        }
                                    }
                                } onCancel: {
                                    showAddSimulatorWindow = false
                                }
                        }
                    })
                    .alert(Text(alertTitle), isPresented: $isAlertPresented, actions: {
                        if let alertDesruptionAction {
                            Button("Yes", role: .destructive, action: alertDesruptionAction)
                        }
                        if let alertOkAction {
                            Button("Ok", role: .cancel, action: alertOkAction)
                        }
                        if let alertCancelAction {
                            Button("Cancel", role: .cancel, action: alertCancelAction)
                        }
                    }, message: {
                        Text(alertMessage)
                    })
                }
            } else {
                ProgressView()
                    .navigationTitle(navigationTitle)
            }
        }
        .task {
            CliTool.SimCtl.setPreviewsMode(previewsMode)
            await updateRuntimes(deleting: false)
        }
        .onDisappear {
            runtimeSelected = nil
            reloadSimulators = nil
        }
    }
    
    private func updateRuntimes(deleting: Bool) async {
        do {
            if deleting, let deletingRuntime = runtimeSelected {
                do {
                    var count = 0
                    while count < 5 {
                        let runtimes = try await runtimesService.runtimes().runtimes
                        if !runtimes.contains(where: { $0.id == deletingRuntime.id }) {
                            break
                        }
                        count += 1
                        try await Task.sleep(nanoseconds: 1_000_000_000)
                    }
                } catch {
                    appLogger.error(error)
                }
            }
            self.runtimes = nil
            self.runtimeSelected = nil
            let runtimesInternal = await ((try? runtimesService.list()) ?? [])
            let runtimes = try await runtimesService.runtimes().runtimes
            self.runtimesInternal = runtimesInternal
            await withTaskGroup(of: (String, Bool).self) { group in
                for runtime in runtimes {
                    group.addTask {
                        await (runtime.id, (try? runtimesService.isBeta(runtime)) ?? false)
                    }
                }
                for await (id, isBeta) in group {
                    self.runtimesIsBeta[id] = isBeta
                }
            }
            self.runtimes = runtimes
            self.navigationTitle = "Simulator runtimes"
        } catch {
            alertHandler.handle(title: "Update runtimes list error", message: nil, error: error)
            appLogger.error(error)
        }
    }
}

#Preview {
    SimulatorRuntimeListView(
        runtimeSelected: .constant(nil),
        reloadSimulators: .constant(nil),
        previewsMode: false
    )
    .frame(width: 500, height: 300)
    .withRuntimesService(RuntimesProviderMockObject.self)
    .withAppMocks()
}

private class RuntimesProviderMockObject: RuntimesProviderMock {
    
    override class func list() async throws -> [RuntimeInternal] {
        [.init(
            build: "21C62",
            deletable: true,
            identifier: "46AFC7AD-45BB-4F6B-99B0-7E49BC4AD6E7",
            kind:  "Disk Image",
            lastUsedAt: "2024-07-03T06:23:09Z",
            mountPath: "/Library/Developer/CoreSimulator/Volumes/iOS_21C62",
            path: "/Library/Developer/CoreSimulator/Images/46AFC7AD-45BB-4F6B-99B0-7E49BC4AD6E7.dmg",
            platformIdentifier: "com.apple.platform.iphonesimulator",
            runtimeBundlePath: "/Library/Developer/CoreSimulator/Volumes/iOS_21C62/Library/Developer/CoreSimulator/Profiles/Runtimes/iOS 17.2.simruntime",
            runtimeIdentifier: "com.apple.CoreSimulator.SimRuntime.iOS-17-2",
            signatureState: "Verified",
            sizeBytes: 7351124481,
            state: "Ready",
            version: "17.2"
        )
        ]
    }
    
    override class func runtimes() async throws -> CliTool.SimCtl.List.Runtimes {
        return .init(
            runtimes: [
                .init(
                    bundlePath: "", buildversion: "20E247", platform: "", runtimeRoot: "",
                    identifier: "com.apple.CoreSimulator.SimRuntime.iOS-16-4", version: "", isInternal: false, isAvailable: true,
                    name: "iOS 16", supportedDeviceTypes: [
                    ]
                ),
                .init(
                    bundlePath: "", buildversion: "21C62", platform: "", runtimeRoot: "",
                    identifier: "com.apple.CoreSimulator.SimRuntime.iOS-17-2", version: "", isInternal: false, isAvailable: false,
                    name: "iOS 17", supportedDeviceTypes: [
                    ]
                ),
                .init(
                    bundlePath: "", buildversion: "21F79", platform: "", runtimeRoot: "",
                    identifier: "com.apple.CoreSimulator.SimRuntime.iOS-14-5", version: "", isInternal: false, isAvailable: true,
                    name: "iOS 14", supportedDeviceTypes: [
                    ]
                )
            ]
        )
    }
}
