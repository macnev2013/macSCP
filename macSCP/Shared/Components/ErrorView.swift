//
//  ErrorView.swift
//  macSCP
//
//  Reusable error display view
//

import SwiftUI

struct ErrorView: View {
    let error: AppError
    let retryAction: (() -> Void)?

    init(error: AppError, retryAction: (() -> Void)? = nil) {
        self.error = error
        self.retryAction = retryAction
    }

    var body: some View {
        VStack(spacing: UIConstants.spacing) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.red)

            Text("Error")
                .font(.headline)

            Text(error.localizedDescription)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            if let suggestion = error.recoverySuggestion {
                Text(suggestion)
                    .font(.callout)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
            }

            if let retryAction = retryAction {
                Button("Retry") {
                    retryAction()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(UIConstants.spacing * 2)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Compact Error View
struct CompactErrorView: View {
    let message: String
    let dismissAction: (() -> Void)?

    init(message: String, dismissAction: (() -> Void)? = nil) {
        self.message = message
        self.dismissAction = dismissAction
    }

    var body: some View {
        HStack(spacing: UIConstants.smallSpacing) {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundStyle(.red)

            Text(message)
                .font(.callout)
                .foregroundStyle(.secondary)

            Spacer()

            if let dismissAction = dismissAction {
                Button {
                    dismissAction()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(UIConstants.smallSpacing)
        .background(.red.opacity(0.1), in: RoundedRectangle(cornerRadius: UIConstants.smallCornerRadius))
    }
}

// MARK: - Error Alert Modifier
struct ErrorAlertModifier: ViewModifier {
    @Binding var error: AppError?

    func body(content: Content) -> some View {
        content
            .alert(
                "Error",
                isPresented: Binding(
                    get: { error != nil },
                    set: { if !$0 { error = nil } }
                ),
                presenting: error
            ) { _ in
                Button("OK", role: .cancel) {
                    error = nil
                }
            } message: { error in
                Text(error.localizedDescription)
            }
    }
}

extension View {
    func errorAlert(_ error: Binding<AppError?>) -> some View {
        modifier(ErrorAlertModifier(error: error))
    }
}

// MARK: - Preview
#Preview("Error View") {
    ErrorView(
        error: .connectionFailed("Connection refused"),
        retryAction: {}
    )
    .frame(width: 300, height: 300)
}

#Preview("Compact Error") {
    CompactErrorView(
        message: "Failed to load files",
        dismissAction: {}
    )
    .padding()
}
