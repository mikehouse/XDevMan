//
//  DeleteIconView.swift
//  XDevMan
//
//  Created by Mikhail Demidov on 05.10.2024.
//

import SwiftUI

struct DeleteIconView: View {
    
    var body: some View {
        Image(systemName: "trash")
            .resizable()
            .frame(width: 18, height: 18)
            .foregroundStyle(.red)
    }
}

#Preview {
    DeleteIconView()
}
