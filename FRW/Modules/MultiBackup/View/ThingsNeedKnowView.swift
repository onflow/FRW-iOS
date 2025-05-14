//
//  ThingsNeedKnowView.swift
//  FRW
//
//  Created by cat on 2024/9/19.
//

import SwiftUI

struct ThingsNeedKnowView: RouteableView {
    @StateObject
    var viewModel = ThingsNeedKnowViewModel()

    @State
    var allCheck = false

    var title: String {
        ""
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                Text("things_you".localized)
                    .font(.inter(size: 36, weight: .heavy))
                    .foregroundColor(Color.Theme.Text.black)
                HStack {
                    Text("need_to".localized)
                        .font(.inter(size: 36, weight: .heavy))
                        .foregroundColor(Color.Theme.Text.black)

                    Text("know".localized)
                        .font(.inter(size: 36, weight: .heavy))
                        .foregroundColor(Color.Theme.Accent.green)
                }

                Text("things_need_know_des".localized)
                    .font(.inter(size: 14))
                    .foregroundColor(.Theme.Text.black8)
                    .padding(.top, 24)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 12) {
                TextCheckListView(titles: [
                    "things_need_know_check_1".localized,
                    "things_need_know_check_2".localized,
                    "things_need_know_check_3".localized,
                ], allChecked: $allCheck)
            }
            .padding(.top, 24)
            Spacer()
            VPrimaryButton(
                model: ButtonStyle.primary,
                state: allCheck ? .enabled : .disabled,
                action: {
                    onConfirm()
                },
                title: "create_backup".localized
            )
            .padding(.bottom)
        }
        .padding(.horizontal, 28)
        .background(Color.LL.background, ignoresSafeAreaEdges: .all)
        .applyRouteable(self)
        .tracedView(self)
    }

    func onConfirm() {
        viewModel.onCreate()
    }
}

#Preview {
    ThingsNeedKnowView()
}
