//
//  OpenLinkView.swift
//  XDevMan
//
//  Created by Mikhail Demidov on 05.10.2024.
//

import SwiftUI

struct OpenLinkView: View {
    
    let urlProvider: @Sendable () async throws -> URL?
    @Environment(\.appLogger) private var appLogger
    
    var body: some View {
        Button {
            Task { [appLogger] in
                do {
                    if let url = try await urlProvider() {
                        NSWorkspace.shared.open(url)
                    }
                } catch {
                    appLogger.error(error)
                }
            }
        } label: {
            Image(systemName: "link.circle")
                .resizable()
                .frame(width: 20, height: 20)
                .foregroundStyle(.indigo)
            
        }
        .buttonStyle(BorderlessButtonStyle())
    }
}

#Preview {
    OpenLinkView(urlProvider: { nil })
        .padding()
        .withAppMocks()
}
