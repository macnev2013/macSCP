//
//  CheckForUpdatesView.swift
//  macSCP
//

#if !MAS_BUILD
import SwiftUI

struct CheckForUpdatesView: View {
    @ObservedObject var viewModel: CheckForUpdatesViewModel

    var body: some View {
        Button("Check for Updates...", action: viewModel.checkForUpdates)
            .disabled(!viewModel.canCheckForUpdates)
    }
}
#endif
