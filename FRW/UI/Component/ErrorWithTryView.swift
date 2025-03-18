import SwiftUI

extension ErrorWithTryView {
    enum Message: String {
        case check = "error_check_refresh"
    }
}

struct ErrorWithTryView: View {
    let message: ErrorWithTryView.Message
    let retryAction: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            Text(message.rawValue.localized)
                .font(.inter(weight: .semibold))
                .foregroundStyle(Color.Theme.Text.black6)
                .multilineTextAlignment(.center)

            Button(action: retryAction) {
                HStack(spacing: 16) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                    Text("Refresh::message".localized)
                        .font(.inter(weight: .semibold))
                        .foregroundStyle(Color.Theme.Text.black6)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    Capsule()
                        .stroke(Color.Theme.Text.black, lineWidth: 1)
                )
            }
            .foregroundColor(.primary)

            Spacer()
        }
        .padding()
    }
}
