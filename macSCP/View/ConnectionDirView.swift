//
//  ConnectionDirView.swift
//  macSCP
//
//  Created by Nevil Macwan on 27/04/21.
//

import SwiftUI
import NMSSH

struct ConnectionDirView: View {
    var directory: NMSFTPFile
    
    func getPrefixIcon(directory: NMSFTPFile) -> String {
        var prefixIcon: String
        
        switch directory.filename {
        case _ where directory.filename.contains(".zip"):
            prefixIcon = "doc.zipper"
        case _ where directory.filename.contains(".doc"):
            prefixIcon = "doc.fill"
        case _ where directory.filename.contains(".rar"):
            prefixIcon = "doc.zipper"
        case _ where directory.filename.contains(".txt"):
            prefixIcon = "doc.text.fill"
        case _ where directory.filename.contains(".png") || directory.filename.contains(".jpg") || directory.filename.contains(".jpeg") || directory.filename.contains(".ico"):
            prefixIcon = "photo.fill"
        default:
            prefixIcon = directory.isDirectory ? "folder.fill" : "doc.fill"
        }
        return prefixIcon
    }
    
    var body: some View {
        HStack {
            Image(systemName: getPrefixIcon(directory: directory))
            Text(directory.filename)
                .font(.headline)
                .frame(minWidth: 0, idealWidth: 100, maxWidth: .infinity, alignment: .leading)
                .lineLimit(1)
            Image(systemName: "chevron.right")
        }
        .contentShape(Rectangle())
    }
}

struct ConnectionDirView_Previews: PreviewProvider {
    static var previews: some View {
        ConnectionDirView(directory: NMSFTPFile(filename: "filen"))
    }
}
