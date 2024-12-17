//
//  SimulatorDyldCacheListItemView.swift
//  XDevMan
//
//  Created by Mikhail Demidov on 16.12.2024.
//

import SwiftUI

struct SimulatorDyldCacheListItemView: View {
	
	let item: Item
	@Binding var deleted: Item?
    @Environment(\.alertHandler) private var alertHandler
    @Environment(\.bashService) private var bashService
    @Environment(\.appLogger) private var appLogger
    @State private var size: String?
    @State private var isDeleting = false
    
    var body: some View {
        HStack(spacing: 10) {
			Text("\(item.dyldRuntimeId) (\(item.dyldRuntimeBuild))")
                .textSelection(.enabled)
            Spacer()
            StringSizeView(sizeProvider: {
                try await bashService.size(item.dyldURL)
            }, size: $size)
            if isDeleting {
                ProgressView()
                    .controlSize(.small)
            } else {
                Button {
                    Task {
                        do {
                            isDeleting = true
                            try await bashService.rmDir(item.dyldURL)
                            deleted = item
                        } catch {
                            alertHandler.handle(title: "Delete error for \(item.dyldRuntimeId)", message: nil, error: error)
                            isDeleting = false
                            appLogger.error(error)
                        }
                    }
                } label: {
                    DeleteIconView()
                }
                .buttonStyle(BorderlessButtonStyle())
            }
            BashOpenView(path: .url(item.dyldURL), type: .folder)
        }
        .task(id: item) {
        }
    }
}

extension SimulatorDyldCacheListItemView {
	
	struct Item: Identifiable, HashableIdentifiable {
		
		var id: URL { dyldURL }
		let dyldURL: URL
		let dyldRuntimeId: String
		let dyldRuntimeBuild: String
	}
}