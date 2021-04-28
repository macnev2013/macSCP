//
//  SSHConnectionController.swift
//  macSCP
//
//  Created by Nevil Macwan on 25/04/21.
//

import Foundation
import NMSSH

func NNMSSHTest(address: String, username: String, keypath: String) {
    let privateKey = try! String(contentsOfFile: keypath)
    let error: NSErrorPointer = nil
    let session = NMSSHSession(host: address, andUsername: username)
    session.connect()

    if session.isConnected == true {
        session.authenticateBy(inMemoryPublicKey: "", privateKey: privateKey, andPassword: nil)
        let listOfDir = session.channel.execute("ls -l /var", error: error)
        print(listOfDir)
    } else {
        print("Error in connection")
    }
}

func SSHConnect(address: String, username: String, password: String, keypath: String, isKey: Bool) {
    var source = ""

    if (isKey && !keypath.isEmpty) {
        source = """
            tell application "Terminal"
                set currentTab to do script ("ssh -i \(keypath) \(username)@\(address);")
            end tell
        """
    }
    if (!isKey && !password.isEmpty){
        source = """
            tell application "Terminal"
                ßßßset currentTab to do script ("ssh \(username):\(password)@\(address);")
            end tell
        """
    }
    
    if (keypath.isEmpty && password.isEmpty) {
        return
    }
    
    if let script = NSAppleScript(source: source) {
        var error: NSDictionary?
        script.executeAndReturnError(&error)
        if let err = error {
            print(err)
        }
    }
}
