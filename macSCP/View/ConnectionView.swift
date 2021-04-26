//
//  ConnectionView.swift
//  macSCP
//
//  Created by Nevil Macwan on 25/04/21.
//

import SwiftUI
import AppKit
import Combine

struct ConnectionView: View {
    @State private var showingSheet = false
    
    @Environment(\.managedObjectContext) var managedObjectContext
    
    @FetchRequest(entity: Connections.entity(), sortDescriptors: [NSSortDescriptor(key: "label", ascending: true)]) var connections: FetchedResults<Connections>
    
    private func delete(at offsets: IndexSet) {
        for index in offsets {
            let connection = connections[index]
            PersistanceController.shared.delete(connection)
        }
    }
    
    var body: some View {
        List {
            ForEach(self.connections, id: \.self) { (connection: Connections) in
                NavigationLink(destination: ConnectionDetailView(connection: connection)) {
                    ConnectionRow(connection: connection)
                }
                .contextMenu(ContextMenu(menuItems: {
                    Button(action: {
                        PersistanceController.shared.delete(connection)
                    }, label: {
                        Text("Delete")
                        Image(systemName: "trash")
                    })
                    .buttonStyle(PlainButtonStyle())
                }))
            }
            .onDelete(perform: self.delete)
        }
        .frame(minWidth: 250, idealWidth: 250, maxWidth: /*@START_MENU_TOKEN@*/.infinity/*@END_MENU_TOKEN@*/, minHeight: /*@START_MENU_TOKEN@*/0/*@END_MENU_TOKEN@*/, idealHeight: /*@START_MENU_TOKEN@*/100/*@END_MENU_TOKEN@*/, maxHeight: /*@START_MENU_TOKEN@*/.infinity/*@END_MENU_TOKEN@*/, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
        .navigationTitle("Connections")
        .toolbar {
            ToolbarItem {
                Button(action: {
                    showingSheet.toggle()
                }) {
                    Image(systemName: "plus.circle")
                }
                .sheet(isPresented: $showingSheet) {
                    ConnectionAddView()
                }
                .keyboardShortcut("n", modifiers: [.command, .shift])
            }
        }
    }
}

struct ConnectionView_Previews: PreviewProvider {
    static var previews: some View {
        ConnectionView()
    }
}
