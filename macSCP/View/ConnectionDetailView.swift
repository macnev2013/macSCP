//
//  ConnectionDetailView.swift
//  macSCP
//
//  Created by Nevil Macwan on 25/04/21.
//

import SwiftUI
import Combine

struct ConnectionDetailView: View {
    var connection: Connections
    @State private var address = ""
    @State private var username = ""
    @State private var password = ""
    @State private var keypath = ""
    @State private var label = ""

    var body: some View {
        VStack(alignment: .leading) {
            Text(connection.label ?? "")
                .font(/*@START_MENU_TOKEN@*/.title/*@END_MENU_TOKEN@*/)
                .bold()
                .foregroundColor(.accentColor)
            VStack() {
                HStack {
                    Text("Address:")
                        .connectionViewText()
                    TextField(connection.address ?? "", text: $address)
                        .connectionViewTextField()
                }
                Divider()
                HStack {
                    Text("Username:")
                        .connectionViewText()
                    TextField(connection.username ?? "", text: $username)
                        .connectionViewTextField()
                }
                Divider()
                HStack {
                    if !(connection.password ?? "").isEmpty {
                        Text("Password:")
                            .connectionViewText()
                        SecureField(connection.keypath ?? "", text: $password)
                            .connectionViewSecureField()
                    } else {
                        Text("Key:")
                            .connectionViewText()
                        TextField(connection.keypath ?? "", text: $keypath)
                            .connectionViewTextField()
                    }
                }
                HStack {
                    Button("Save") {
                    }
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .padding()
        .toolbar  {
            Button(action: {}) {
                Image(systemName: "square.and.arrow.up")
            }
        }
        Spacer()
    }
}

struct ConnectionDetailView_Previews: PreviewProvider {
    static var previews: some View {
        ConnectionDetailView(connection: Connections())
    }
}
