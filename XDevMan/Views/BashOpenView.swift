//
//  BashOpenView.swift
//  XDevMan
//
//  Created by Mikhail Demidov on 30.09.2024.
//

import SwiftUI

struct BashOpenView: View {
    
    enum ViewType {
        case button(title: String = "Open", icon: Image? = nil, bordered: Bool = true)
        case folder
        case toolbarFolder
    }
    
    enum OpenType {
        case url(URL, args: [String] = [])
        case app(CliTool.Bash.App, args: [String] = [])
        case custom(() async throws -> Void)
    }
    
    let path: OpenType
    let type: ViewType
    
    @Environment(\.bashService) private var bashService
    @Environment(\.alertHandler) private var alertHandler
    @Environment(\.appLogger) private var appLogger
    
    var body: some View {
        Button {
            Task {
                do {
                    switch path {
                    case .url(let url, let args):
                        try await bashService.open(url, args: args)
                    case .app(let app, let args):
                        try await bashService.open(app, args: args)
                    case .custom(let opener):
                        try await opener()
                    }
                } catch {
                    switch path {
                    case .url(let url, _):
                        self.alertHandler.handle(title: "Open error (\(url.path)", message: nil, error: error)
                    case .app(let app, _):
                        self.alertHandler.handle(title: "Open error (\(app.name)", message: nil, error: error)
                    case .custom:
                        self.alertHandler.handle(title: "Open error", message: nil, error: error)
                    }
                    appLogger.error(error)
                }
            }
        } label: {
            switch type {
            case .button(let title, let icon, _):
                VStack {
                    if let icon {
                        icon
                    }
                    if !title.isEmpty {
                        Text(title)
                            .padding(.top, 1)
                    }
                }
            case .folder:
                Image(systemName: "folder.fill")
                    .resizable()
                    .frame(width: 19, height: 16)
                    .foregroundStyle(.cyan)
            case .toolbarFolder:
                Image(systemName: "folder")
                    .resizable()
                    .frame(width: 20, height: 18)
            }
        }
        .modifier(ButtonStyler(type: type))
    }
}

private struct ButtonStyler: ViewModifier {
     
     let type: BashOpenView.ViewType
    
     func body(content: Content) -> some View {
        switch type {
        case .button(_, _, let bordered) where bordered:
            content
                .buttonStyle(BorderedButtonStyle())
        default:
            content
                .buttonStyle(BorderlessButtonStyle())
        }
    }
}

private extension BashOpenView {
    
    @ViewBuilder
    func setButtonStyle() -> some View {
        switch type {
        case .button:
            self.buttonStyle(BorderedButtonStyle())
        case .folder, .toolbarFolder:
            self.buttonStyle(BorderlessButtonStyle())
        }
    }
}

#Preview {
    VStack {
        BashOpenView(
            path: .url(URL(fileURLWithPath: "/")),
            type: .folder
        )
        BashOpenView(
            path: .url(URL(fileURLWithPath: "/")),
            type: .folder
        )
    }
    .padding()
    .withAppMocks()
    .frame(width: 200, height: 200)
}
