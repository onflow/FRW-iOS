import SwiftUI

struct NFTLoadingView: View {
    let loadedCount: Int
    let totalCount: Int

    var body: some View {
        VStack {
            Spacer()

            VStack(alignment: .center, spacing: 16) {
                Text("loading_nfts".localized)
                    .font(.inter(size: 14))
                    .foregroundStyle(Color.Theme.Text.black6)

                ProgressView(value: Double(loadedCount), total: Double(totalCount))
                    .progressViewStyle(LinearProgressViewStyle(tint: .Theme.Accent.green))
                    .frame(width: 144, height: 8)
                    .scaleEffect(x: 1, y: 1.5, anchor: .center)

                Text("\(loadedCount)/\(totalCount)")
                    .font(.inter(size: 14, weight: .semibold))
                    .foregroundStyle(Color.Theme.Text.black6)
            }

            Spacer()
        }
    }
}

#Preview {
    NFTLoadingView(loadedCount: 50, totalCount: 100)
}
