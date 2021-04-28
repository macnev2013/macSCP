//
//  ConnectionController.swift
//  macSCP
//
//  Created by Nevil Macwan on 26/04/21.
//

import Foundation
import NMSSH

//class ConnectionController {
//    var session: NMSSHSession
//    var privateKey: String
//
//    init(address:String, username:String, password:String, keypath:String) {
//        self.privateKey = try! String(contentsOfFile: keypath)
//        self.session = NMSSHSession(host: address, andUsername: username)
//        self.session.connect()
//        if self.session.isConnected == true {
//            self.session.authenticateBy(inMemoryPublicKey: "", privateKey: privateKey, andPassword: nil)
//        } else {
//            print("Error in authenticate!")
//        }
//    }
//
//    func executeCommand(command: String) -> String {
//        let error: NSErrorPointer = nil
//        return self.session.channel.execute(command, error: error)
//    }
//}

func createSession(address:String, username:String, password:String, keypath:String) -> NMSSHSession {
    let privateKey = try! String(contentsOfFile: keypath)
    let session = NMSSHSession(host: address, andUsername: username)
    session.connect()
    if session.isConnected == true {
        session.authenticateBy(inMemoryPublicKey: "", privateKey: privateKey, andPassword: nil)
        let error: NSErrorPointer = nil
        //        session.channel.execute("ls -la ~/", error: error)
        print("Connected to the server succesfully.")
    } else {
        print("Error in authenticate!")
    }
    return session
}

func executeCommand(session: NMSSHSession, command: String) -> String {
    let error: NSErrorPointer = nil
    return session.channel.execute(command, error: error)
}

func getFileList(session: NMSSHSession, dir: String) -> [NMSFTPFile] {
    if !session.isConnected {
        session.connect()
    }
    let sftp =  NMSFTP(session: session)
    sftp.connect()
    return sftp.contentsOfDirectory(atPath: dir) ?? []
}

func deleteFile(session: NMSSHSession, pathToDelete: String) {
//    if !session.isConnected {
//        session.connect()
//    }
//    let sftp =  NMSFTP(session: session)
//    sftp.connect()
//    return sftp.contentsOfDirectory(atPath: pathToDelete) ?? []
}

func downloadFile(session: NMSSHSession, pathToDownload: String, downloadDirectory: String) {
    if !session.isConnected {
        session.connect()
    }
    let sftp = NMSFTP(session: session)
    sftp.connect()
//    sftp.copyContents(ofPath: <#T##String#>, toFileAtPath: <#T##String#>, progress: <#T##((UInt, UInt) -> Bool)?##((UInt, UInt) -> Bool)?##(UInt, UInt) -> Bool#>)
}

func makeDirectoy(session: NMSSHSession, atPath: String) {
    if !session.isConnected {
        session.connect()
    }
    let sftp = NMSFTP(session: session)
    sftp.connect()
    sftp.createDirectory(atPath: atPath)
}

func deleteDirectoy(session: NMSSHSession, atPath: String) {
    if !session.isConnected {
        session.connect()
    }
    let sftp = NMSFTP(session: session)
    sftp.connect()
    sftp.removeDirectory(atPath: atPath)
}
