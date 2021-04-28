//
//  SFTPView.swift
//  macSCP
//
//  Created by Nevil Macwan on 26/04/21.
//

import SwiftUI
import NMSSH

struct SFTPView: View {
    var connection: Connections
    let error: NSErrorPointer = nil
    
    var body: some View {
        HStack {
            let session = createSession(address: connection.address ?? "", username: connection.username ?? "", password: connection.password ?? "", keypath: connection.keypath ?? "", iskey: connection.iskey)
            SFTPFileListView(session: session)
        }
    }
}

struct SFTPView_Previews: PreviewProvider {
    static var previews: some View {
        SFTPView(connection: Connections())
    }
}
