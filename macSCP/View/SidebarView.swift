//
//  SidebarView.swift
//  macSCP
//
//  Created by Nevil Macwan on 25/04/21.
//

import SwiftUI
import Combine

#if os(macOS)
private func toggleSidebar() {
    NSApp.keyWindow?.firstResponder?
        .tryToPerform(#selector(NSSplitViewController.toggleSidebar(_:)), with: nil)
}
#endif

struct SidebarView: View {
    @State private var isDefaultItemActive = true

    var body: some View {
        
        let list = List {
            Text("Folders")
                .font(.caption)
                .foregroundColor(.secondary)
            NavigationLink(destination: ConnectionView(), isActive: $isDefaultItemActive) {
                Label("All", systemImage: "tray.2")
            }
            
        }
        .listStyle(SidebarListStyle())
        .frame(idealWidth: .infinity)
        
        #if false
        Button(action: {
            print("Add a new folder")
        }, label: {
            Image(systemName: "plus")
            Text("New Folder")
        })
        .buttonStyle(PlainButtonStyle())
        .frame(minWidth: 30, idealWidth: 30, maxWidth: .infinity, alignment: .leading)
        .padding()
        #endif
        
        #if os(macOS)
        list.toolbar {
            Button(action: toggleSidebar) {
                Image(systemName: "sidebar.left")
            }
        }
        #else
        list
        #endif
    }
}

struct SidebarView_Previews: PreviewProvider {
    static var previews: some View {
        SidebarView()
    }
}
