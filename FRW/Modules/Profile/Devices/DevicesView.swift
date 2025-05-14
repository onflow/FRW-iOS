//
//  DevicesView.swift
//  FRW
//
//  Created by cat on 2023/10/30.
//

import SwiftUI

// MARK: - DevicesView

struct DevicesView: RouteableView {
    // MARK: Internal

    var title: String {
        "devices".localized
    }

    var body: some View {
        ScrollView {
            Text("Scan_to_Sync_Extension_Wallet".localized)
                .font(.inter(size: 16, weight: .semibold))
                .foregroundStyle(Color.Theme.Text.black3)
            Text("Scan_sync_detal".localized)
                .font(.inter(size: 12))
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.Theme.Text.black8)
                .padding(.top, 16)
            Button {
                ScanHandler.scan()
            } label: {
                HStack(spacing: 8) {
                    Image("scan-stroke")
                        .renderingMode(.template)
                        .foregroundColor(Color.Theme.Text.white9)
                        .frame(width: 24, height: 24)
                    Text("add_other_device".localized)
                        .font(.inter(size: 16, weight: .semibold))
                        .foregroundStyle(Color.Theme.Text.white9)
                }
                .frame(width: 339, height: 54)
                .background(Color.Theme.Accent.blue)
                .cornerRadius(16)
            }
            .padding(.top, 24)
            .buttonStyle(ScaleButtonStyle())

            Divider()
                .background(Color.LL.Neutrals.background)
                .padding(.horizontal, 18)
                .padding(.top, 24)

            LazyVStack(alignment: .leading) {
                VStack(alignment: .leading) {
                    Text("current_device".localized)
                        .font(.inter(size: 14, weight: .bold))
                        .foregroundColor(Color.Theme.Text.black3)

                    DevicesView.Cell(model: vm.current ?? DeviceInfoModel.empty(), isCurrent: true)
                }
                .visibility(vm.showCurrent ? .visible : .gone)

                VStack(alignment: .leading) {
                    Text("other_device".localized)
                        .font(.inter(size: 14, weight: .bold))
                        .foregroundColor(Color.Theme.Text.black3)
                    ForEach(vm.devices) { model in
                        DevicesView.Cell(model: model)
                    }
                }
                .visibility(vm.showOther ? .visible : .gone)
            }
            .padding(.horizontal, 18)
            .padding(.top, 24)
        }
        .backgroundFill(Color.LL.Neutrals.background)
        .mockPlaceholder(vm.status == PageStatus.loading)
        .applyRouteable(self)
        .tracedView(self)
    }

    // MARK: Private

    @StateObject
    private var vm = DevicesViewModel()
}

// MARK: DevicesView.Cell

extension DevicesView {
    struct Cell: View {
        var model: DeviceInfoModel
        var isCurrent: Bool = false

        var body: some View {
            Button {
                Router.route(to: RouteMap.Profile.deviceInfo(model))
            } label: {
                HStack(alignment: .top) {
                    Image("device_2")
                        .frame(width: 24, height: 24)
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(model.showName())
                                .font(.inter(size: 16))
                                .foregroundColor(Color.Theme.Text.black8)
                                .frame(height: 24)
                            Text(model.showApp())
                                .font(.inter(size: 12))
                                .foregroundColor(Color.Theme.Text.black3)
                                .frame(height: 16)
                            Text(model.showLocationAndDate())
                                .font(.inter(size: 12))
                                .foregroundColor(Color.Theme.Text.black3)
                                .frame(height: 16)
                        }
                        Spacer()
                        if isCurrent {
                            Image("check_fill_1")
                        } else {
                            Image("device_arrow_right")
                        }
                    }
                }
                .padding(.all, 16)
                .frame(height: 96)
                .background(.Theme.Background.grey)
                .cornerRadius(16)
            }
            .buttonStyle(ScaleButtonStyle())
        }
    }
}

#Preview {
    DevicesView()
}
