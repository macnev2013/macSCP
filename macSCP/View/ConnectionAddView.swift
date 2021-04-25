//
//  ConnectionAddView.swift
//  macSCP
//
//  Created by Nevil Macwan on 25/04/21.
//

import SwiftUI
import Combine

struct ConnectionAddView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.managedObjectContext) var managedObjectContext

    @FetchRequest(
        entity: Connections.entity(), sortDescriptors: [NSSortDescriptor(key: "label", ascending: true)]
    ) var connections: FetchedResults<Connections>

    @State private var address = ""
    @State private var username = ""
    @State private var password = ""
    @State private var isKey = false
    @State private var keypath = ""
    @State private var label = ""
    @State private var filename = ""

    
    var body: some View {
        VStack(alignment: .center) {
            Text("Add a new connection")
                .font(.title)
            Spacer()
            VStack(alignment: .center){
                HStack {
                    Text("Name:")
                        .connectionViewText()
                    TextField("bastion-host", text: $label)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                HStack {
                    Text("Address:")
                        .connectionViewText()
                    TextField("x.x.x.x", text: $address)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                HStack {
                    Text("Username:")
                        .connectionViewText()
                    TextField("ubuntu", text: $username)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                HStack {
                    Toggle(isOn: $isKey) {
                        Text("Keybased Authentication")
                        Spacer()
                    }
                    .toggleStyle(SwitchToggleStyle())
                }
                if !isKey {
                    HStack {
                        Text("Password:")
                            .connectionViewText()
                        TextField("greatpass", text: $password)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .disabled(isKey)
                    }
                }
                if isKey {
                    HStack {
                        Text("Key Path:")
                            .connectionViewText()
                        TextField("/User/share/keys/", text: $keypath)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        Text("or")
                        Button(action: {
                            let panel = NSOpenPanel()
                            panel.allowsMultipleSelection = false
                            panel.canChooseDirectories = false
                            panel.allowedFileTypes = ["pem"]
                            if panel.runModal() == .OK {
                                self.keypath = panel.url?.path ?? "<none>"
                            }
                        }) {
                            Text("Choose")
                        }
                    }
                }
                Spacer()
                HStack {
                    
                    Button("Save") {
                        let connection = Connections(context: managedObjectContext)
                        connection.label = self.label
                        connection.address = self.address
                        connection.iskey = self.isKey
                        connection.keypath = self.keypath
                        connection.password = self.password
                        connection.username = self.username
                        PersistanceController.shared.save()
                        presentationMode.wrappedValue.dismiss()
                    }
                    .keyboardShortcut(.defaultAction)
                    
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .keyboardShortcut(.cancelAction)
                }
            }
        }
        .padding()
        .frame(minWidth: 400, idealWidth: 400, maxWidth: /*@START_MENU_TOKEN@*/.infinity/*@END_MENU_TOKEN@*/, minHeight: 300, idealHeight: 300, maxHeight: /*@START_MENU_TOKEN@*/.infinity/*@END_MENU_TOKEN@*/, alignment: .trailing)
    }
}

struct ConnectionAddView_Previews: PreviewProvider {
    static var previews: some View {
        ConnectionAddView()
    }
}
