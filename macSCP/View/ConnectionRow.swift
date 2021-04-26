//
//  ConnectionRow.swift
//  macSCP
//
//  Created by Nevil Macwan on 25/04/21.
//

import SwiftUI
import Combine
import AppKit

struct ConnectionRow: View {
    var connection:Connections

    var body: some View {
        HStack {
            Image(systemName: "xserve")
                .font(.title)
            VStack(alignment: .leading) {
                Text(connection.label ?? "")
                    .font(.headline)
                Text(connection.address ?? "")
            }
            Spacer(minLength: 20)
            Button(action: {
                SSHConnect(address: connection.address ?? "", username: connection.username ?? "", password: connection.password ?? "", keypath: connection.keypath ?? "", isKey: connection.iskey)
            }, label: {
                Image(systemName: "play")
            })
            .buttonStyle(PlainButtonStyle())
            
        }
        .padding(5)
    }
}

struct ConnectionRow_Previews: PreviewProvider {
    static var previews: some View {
        ConnectionRow(connection: Connections())
    }
}
