//
//  LoadingView.swift
//  macSCP
//
//  Reusable loading indicator view
//

import SwiftUI

struct LoadingView: View {
    let message: String

    init(message: String = "Loading...") {
        self.message = message
    }

    var body: some View {
        VStack(spacing: UIConstants.spacing) {
            ProgressView()
                .progressViewStyle(.circular)
                .scaleEffect(1.2)

            Text(message)
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Inline Loading
struct InlineLoadingView: View {
    let message: String

    init(message: String = "Loading...") {
        self.message = message
    }

    var body: some View {
        HStack(spacing: UIConstants.smallSpacing) {
            ProgressView()
                .progressViewStyle(.circular)
                .controlSize(.small)

            Text(message)
                .font(.callout)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Overlay Loading
struct LoadingOverlayView: View {
    let message: String

    init(message: String = "Loading...") {
        self.message = message
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: UIConstants.spacing) {
                ProgressView()
                    .progressViewStyle(.circular)
                    .scaleEffect(1.5)

                Text(message)
                    .font(.headline)
                    .foregroundStyle(.white)
            }
            .padding(UIConstants.spacing * 2)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: UIConstants.cornerRadius))
        }
    }
}

// MARK: - Preview
#Preview("Loading View") {
    LoadingView(message: "Connecting...")
        .frame(width: 300, height: 200)
}

#Preview("Inline Loading") {
    InlineLoadingView(message: "Refreshing...")
        .padding()
}

#Preview("Loading Overlay") {
    ZStack {
        Color.gray
        LoadingOverlayView(message: "Uploading file...")
    }
    .frame(width: 400, height: 300)
}
