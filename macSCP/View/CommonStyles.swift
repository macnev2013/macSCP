//
//  CommonStyles.swift
//  macSCP
//
//  Created by Nevil Macwan on 25/04/21.
//

import SwiftUI

import SwiftUI

extension Text {
    func connectionViewText() -> some View {
        self.font(.body)
            .frame(minWidth: 15, idealWidth: 15, maxWidth: 100, alignment: .leading)
    }
}

extension TextField {
    func connectionViewTextField() -> some View {
        self.textFieldStyle(PlainTextFieldStyle())
    }
}

extension SecureField {
    func connectionViewSecureField() -> some View {
        self.textFieldStyle(PlainTextFieldStyle())
    }
}
