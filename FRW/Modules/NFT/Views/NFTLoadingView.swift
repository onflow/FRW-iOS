import SwiftUI

struct NFTLoadingView: View {
    let loadedCount: Int
    let totalCount: Int
    @State private var currentProgress: Double = 0

    var body: some View {
        VStack {
            Spacer()

            VStack(alignment: .center, spacing: 16) {
                Text("loading_nfts".localized)
                    .font(.inter(size: 14))
                    .foregroundStyle(Color.Theme.Text.black6)

                ProgressView(value: currentProgress, total: Double(totalCount))
                    .progressViewStyle(LinearProgressViewStyle(tint: .Theme.Accent.green))
                    .frame(width: 144, height: 8)
                    .scaleEffect(x: 1, y: 1.5, anchor: .center)
                if totalCount > 0 {
                    Text("\(loadedCount)/\(totalCount)")
                        .font(.inter(size: 14, weight: .semibold))
                        .foregroundStyle(Color.Theme.Text.black6)
                }
            }
            .onChange(of: loadedCount) { newValue in
                withAnimation(.easeInOut(duration: 0.3)) {
                    currentProgress = Double(newValue)
                }
            }
            .onAppear {
                currentProgress = Double(loadedCount)
            }

            Spacer()
        }
    }
}

struct CollectionEmptyView: View {
    var body: some View {
        VStack(alignment: .center) {
            Text("nft_no_found".localized)
                .font(.inter(size: 14, weight: .semibold))
                .foregroundStyle(Color.Theme.Text.black6)
                .multilineTextAlignment(.center)
        }
    }
}

#Preview {
    NFTLoadingView(loadedCount: 50, totalCount: 100)
}
