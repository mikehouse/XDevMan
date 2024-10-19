//
//  PasteboardCopyView.swift
//  XDevMan
//
//  Created by Mikhail Demidov on 29.09.2024.
//

import SwiftUI

struct PasteboardCopyView: View {
    
    let text: String
    
    var body: some View {
        Button {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(text, forType: .string)
        } label: {
            Image(systemName: "doc.on.doc.fill")
        }
        .buttonStyle(.borderless)
    }
}
