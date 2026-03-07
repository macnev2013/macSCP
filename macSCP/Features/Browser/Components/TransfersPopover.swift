//
//  TransfersPopover.swift
//  macSCP
//
//  Safari-style popover showing file transfer progress
//

import SwiftUI

struct TransfersPopover: View {
    @Bindable var viewModel: FileBrowserViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Header
            header

            Divider()

            // Content
            if viewModel.allTransfers.isEmpty {
                emptyState
            } else {
                transfersList
            }
        }
        .frame(width: 320, height: min(CGFloat(viewModel.allTransfers.count * 72 + 52), 400))
        .background(.ultraThickMaterial)
    }

    private var header: some View {
        HStack {
            Text("Transfers")
                .font(.system(size: 13, weight: .semibold))

            Spacer()

            // Cancel all button (shown when there are active transfers)
            if viewModel.hasActiveTransfers {
                Button("Cancel All") {
                    viewModel.cancelAllTransfers()
                }
                .buttonStyle(.plain)
                .font(.system(size: 12))
                .foregroundStyle(.red)
            }

            // Clear completed button
            if !viewModel.recentTransfers.isEmpty {
                Button("Clear") {
                    viewModel.clearCompletedTransfers()
                }
                .buttonStyle(.plain)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "arrow.up.arrow.down.circle")
                .font(.system(size: 32, weight: .light))
                .foregroundStyle(.tertiary)

            Text("No transfers")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 32)
    }

    private var transfersList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.allTransfers) { transfer in
                    TransferItemView(
                        transfer: transfer,
                        onCancel: {
                            viewModel.cancelTransfer(transfer)
                        },
                        onRemove: {
                            viewModel.removeTransfer(transfer)
                        }
                    )

                    if transfer.id != viewModel.allTransfers.last?.id {
                        Divider()
                            .padding(.leading, 48)
                    }
                }
            }
        }
    }
}

// MARK: - Transfer Item View
struct TransferItemView: View {
    let transfer: TransferProgress
    let onCancel: () -> Void
    let onRemove: () -> Void

    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 12) {
            // Status icon
            statusIcon
                .frame(width: 28, height: 28)

            // File info and progress
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(transfer.fileName)
                        .font(.system(size: 12, weight: .medium))
                        .lineLimit(1)
                        .truncationMode(.middle)

                    Spacer()

                    if transfer.isComplete {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(.green)
                    } else if transfer.status == .failed {
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(.red)
                    } else if transfer.status == .cancelled {
                        Image(systemName: "slash.circle.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(.orange)
                    }
                }

                if transfer.isInProgress {
                    // Progress bar
                    ProgressView(value: transfer.fractionCompleted)
                        .progressViewStyle(.linear)
                        .tint(.accentColor)

                    // Progress text
                    HStack {
                        Text(transfer.progressText)
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)

                        Spacer()

                        Text("\(transfer.percentCompleted)%")
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }
                } else if transfer.isComplete {
                    Text(transfer.totalSizeText)
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                } else if transfer.status == .failed {
                    Text(transfer.error ?? (transfer.transferType == .download ? "Download failed" : "Upload failed"))
                        .font(.system(size: 10))
                        .foregroundStyle(.red)
                        .lineLimit(1)
                } else if transfer.status == .cancelled {
                    Text("Cancelled")
                        .font(.system(size: 10))
                        .foregroundStyle(.orange)
                }
            }

            // Cancel button for active transfers
            if transfer.isInProgress {
                Button(action: onCancel) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help(transfer.transferType == .download ? "Cancel download" : "Cancel upload")
            }

            // Remove button (shown on hover for completed/failed/cancelled)
            if !transfer.isInProgress && isHovering {
                Button(action: onRemove) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(isHovering ? Color.primary.opacity(0.04) : .clear)
        .onHover { hovering in
            isHovering = hovering
        }
    }

    @ViewBuilder
    private var statusIcon: some View {
        ZStack {
            Circle()
                .fill(statusBackgroundColor)

            if transfer.isInProgress {
                // Animated transfer icon
                Image(systemName: transfer.transferType == .download ? "arrow.down" : "arrow.up")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white)
            } else if transfer.isComplete {
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white)
            } else if transfer.status == .failed {
                Image(systemName: "exclamationmark")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white)
            } else if transfer.status == .cancelled {
                Image(systemName: "stop.fill")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.white)
            } else {
                Image(systemName: "clock")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white)
            }
        }
    }

    private var statusBackgroundColor: Color {
        switch transfer.status {
        case .inProgress:
            return .blue
        case .completed:
            return .green
        case .failed:
            return .red
        case .pending:
            return .orange
        case .cancelled:
            return .gray
        }
    }
}

// MARK: - Toolbar Transfers Button
struct TransfersToolbarButton: View {
    @Bindable var viewModel: FileBrowserViewModel

    @State private var isHovering = false

    var body: some View {
        Button {
            viewModel.isShowingTransfersPopover.toggle()
        } label: {
            ZStack(alignment: .topTrailing) {
                Image(systemName: viewModel.hasActiveTransfers ? "arrow.up.circle.fill" : "arrow.up.arrow.down.circle")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(viewModel.hasActiveTransfers ? .blue : .primary)
                    .frame(width: 28, height: 28)
                    .background {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(isHovering ? Color.primary.opacity(0.06) : .clear)
                    }
                    .symbolEffect(.pulse, options: .repeating, isActive: viewModel.hasActiveTransfers)

                // Badge for active transfer count
                if viewModel.activeTransferCount > 0 {
                    Text("\(viewModel.activeTransferCount)")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Capsule().fill(.blue))
                        .offset(x: 4, y: -4)
                }
            }
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovering = hovering
        }
        .popover(isPresented: $viewModel.isShowingTransfersPopover, arrowEdge: .bottom) {
            TransfersPopover(viewModel: viewModel)
        }
        .help("Transfers")
    }
}

// MARK: - Preview
#Preview {
    TransfersPopover(
        viewModel: DependencyContainer.shared.makeFileBrowserViewModel(
            connection: Connection(name: "Test", host: "localhost", username: "user"),
            sftpSession: SFTPSession(),
            password: "test"
        )
    )
}
