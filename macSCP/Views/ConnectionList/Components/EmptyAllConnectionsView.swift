//
//  EmptyAllConnectionsView.swift
//  macSCP
//
//  Created by Nevil Macwan on 01/11/25.
//

import SwiftUI

struct EmptyAllConnectionsView: View {
    let onAddConnection: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "network.slash")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            VStack(spacing: 8) {
                Text("No Connections")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Create your first SSH connection to get started")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            Button(action: onAddConnection) {
                Label("Create New Connection", systemImage: "plus.circle.fill")
                    .font(.body)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
