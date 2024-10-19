//
//  SidebarMenuItemView.swift
//  XDevMan
//
//  Created by Mikhail Demidov on 05.10.2024.
//

import SwiftUI

struct SidebarMenuItemView: View {
    
    let menu: MainMenuItem
    
    var body: some View {
        HStack {
            Image(menu.icon)
                .resizable()
                .frame(width: 22, height: 22)
                .cornerRadius(4)
            Text(menu.title)
        }
        .fixedSize()
    }
}

#Preview {
    SidebarMenuItemView(menu: .git)
}
