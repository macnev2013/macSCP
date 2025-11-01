//
//  IconPickerView.swift
//  macSCP
//
//  Created by Nevil Macwan on 01/11/25.
//

import SwiftUI

struct IconPickerView: View {
    @Binding var selectedIcon: String
    @Environment(\.dismiss) private var dismiss

    let icons = [
        "server.rack", "desktopcomputer", "laptopcomputer", "pc",
        "network", "wifi", "antenna.radiowaves.left.and.right",
        "cloud", "cloud.fill", "icloud", "icloud.fill",
        "externaldrive", "internaldrive", "externaldrive.fill",
        "cylinder", "cylinder.fill", "cube", "cube.fill",
        "shippingbox", "shippingbox.fill", "building", "building.2",
        "lock.shield", "lock.shield.fill", "key.fill"
    ]

    let columns = [
        GridItem(.adaptive(minimum: 60), spacing: 12)
    ]

    var body: some View {
        VStack(spacing: 20) {
            Text("Choose an Icon")
                .font(.title2)
                .fontWeight(.semibold)

            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(icons, id: \.self) { icon in
                        Button(action: {
                            selectedIcon = icon
                            dismiss()
                        }) {
                            VStack {
                                Image(systemName: icon)
                                    .font(.system(size: 30))
                                    .foregroundColor(selectedIcon == icon ? .white : .blue)
                                    .frame(width: 60, height: 60)
                                    .background(selectedIcon == icon ? Color.accentColor : Color(.controlBackgroundColor))
                                    .cornerRadius(8)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }

            Button("Cancel") {
                dismiss()
            }
        }
        .padding()
        .frame(width: 400, height: 500)
    }
}
