//
//  CreateNewDirectoryView.swift
//  macSCP
//
//  Created by Nevil Macwan on 27/04/21.
//

import SwiftUI
import NMSSH

struct CreateNewDirectoryView: View {
    @Environment(\.presentationMode) var presentationMode

    var session: NMSSHSession
    var directory: String

    @State private var directoryName = ""

    var body: some View {
        VStack {
            Text("Add a new folder")
                .font(.title)
            Text("Creating a folder inside: \(directory)")
            Spacer()
            HStack {
                Text("Folder Name:")
                    .connectionViewText()
                TextField("directory", text: $directoryName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            Spacer()
            HStack {
                Button("Save") {
                    directoryName = directory + directoryName
                    print("Making directroy: \(directoryName)")
                    makeDirectoy(session: session, atPath: directoryName)
                    presentationMode.wrappedValue.dismiss()
                }
                .keyboardShortcut(.defaultAction)
                Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
                .keyboardShortcut(.cancelAction)
            }
        }
        .padding()
        .frame(minWidth: 400, idealWidth: 400, maxWidth: /*@START_MENU_TOKEN@*/.infinity/*@END_MENU_TOKEN@*/, minHeight: 200, idealHeight: 200, maxHeight: /*@START_MENU_TOKEN@*/.infinity/*@END_MENU_TOKEN@*/, alignment: .trailing)
    }
}

struct CreateNewDirectoryView_Previews: PreviewProvider {
    static var previews: some View {
        CreateNewDirectoryView(session: NMSSHSession(host: "", andUsername: ""), directory: "")
    }
}
