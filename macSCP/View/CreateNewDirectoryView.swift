//
//  CreateNewDirectoryView.swift
//  macSCP
//
//  Created by Nevil Macwan on 27/04/21.
//

import SwiftUI
import NMSSH

struct CreateNewDirectoryView: View {
    var sftpSession: NMSFTP
    var directory: String

    @Environment(\.presentationMode) var presentationMode

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
                    makeDirectoy(session: sftpSession, atPath: directoryName)
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
