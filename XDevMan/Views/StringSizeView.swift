//
//  StringSizeView.swift
//  XDevMan
//
//  Created by Mikhail Demidov on 14.10.2024.
//

import SwiftUI

struct StringSizeView: View {
    
    let sizeProvider: () async throws -> String
    @Binding var size: String?
    @Environment(\.alertHandler) private var alertHandler
    
    var body: some View {
        if let size {
            Text(size)
        } else {
            ProgressView()
                .controlSize(.small)
                .task {
                    do {
                        size = try await sizeProvider()
                    } catch {
                        alertHandler.handle(title: "Error", message: nil, error: error)
                    }
                }
        }
    }
}

#Preview {
    StringSizeView(sizeProvider: { "" }, size: .constant(nil))
}
